import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_editor/super_editor.dart';
import '../../state/tab_state.dart';
import '../../state/app_state.dart';
import '../../services/save_service.dart';
import '../../services/entity_attribution_service.dart';
import '../../core/services/chapter_coordinator.dart';
import '../../widgets/entity_tooltip_overlay.dart';
import '../../screens/entity_detail_screen.dart';
import 'editor_tab_bar.dart';
import 'dart:async';

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
  DateTime? _currentChapterCreatedAt; // Track by creation time to handle ID changes
  Timer? _autoSaveTimer;
  Timer? _attributionTimer;
  final GlobalKey<EntityDetailScreenState> _entityDetailKey = GlobalKey<EntityDetailScreenState>();

  @override
  void initState() {
    super.initState();
    _attributionService = EntityAttributionService(ref.read(entityRecognizerProvider));
    // Set up callback for AI entity extraction updates
    _attributionService.onEntitiesUpdated = _onAIEntitiesExtracted;
    _initializeEditor();
  }

  /// Called when AI entity extraction completes (async)
  void _onAIEntitiesExtracted() {
    if (mounted) {
      // Re-apply attributions with the new AI-extracted entities
      _attributionService.applyToDocument(_document);
      setState(() {}); // Trigger rebuild to show updated entity highlights
    }
  }

  void _initializeEditor({String content = ''}) {
    _document = MutableDocument(
      nodes: content.isEmpty
          ? [
              ParagraphNode(
                id: Editor.createNodeId(),
                text: AttributedText('Start writing your story here...'),
              ),
            ]
          : _parseContentToNodes(content),
    );
    _composer = MutableDocumentComposer();
    _editor = createDefaultDocumentEditor(
      document: _document,
      composer: _composer,
    );

    // Apply entity attributions to initial content
    _attributionService.applyToDocument(_document);

    // Set up auto-save timer (1 second for responsive saving)
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _autoSave();
    });

    // Set up attribution update timer (2 seconds for entity recognition)
    _attributionTimer?.cancel();
    _attributionTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _attributionService.applyToDocument(_document);
      setState(() {}); // Trigger rebuild to show updated styling
    });
  }

  List<DocumentNode> _parseContentToNodes(String content) {
    if (content.isEmpty) {
      return [
        ParagraphNode(id: Editor.createNodeId(), text: AttributedText('')),
      ];
    }

    final lines = content.split('\n');
    return lines.map((line) {
      return ParagraphNode(
        id: Editor.createNodeId(),
        text: AttributedText(line),
      );
    }).toList();
  }

  String _getDocumentContent() {
    final buffer = StringBuffer();
    final nodeCount = _document.nodeCount;

    for (var i = 0; i < nodeCount; i++) {
      final node = _document.getNodeAt(i);
      if (node is TextNode) {
        buffer.write(node.text.toPlainText());
        if (i < nodeCount - 1) {
          buffer.write('\n');
        }
      }
    }
    return buffer.toString();
  }

  void _autoSave() {
    final tabState = ref.read(tabStateProvider);
    final activeTab = tabState.activeTab;

    if (activeTab == null) return;

    // Only auto-save for chapter tabs (entities use their own form save)
    if (activeTab.type == TabContentType.chapter && activeTab.chapter != null) {
      final content = _getDocumentContent();

      if (content != activeTab.chapter!.content) {
        // Convert preview tab to permanent when user starts typing
        if (activeTab.isPreview) {
          ref.read(tabStateProvider.notifier).makeTabPermanent(activeTab.chapter!.id);
        }

        // Use chapter coordinator to update chapter across all providers
        ref.read(chapterCoordinatorProvider).updateContent(activeTab.chapter!.id, content);
      }
    }
  }

  Future<void> _saveCurrentTab() async {
    final tabState = ref.read(tabStateProvider);
    final activeTab = tabState.activeTab;

    // Handle entity tab saves via the GlobalKey
    if (activeTab?.type == TabContentType.entity && _entityDetailKey.currentState != null) {
      _entityDetailKey.currentState!.save();
    }

    // Use centralized save service for chapter saves
    await ref.read(saveServiceProvider).saveCurrentTab();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _attributionTimer?.cancel();
    _attributionService.dispose(); // Clean up AI extraction timer if any
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabState = ref.watch(tabStateProvider);
    final activeTab = tabState.activeTab;
    final highlightsEnabled = ref.watch(entityHighlightProvider);
    final hoveredEntityName = ref.watch(hoveredEntityProvider);

    // Update editor when active chapter tab changes
    if (activeTab?.type == TabContentType.chapter) {
      final chapter = activeTab?.chapter;
      // Check if this is actually a different chapter (not just an ID sync)
      // Use createdAt as stable identifier since ID can change from timestamp to UUID
      final isDifferentChapter = chapter != null &&
          (_currentChapterCreatedAt == null ||
           chapter.createdAt != _currentChapterCreatedAt);

      if (isDifferentChapter) {
        _currentChapterId = chapter?.id;
        _currentChapterCreatedAt = chapter?.createdAt;
        if (_currentChapterId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _composer.dispose();
                _initializeEditor(content: chapter?.content ?? '');
              });
            }
          });
        }
      } else if (chapter != null && chapter.id != _currentChapterId) {
        // Just an ID change (sync), update the tracked ID without re-initializing
        _currentChapterId = chapter.id;
      }
    } else {
      // Clear editor if not a chapter tab
      if (_currentChapterId != null) {
        _currentChapterId = null;
        _currentChapterCreatedAt = null;
      }
    }

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Tab Bar
          const EditorTabBar(),
          // Editor Toolbar
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                const Spacer(),
                if (activeTab != null)
                  TextButton.icon(
                    onPressed: () => _saveCurrentTab(),
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('Save'),
                  ),
              ],
            ),
          ),
          // Editor Content
          Expanded(
            child: activeTab == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit_document,
                          size: 64,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tab selected',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create a new project and chapter to start writing',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                        ),
                      ],
                    ),
                  )
                : activeTab.type == TabContentType.entity && activeTab.entity != null
                    ? EntityDetailScreen(
                        key: _entityDetailKey,
                        metadata: activeTab.entity!,
                        onSave: (updatedEntity) {
                          // Update entity in store
                          ref.read(entityStoreProvider).save(updatedEntity);
                          // Trigger UI rebuild for entity lists
                          ref.read(entityStoreVersionProvider.notifier).increment();
                          // Update tab
                          ref.read(tabStateProvider.notifier).updateTabEntity(updatedEntity);
                          // Save only this entity to backend
                          ref.read(projectServiceProvider).saveEntity(updatedEntity);
                        },
                      )
                    : Padding(
                        padding: const EdgeInsets.all(48.0),
                        child: SuperEditor(
                      editor: _editor,
                      stylesheet: defaultStylesheet.copyWith(
                        documentPadding: EdgeInsets.zero,
                        addRulesAfter: [
                          StyleRule(BlockSelector.all, (doc, docNode) {
                            return {
                              Styles.textStyle: TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            };
                          }),
                        ],
                        inlineTextStyler: (attributions, existingStyle) {
                          // Check if entity highlights are enabled
                          if (!highlightsEnabled) {
                            return existingStyle;
                          }

                          // Apply entity styling based on attribution
                          TextStyle style = existingStyle;
                          for (final attribution in attributions) {
                            if (attribution is EntityAttribution) {
                              final entity = attribution.entity;
                              final isHovered = hoveredEntityName == entity.name;

                              if (entity.recognized) {
                                // Green underline for recognized entities
                                style = style.copyWith(
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.green.shade600,
                                  decorationThickness: isHovered ? 3.0 : 2.0,
                                );
                              } else {
                                // Orange underline for unrecognized entities
                                style = style.copyWith(
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.orange.shade600,
                                  decorationThickness: isHovered ? 3.0 : 2.0,
                                );
                              }
                            }
                          }
                          return style;
                        },
                      ),
                      selectionStyle: SelectionStyles(
                        selectionColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.3),
                      ),
                      documentOverlayBuilders: [
                        EntityTooltipOverlayBuilder(ref),
                        const SuperEditorIosToolbarFocalPointDocumentLayerBuilder(),
                        const SuperEditorIosHandlesDocumentLayerBuilder(),
                        const SuperEditorAndroidToolbarFocalPointDocumentLayerBuilder(),
                        const SuperEditorAndroidHandlesDocumentLayerBuilder(),
                        DefaultCaretOverlayBuilder(
                          caretStyle: CaretStyle(
                            width: 2,
                            color:
                                Theme.of(context).brightness == Brightness.light
                                ? const Color(
                                    0xFFFF6B00,
                                  ) // Bright orange for light mode
                                : const Color(
                                    0xFF00D4FF,
                                  ), // Bright cyan for dark mode
                          ),
                        ),
                      ],
                      keyboardActions: defaultKeyboardActions,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

}
