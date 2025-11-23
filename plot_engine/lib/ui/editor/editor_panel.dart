import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_editor/super_editor.dart';
import '../../state/tab_state.dart';
import '../../services/save_service.dart';
import '../../core/services/chapter_coordinator.dart';
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
  String? _currentChapterId;
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _initializeEditor();
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

    // Set up auto-save timer (1 second for responsive saving)
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _autoSave();
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
        buffer.write(node.text.text);
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

    if (activeTab != null) {
      final content = _getDocumentContent();
      if (content != activeTab.chapter.content) {
        // Convert preview tab to permanent when user starts typing
        if (activeTab.isPreview) {
          ref.read(tabStateProvider.notifier).makeTabPermanent(activeTab.chapter.id);
        }

        // Use chapter coordinator to update chapter across all providers
        ref.read(chapterCoordinatorProvider).updateContent(activeTab.chapter.id, content);
      }
    }
  }

  Future<void> _saveCurrentTab() async {
    // Use centralized save service
    await ref.read(saveServiceProvider).saveCurrentTab();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabState = ref.watch(tabStateProvider);
    final activeTab = tabState.activeTab;

    // Update editor when active tab changes
    if (activeTab?.chapter.id != _currentChapterId) {
      _currentChapterId = activeTab?.chapter.id;
      if (_currentChapterId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _composer.dispose();
            _initializeEditor(content: activeTab?.chapter.content ?? '');
          });
        });
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
                if (activeTab != null) ...[
                  IconButton(
                    icon: const Icon(Icons.format_bold, size: 20),
                    onPressed: () {},
                    tooltip: 'Bold (Coming soon)',
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_italic, size: 20),
                    onPressed: () {},
                    tooltip: 'Italic (Coming soon)',
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_underlined, size: 20),
                    onPressed: () {},
                    tooltip: 'Underline (Coming soon)',
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _saveCurrentTab(),
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('Save'),
                  ),
                ],
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
                          'No chapter selected',
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
                      ),
                      selectionStyle: SelectionStyles(
                        selectionColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.3),
                      ),
                      documentOverlayBuilders: [
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
