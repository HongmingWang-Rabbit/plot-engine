import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

class EditorPanel extends StatefulWidget {
  const EditorPanel({super.key});

  @override
  State<EditorPanel> createState() => _EditorPanelState();
}

class _EditorPanelState extends State<EditorPanel> {
  late MutableDocument _document;
  late MutableDocumentComposer _composer;
  late Editor _editor;

  @override
  void initState() {
    super.initState();
    _document = MutableDocument(
      nodes: [
        ParagraphNode(
          id: Editor.createNodeId(),
          text: AttributedText('Start writing your story here...'),
        ),
      ],
    );
    _composer = MutableDocumentComposer();
    _editor = createDefaultDocumentEditor(
      document: _document,
      composer: _composer,
    );
  }

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                Text(
                  'Chapter 1: The Beginning',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.format_bold, size: 20),
                  onPressed: () {},
                  tooltip: 'Bold',
                ),
                IconButton(
                  icon: const Icon(Icons.format_italic, size: 20),
                  onPressed: () {},
                  tooltip: 'Italic',
                ),
                IconButton(
                  icon: const Icon(Icons.format_underlined, size: 20),
                  onPressed: () {},
                  tooltip: 'Underline',
                ),
              ],
            ),
          ),
          // Editor Content
          Expanded(
            child: Padding(
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
}
