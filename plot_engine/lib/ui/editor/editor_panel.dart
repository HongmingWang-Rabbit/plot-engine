import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_editor/super_editor.dart';
import '../../state/app_state.dart';
import '../../services/project_service.dart';
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

    // Set up auto-save timer
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _autoSave();
    });
  }

  List<DocumentNode> _parseContentToNodes(String content) {
    if (content.isEmpty) {
      return [
        ParagraphNode(
          id: Editor.createNodeId(),
          text: AttributedText(''),
        ),
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
    final currentChapter = ref.read(currentChapterProvider);
    if (currentChapter != null) {
      final content = _getDocumentContent();
      if (content != currentChapter.content) {
        ref.read(currentChapterProvider.notifier).updateContent(content);
      }
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentChapter = ref.watch(currentChapterProvider);

    // Update editor when chapter changes
    if (currentChapter?.id != _currentChapterId) {
      _currentChapterId = currentChapter?.id;
      if (_currentChapterId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _composer.dispose();
            _initializeEditor(content: currentChapter?.content ?? '');
          });
        });
      }
    }

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Editor Toolbar
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    currentChapter?.title ?? 'No chapter selected',
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                if (currentChapter != null) ...[
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
                    onPressed: () => _saveChapter(),
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('Save'),
                  ),
                ],
              ],
            ),
          ),
          // Editor Content
          Expanded(
            child: currentChapter == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit_document,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No chapter selected',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create a new project and chapter to start writing',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
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
                          StyleRule(
                            BlockSelector.all,
                            (doc, docNode) {
                              return {
                                Styles.textStyle: TextStyle(
                                  fontSize: 16,
                                  height: 1.6,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              };
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChapter() async {
    final currentChapter = ref.read(currentChapterProvider);
    if (currentChapter == null) return;

    // Update content first
    final content = _getDocumentContent();
    ref.read(currentChapterProvider.notifier).updateContent(content);

    try {
      await ref.read(projectServiceProvider).updateChapter(
        ref.read(currentChapterProvider)!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chapter saved successfully'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving chapter: $e')),
        );
      }
    }
  }
}
