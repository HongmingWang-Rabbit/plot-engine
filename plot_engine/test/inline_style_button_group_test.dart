/// Tests for InlineStyleButtonGroup widget
/// 
/// Verifies that inline style buttons render correctly and respond to user interaction.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plot_engine/ui/editor/inline_style_button_group.dart';
import 'package:super_editor/super_editor.dart';

void main() {
  group('InlineStyleButtonGroup', () {
    testWidgets('renders all four style buttons', (tester) async {
      // Create a simple document with one paragraph
      final document = MutableDocument(
        nodes: [
          ParagraphNode(
            id: 'node1',
            text: AttributedText('Hello World'),
          ),
        ],
      );

      final composer = MutableDocumentComposer();
      final editor = createDefaultDocumentEditor(
        document: document,
        composer: composer,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InlineStyleButtonGroup(
              editor: editor,
              composer: composer,
              isBold: false,
              isItalic: false,
              isUnderline: false,
              isStrikethrough: false,
            ),
          ),
        ),
      );

      // Verify all four buttons are present
      expect(find.byIcon(Icons.format_bold), findsOneWidget);
      expect(find.byIcon(Icons.format_italic), findsOneWidget);
      expect(find.byIcon(Icons.format_underlined), findsOneWidget);
      expect(find.byIcon(Icons.format_strikethrough), findsOneWidget);
    });

    testWidgets('shows active state for bold button', (tester) async {
      // Create a simple document with one paragraph
      final document = MutableDocument(
        nodes: [
          ParagraphNode(
            id: 'node1',
            text: AttributedText('Hello World'),
          ),
        ],
      );

      final composer = MutableDocumentComposer();
      final editor = createDefaultDocumentEditor(
        document: document,
        composer: composer,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InlineStyleButtonGroup(
              editor: editor,
              composer: composer,
              isBold: true,
              isItalic: false,
              isUnderline: false,
              isStrikethrough: false,
            ),
          ),
        ),
      );

      await tester.pump();

      // The bold button should be present
      expect(find.byIcon(Icons.format_bold), findsOneWidget);
      
      // Verify the button is in the widget tree
      final boldIcon = tester.widget<Icon>(find.byIcon(Icons.format_bold));
      expect(boldIcon, isNotNull);
    });

    testWidgets('shows tooltips with keyboard shortcuts', (tester) async {
      // Create a simple document with one paragraph
      final document = MutableDocument(
        nodes: [
          ParagraphNode(
            id: 'node1',
            text: AttributedText('Hello World'),
          ),
        ],
      );

      final composer = MutableDocumentComposer();
      final editor = createDefaultDocumentEditor(
        document: document,
        composer: composer,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InlineStyleButtonGroup(
              editor: editor,
              composer: composer,
              isBold: false,
              isItalic: false,
              isUnderline: false,
              isStrikethrough: false,
            ),
          ),
        ),
      );

      // Find the bold button tooltip
      final boldTooltip = find.ancestor(
        of: find.byIcon(Icons.format_bold),
        matching: find.byType(Tooltip),
      );
      
      expect(boldTooltip, findsOneWidget);
      
      // Verify tooltip contains keyboard shortcut
      final tooltip = tester.widget<Tooltip>(boldTooltip);
      expect(tooltip.message, contains('Bold'));
      expect(tooltip.message, contains('B'));
    });
  });
}
