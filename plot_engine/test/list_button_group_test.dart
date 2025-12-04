import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'package:plot_engine/ui/editor/list_button_group.dart';
import 'package:plot_engine/services/block_metadata.dart';

void main() {
  group('ListButtonGroup', () {
    testWidgets('renders bullet and numbered list buttons', (tester) async {
      final document = MutableDocument(nodes: [
        ParagraphNode(
          id: 'test-node',
          text: AttributedText('Test text'),
        ),
      ]);
      
      final composer = MutableDocumentComposer();
      final editor = createEditor(document: document, composer: composer);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListButtonGroup(
              editor: editor,
              composer: composer,
              currentListType: null,
            ),
          ),
        ),
      );
      
      // Verify both buttons are present
      expect(find.byIcon(Icons.format_list_bulleted), findsOneWidget);
      expect(find.byIcon(Icons.format_list_numbered), findsOneWidget);
    });
    
    testWidgets('highlights active list type', (tester) async {
      final document = MutableDocument(nodes: [
        ParagraphNode(
          id: 'test-node',
          text: AttributedText('Test text'),
        ),
      ]);
      
      final composer = MutableDocumentComposer();
      final editor = createEditor(document: document, composer: composer);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListButtonGroup(
              editor: editor,
              composer: composer,
              currentListType: ListType.unordered,
            ),
          ),
        ),
      );
      
      // Find the bullet list button's Material widget
      final bulletButton = find.ancestor(
        of: find.byIcon(Icons.format_list_bulleted),
        matching: find.byType(Material),
      ).first;
      
      final bulletMaterial = tester.widget<Material>(bulletButton);
      
      // Verify it has a non-transparent color (active state)
      expect(bulletMaterial.color, isNot(Colors.transparent));
    });
    
    testWidgets('shows tooltips with keyboard shortcuts', (tester) async {
      final document = MutableDocument(nodes: [
        ParagraphNode(
          id: 'test-node',
          text: AttributedText('Test text'),
        ),
      ]);
      
      final composer = MutableDocumentComposer();
      final editor = createEditor(document: document, composer: composer);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListButtonGroup(
              editor: editor,
              composer: composer,
              currentListType: null,
            ),
          ),
        ),
      );
      
      // Find tooltip widgets
      final tooltips = find.byType(Tooltip);
      expect(tooltips, findsNWidgets(2)); // Two buttons, two tooltips
      
      // Verify tooltip messages contain keyboard shortcuts
      final bulletTooltip = tester.widget<Tooltip>(tooltips.first);
      expect(bulletTooltip.message, contains('Shift+8'));
      
      final numberedTooltip = tester.widget<Tooltip>(tooltips.last);
      expect(numberedTooltip.message, contains('Shift+7'));
    });
  });
}

/// Create an editor for testing
Editor createEditor({
  required MutableDocument document,
  required MutableDocumentComposer composer,
}) {
  return Editor(
    editables: {
      Editor.documentKey: document,
      Editor.composerKey: composer,
    },
    requestHandlers: [],
  );
}
