import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_editor/super_editor.dart';
import 'dart:async';

import '../../state/tab_state.dart';
import '../../state/app_state.dart';
import '../../services/save_service.dart';
import '../../services/entity_attribution_service.dart';
import '../../services/ai_suggestion_service.dart';
import '../../services/formatted_content_serializer.dart';
import '../../services/formatting_commands.dart';
import '../../core/services/chapter_coordinator.dart';
import '../../widgets/entity_tooltip_overlay.dart';
import '../../screens/entity_detail_screen.dart';
import '../../l10n/app_localizations.dart';
import 'editor_tab_bar.dart';
import 'editor_config.dart';
import 'ai_input_bar.dart';
import 'formatting_toolbar.dart';
import 'dart:convert';

class EditorPanel extends ConsumerStatefulWidget {
  const EditorPanel({super.key});

  @override
  ConsumerState<EditorPanel> createState() => _EditorPanelState();
}

class _EditorPanelState extends ConsumerState<EditorPanel> {
  late MutableDocument _document;
  late MutableDocumentComposer _composer;
  late Editor _editor;
  late EntityAttributionService _attributionService;

  String? _currentChapterId;
  DateTime? _currentChapterCreatedAt;
  Timer? _autoSaveTimer;
  Timer? _attributionTimer;

  final GlobalKey<EntityDetailScreenState> _entityDetailKey = GlobalKey<EntityDetailScreenState>();

  @override
  void initState() {
    super.initState();
    _attributionService = EntityAttributionService(ref.read(entityRecognizerProvider));
    _attributionService.onEntitiesUpdated = _onAIEntitiesExtracted;
    _initializeEditor();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _attributionTimer?.cancel();
    _attributionService.dispose();
    _document.removeListener(_onDocumentChangedForPendingStyles);
    _composer.selectionNotifier.removeListener(_onSelectionChangedForPendingStyles);
    _composer.dispose();
    super.dispose();
  }

  void _onAIEntitiesExtracted() {
    if (mounted) {
      _attributionService.applyToDocument(_document);
      setState(() {});
    }
  }

  void _initializeEditor({String content = ''}) {
    _document = MutableDocument(
      nodes: content.isEmpty
          ? [ParagraphNode(id: Editor.createNodeId(), text: AttributedText('Start writing your story here...'))]
          : _parseContentToNodes(content),
    );
    _composer = MutableDocumentComposer();
    _editor = _createEditorWithFormattingSupport();

    _attributionService.applyToDocument(_document);
    _setupTimers();
    _setupPendingStylesHandler();
  }

  /// Creates an editor with custom formatting request handlers
  Editor _createEditorWithFormattingSupport() {
    return Editor(
      editables: {
        Editor.documentKey: _document,
        Editor.composerKey: _composer,
      },
      requestHandlers: [
        // Add our custom formatting handlers first
        ...formattingRequestHandlers,
        // Then include all default handlers
        ...defaultRequestHandlers,
      ],
      reactionPipeline: List.from(defaultEditorReactions),
    );
  }
  
  DocumentSelection? _lastSelectionForPendingStyles;
  
  void _setupPendingStylesHandler() {
    // Listen to document changes to apply pending styles
    _document.addListener(_onDocumentChangedForPendingStyles);
    _composer.selectionNotifier.addListener(_onSelectionChangedForPendingStyles);
  }
  
  void _onSelectionChangedForPendingStyles() {
    _lastSelectionForPendingStyles = _composer.selection;
  }
  
  void _onDocumentChangedForPendingStyles(DocumentChangeLog changeLog) {
    final pendingStyles = ref.read(pendingStylesProvider);
    if (pendingStyles.isEmpty) {
      return;
    }
    
    final currentSelection = _composer.selection;
    if (currentSelection == null || !currentSelection.isCollapsed) {
      return;
    }
    
    // Check if text was inserted (selection moved forward)
    if (_lastSelectionForPendingStyles != null &&
        _lastSelectionForPendingStyles!.extent.nodeId == currentSelection.extent.nodeId) {
      final lastOffset = (_lastSelectionForPendingStyles!.extent.nodePosition as TextNodePosition).offset;
      final currentOffset = (currentSelection.extent.nodePosition as TextNodePosition).offset;
      
      if (currentOffset > lastOffset) {
        // Text was inserted, apply pending styles
        final node = _document.getNodeById(currentSelection.extent.nodeId);
        if (node is TextNode) {
          final range = SpanRange(lastOffset, currentOffset - 1);
          for (final style in pendingStyles) {
            node.text.addAttribution(style, range);
          }
        }
      }
    }
    
    _lastSelectionForPendingStyles = currentSelection;
  }

  void _setupTimers() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(EditorConfig.autoSaveInterval, (_) => _autoSave());

    _attributionTimer?.cancel();
    _attributionTimer = Timer.periodic(EditorConfig.attributionUpdateInterval, (_) {
      // Apply attributions without calling setState - the document listener
      // and _onAIEntitiesExtracted will handle UI updates when needed
      _attributionService.applyToDocument(_document);
    });
  }

  List<DocumentNode> _parseContentToNodes(String content) {
    if (content.isEmpty) {
      return [ParagraphNode(id: Editor.createNodeId(), text: AttributedText(''))];
    }
    
    // Try to parse as JSON with formatting
    try {
      final json = jsonDecode(content) as Map<String, dynamic>;
      return FormattedContentSerializer.deserializeDocument(json);
    } catch (e) {
      // If JSON parsing fails, treat as plain text (legacy format)
      print('[Editor] Content is not JSON, treating as plain text: $e');
      return content.split('\n').map((line) {
        return ParagraphNode(id: Editor.createNodeId(), text: AttributedText(line));
      }).toList();
    }
  }

  String _getDocumentContent() {
    // Serialize document with all formatting preserved
    final json = FormattedContentSerializer.serializeDocument(_document);
    return jsonEncode(json);
  }

  void _autoSave() {
    final activeTab = ref.read(tabStateProvider).activeTab;
    if (activeTab == null) return;

    if (activeTab.type == TabContentType.chapter && activeTab.chapter != null) {
      final content = _getDocumentContent();
      
      // Check if content has actually changed
      // We need to compare the actual document structure, not just the JSON strings
      bool hasChanged = false;
      try {
        final currentJson = jsonDecode(content) as Map<String, dynamic>;
        final savedJson = jsonDecode(activeTab.chapter!.content) as Map<String, dynamic>;
        hasChanged = jsonEncode(currentJson) != jsonEncode(savedJson);
      } catch (e) {
        // If either is not valid JSON, do a simple string comparison
        hasChanged = content != activeTab.chapter!.content;
      }
      
      if (hasChanged) {
        print('[Editor] Content changed, auto-saving...');
        if (activeTab.isPreview) {
          ref.read(tabStateProvider.notifier).makeTabPermanent(activeTab.chapter!.id);
        }
        ref.read(chapterCoordinatorProvider).updateContent(activeTab.chapter!.id, content);

        // Trigger AI suggestion analysis in background
        // Extract plain text for AI analysis
        final plainText = _getPlainTextContent();
        final project = ref.read(projectProvider);
        if (project != null) {
          ref.read(aiSuggestionProvider.notifier).onContentChanged(
            plainText,
            activeTab.chapter!.id,
            project.id,
          );
        }
      }
    }
  }
  
  /// Get plain text content for AI analysis (without formatting)
  String _getPlainTextContent() {
    final buffer = StringBuffer();
    final nodeCount = _document.nodeCount;

    for (var i = 0; i < nodeCount; i++) {
      final node = _document.getNodeAt(i);
      if (node is TextNode) {
        buffer.write(node.text.toPlainText());
        if (i < nodeCount - 1) buffer.write('\n');
      }
    }
    return buffer.toString();
  }

  Future<void> _saveCurrentTab() async {
    final activeTab = ref.read(tabStateProvider).activeTab;

    if (activeTab?.type == TabContentType.entity && _entityDetailKey.currentState != null) {
      _entityDetailKey.currentState!.save();
    }

    await ref.read(saveServiceProvider).saveCurrentTab();
  }

  void _handleChapterChange(EditorTab? activeTab) {
    if (activeTab?.type != TabContentType.chapter) {
      if (_currentChapterId != null) {
        _currentChapterId = null;
        _currentChapterCreatedAt = null;
      }
      return;
    }

    final chapter = activeTab?.chapter;
    if (chapter == null) return;

    final isDifferentChapter = _currentChapterCreatedAt == null ||
        chapter.createdAt != _currentChapterCreatedAt;

    if (isDifferentChapter) {
      _currentChapterId = chapter.id;
      _currentChapterCreatedAt = chapter.createdAt;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _composer.dispose();
            _initializeEditor(content: chapter.content);
          });

          // Trigger AI suggestion for newly opened chapter
          final project = ref.read(projectProvider);
          if (project != null) {
            print('[Editor] Chapter opened: ${chapter.id}, triggering AI suggestion...');
            ref.read(aiSuggestionProvider.notifier).onContentChanged(
              chapter.content,
              chapter.id,
              project.id,
            );
          }
        }
      });
    } else if (chapter.id != _currentChapterId) {
      _currentChapterId = chapter.id;
    }
  }

  /// Append content to the end of the document
  void _appendContent(String content) {
    final lines = content.split('\n');
    for (final line in lines) {
      final newNode = ParagraphNode(
        id: Editor.createNodeId(),
        text: AttributedText(line),
      );
      _document.insertNodeAt(_document.nodeCount, newNode);
    }
    setState(() {});
    _autoSave();
  }

  @override
  Widget build(BuildContext context) {
    final tabState = ref.watch(tabStateProvider);
    final activeTab = tabState.activeTab;

    _handleChapterChange(activeTab);

    final isChapterTab = activeTab?.type == TabContentType.chapter;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          const EditorTabBar(),
          _EditorToolbar(activeTab: activeTab, onSave: _saveCurrentTab),
          // Show formatting toolbar only for chapter tabs
          if (isChapterTab)
            FormattingToolbar(
              editor: _editor,
              composer: _composer,
            ),
          Expanded(child: _buildContent(context, activeTab)),
          // AI Input bar for user-initiated AI actions
          if (isChapterTab)
            AIInputBar(onContentGenerated: _appendContent),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, EditorTab? activeTab) {
    if (activeTab == null) {
      return _EmptyEditorState();
    }

    if (activeTab.type == TabContentType.entity && activeTab.entity != null) {
      return _buildEntityDetailScreen(activeTab);
    }

    return _buildChapterEditor(context);
  }

  Widget _buildEntityDetailScreen(EditorTab activeTab) {
    return EntityDetailScreen(
      key: _entityDetailKey,
      metadata: activeTab.entity!,
      onSave: (updatedEntity) {
        ref.read(entityStoreProvider).save(updatedEntity);
        ref.read(entityStoreVersionProvider.notifier).increment();
        ref.read(tabStateProvider.notifier).updateTabEntity(updatedEntity);
        ref.read(projectServiceProvider).saveEntity(updatedEntity);
      },
    );
  }

  Widget _buildChapterEditor(BuildContext context) {
    final highlightsEnabled = ref.watch(entityHighlightProvider);
    final hoveredEntityName = ref.watch(hoveredEntityProvider);

    return SuperEditor(
      editor: _editor,
      stylesheet: EditorStylesheetFactory.createChapterStylesheet(
        context: context,
        highlightsEnabled: highlightsEnabled,
        hoveredEntityName: hoveredEntityName,
      ),
      selectionStyle: EditorStylesheetFactory.createSelectionStyles(context),
      documentOverlayBuilders: [
        EntityTooltipOverlayBuilder(ref),
        const SuperEditorIosToolbarFocalPointDocumentLayerBuilder(),
        const SuperEditorIosHandlesDocumentLayerBuilder(),
        const SuperEditorAndroidToolbarFocalPointDocumentLayerBuilder(),
        const SuperEditorAndroidHandlesDocumentLayerBuilder(),
        DefaultCaretOverlayBuilder(
          caretStyle: EditorStylesheetFactory.createCaretStyle(context),
        ),
      ],
      keyboardActions: EditorStylesheetFactory.createKeyboardActions(),
    );
  }
}

/// Toolbar widget for the editor
class _EditorToolbar extends ConsumerWidget {
  final EditorTab? activeTab;
  final VoidCallback onSave;

  const _EditorToolbar({required this.activeTab, required this.onSave});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          const Spacer(),
          if (activeTab != null)
            TextButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save, size: 18),
              label: Text(ref.tr('save')),
            ),
        ],
      ),
    );
  }
}

/// Empty state widget when no tab is selected
class _EmptyEditorState extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.edit_document,
            size: 64,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            ref.tr('no_tab_selected'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ref.tr('create_project_hint'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
