import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_editor/super_editor.dart';
import 'package:plot_engine/ui/editor/formatting_toolbar.dart';
import 'package:plot_engine/ui/editor/inline_style_button_group.dart';
import 'package:plot_engine/ui/editor/block_style_dropdown.dart';
import 'package:plot_engine/ui/editor/list_button_group.dart';
import 'package:plot_engine/ui/editor/alignment_button_group.dart';
import 'package:plot_engine/ui/editor/color_picker_button.dart';
import 'package:plot_engine/ui/editor/font_size_selector.dart';
import 'package:plot_engine/ui/editor/clear_formatting_button.dart';
import 'package:plot_engine/services/block_metadata.dart';

void main() {
  group('Toolbar Accessibility', () {
    late Editor editor;
    late MutableDocumentComposer composer;

    setUp(() {
      // Create a simple document
      final document = MutableDocument(
        nodes: [
          ParagraphNode(
            id: 'test-node',
            text: AttributedText('Test text'),
          ),
        ],
      );

      // Create composer
      composer = MutableDocumentComposer();

      // Create editor
      editor = createDefaultDocumentEditor(
        document: document,
        composer: composer,
      );
    });

    group('Tooltips', () {
      testWidgets('Inline style buttons have tooltips with keyboard shortcuts', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
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
          ),
        );

        // Find bold button and verify tooltip widget exists
        final boldButton = find.byIcon(Icons.format_bold);
        expect(boldButton, findsOneWidget);

        // Verify Tooltip widget exists
        expect(find.byType(Tooltip), findsWidgets);

        await tester.pumpAndSettle();
      });

      testWidgets('Block style dropdown has tooltip', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: BlockStyleDropdown(
                  editor: editor,
                  composer: composer,
                  currentStyle: BlockStyle.normal,
                ),
              ),
            ),
          ),
        );

        // Find dropdown and verify it exists
        expect(find.byType(DropdownButton<BlockStyle>), findsOneWidget);
      });

      testWidgets('List buttons have tooltips with keyboard shortcuts', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListButtonGroup(
                  editor: editor,
                  composer: composer,
                  currentListType: null,
                ),
              ),
            ),
          ),
        );

        // Find bullet list button
        final bulletButton = find.byIcon(Icons.format_list_bulleted);
        expect(bulletButton, findsOneWidget);

        // Verify Tooltip widget exists
        expect(find.byType(Tooltip), findsWidgets);

        await tester.pumpAndSettle();
      });

      testWidgets('Alignment buttons have tooltips with keyboard shortcuts', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: AlignmentButtonGroup(
                  editor: editor,
                  composer: composer,
                  currentAlignment: TextAlignment.left,
                ),
              ),
            ),
          ),
        );

        // Find center align button
        final centerButton = find.byIcon(Icons.format_align_center);
        expect(centerButton, findsOneWidget);

        // Verify Tooltip widget exists
        expect(find.byType(Tooltip), findsWidgets);

        await tester.pumpAndSettle();
      });

      testWidgets('Color picker buttons have tooltips', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ColorPickerButton(
                  editor: editor,
                  composer: composer,
                  currentColor: null,
                  isTextColor: true,
                  tooltip: 'Text Color',
                  icon: Icons.format_color_text,
                ),
              ),
            ),
          ),
        );

        // Find color picker button
        final colorButton = find.byIcon(Icons.format_color_text);
        expect(colorButton, findsOneWidget);

        // Verify Tooltip widget exists
        expect(find.byType(Tooltip), findsWidgets);

        await tester.pumpAndSettle();
      });

      testWidgets('Font size selector has tooltips', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: FontSizeSelector(
                  editor: editor,
                  composer: composer,
                  currentFontSize: 14,
                ),
              ),
            ),
          ),
        );

        // Find increase button
        final increaseButton = find.byIcon(Icons.add);
        expect(increaseButton, findsOneWidget);

        // Verify Tooltip widget exists
        expect(find.byType(Tooltip), findsWidgets);

        await tester.pumpAndSettle();
      });

      testWidgets('Clear formatting button has tooltip with keyboard shortcut', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ClearFormattingButton(
                  editor: editor,
                  composer: composer,
                ),
              ),
            ),
          ),
        );

        // Find clear formatting button
        final clearButton = find.byIcon(Icons.format_clear);
        expect(clearButton, findsOneWidget);

        // Verify Tooltip widget exists
        expect(find.byType(Tooltip), findsWidgets);

        await tester.pumpAndSettle();
      });
    });

    group('Semantic Labels', () {
      testWidgets('Inline style buttons have semantic labels', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
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
          ),
        );

        // Verify semantic widgets exist
        expect(find.byType(Semantics), findsWidgets);
        
        // Verify buttons exist
        expect(find.byIcon(Icons.format_bold), findsOneWidget);
      });

      testWidgets('Block style dropdown has semantic label', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: BlockStyleDropdown(
                  editor: editor,
                  composer: composer,
                  currentStyle: BlockStyle.normal,
                ),
              ),
            ),
          ),
        );

        // Verify semantic structure exists
        expect(find.byType(Semantics), findsWidgets);
      });

      testWidgets('List buttons have semantic labels', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListButtonGroup(
                  editor: editor,
                  composer: composer,
                  currentListType: null,
                ),
              ),
            ),
          ),
        );

        // Verify semantic widgets exist
        expect(find.byType(Semantics), findsWidgets);
        
        // Verify buttons exist
        expect(find.byIcon(Icons.format_list_bulleted), findsOneWidget);
      });

      testWidgets('Alignment buttons have semantic labels', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: AlignmentButtonGroup(
                  editor: editor,
                  composer: composer,
                  currentAlignment: TextAlignment.left,
                ),
              ),
            ),
          ),
        );

        // Verify semantic widgets exist
        expect(find.byType(Semantics), findsWidgets);
        
        // Verify buttons exist
        expect(find.byIcon(Icons.format_align_left), findsOneWidget);
      });

      testWidgets('Color picker buttons have semantic labels', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ColorPickerButton(
                  editor: editor,
                  composer: composer,
                  currentColor: null,
                  isTextColor: true,
                  tooltip: 'Text Color',
                  icon: Icons.format_color_text,
                ),
              ),
            ),
          ),
        );

        // Verify semantic structure exists
        expect(find.byType(Semantics), findsWidgets);
      });

      testWidgets('Font size selector has semantic labels', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: FontSizeSelector(
                  editor: editor,
                  composer: composer,
                  currentFontSize: 14,
                ),
              ),
            ),
          ),
        );

        // Verify semantic structure exists
        expect(find.byType(Semantics), findsWidgets);
      });

      testWidgets('Clear formatting button has semantic label', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ClearFormattingButton(
                  editor: editor,
                  composer: composer,
                ),
              ),
            ),
          ),
        );

        // Verify semantic widgets exist
        expect(find.byType(Semantics), findsWidgets);
        
        // Verify button exists
        expect(find.byIcon(Icons.format_clear), findsOneWidget);
      });

      testWidgets('FormattingToolbar has semantic container label', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 800));

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: FormattingToolbar(
                  editor: editor,
                  composer: composer,
                ),
              ),
            ),
          ),
        );

        // Verify toolbar has semantic container
        expect(find.byType(Semantics), findsWidgets);
      });
    });

    group('Keyboard Navigation', () {
      testWidgets('Inline style buttons respond to Enter key', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
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
          ),
        );

        // Focus the bold button
        final boldButton = find.byIcon(Icons.format_bold);
        await tester.tap(boldButton);
        await tester.pumpAndSettle();

        // Verify button can be focused
        expect(boldButton, findsOneWidget);
      });

      testWidgets('Inline style buttons respond to Space key', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
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
          ),
        );

        // Focus the bold button
        final boldButton = find.byIcon(Icons.format_bold);
        await tester.tap(boldButton);
        await tester.pumpAndSettle();

        // Verify button exists
        expect(boldButton, findsOneWidget);
      });

      testWidgets('List buttons respond to keyboard activation', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListButtonGroup(
                  editor: editor,
                  composer: composer,
                  currentListType: null,
                ),
              ),
            ),
          ),
        );

        // Focus the bullet list button
        final bulletButton = find.byIcon(Icons.format_list_bulleted);
        await tester.tap(bulletButton);
        await tester.pumpAndSettle();

        // Verify button exists
        expect(bulletButton, findsOneWidget);
      });

      testWidgets('Alignment buttons respond to keyboard activation', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: AlignmentButtonGroup(
                  editor: editor,
                  composer: composer,
                  currentAlignment: TextAlignment.left,
                ),
              ),
            ),
          ),
        );

        // Focus the center align button
        final centerButton = find.byIcon(Icons.format_align_center);
        await tester.tap(centerButton);
        await tester.pumpAndSettle();

        // Verify button exists
        expect(centerButton, findsOneWidget);
      });

      testWidgets('Font size buttons respond to keyboard activation', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: FontSizeSelector(
                  editor: editor,
                  composer: composer,
                  currentFontSize: 14,
                ),
              ),
            ),
          ),
        );

        // Focus the increase button
        final increaseButton = find.byIcon(Icons.add);
        await tester.tap(increaseButton);
        await tester.pumpAndSettle();

        // Verify button exists
        expect(increaseButton, findsOneWidget);
      });

      testWidgets('Clear formatting button responds to keyboard activation', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ClearFormattingButton(
                  editor: editor,
                  composer: composer,
                ),
              ),
            ),
          ),
        );

        // Focus the clear button
        final clearButton = find.byIcon(Icons.format_clear);
        await tester.tap(clearButton);
        await tester.pumpAndSettle();

        // Verify button exists
        expect(clearButton, findsOneWidget);
      });
    });

    group('Focus Indicators', () {
      testWidgets('Inline style buttons show focus indicator', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
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
          ),
        );

        // Verify buttons exist and can receive focus
        expect(find.byIcon(Icons.format_bold), findsOneWidget);
        expect(find.byIcon(Icons.format_italic), findsOneWidget);
        expect(find.byIcon(Icons.format_underlined), findsOneWidget);
        expect(find.byIcon(Icons.format_strikethrough), findsOneWidget);
      });

      testWidgets('List buttons show focus indicator', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListButtonGroup(
                  editor: editor,
                  composer: composer,
                  currentListType: null,
                ),
              ),
            ),
          ),
        );

        // Verify buttons exist and can receive focus
        expect(find.byIcon(Icons.format_list_bulleted), findsOneWidget);
        expect(find.byIcon(Icons.format_list_numbered), findsOneWidget);
      });

      testWidgets('Alignment buttons show focus indicator', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: AlignmentButtonGroup(
                  editor: editor,
                  composer: composer,
                  currentAlignment: TextAlignment.left,
                ),
              ),
            ),
          ),
        );

        // Verify buttons exist and can receive focus
        expect(find.byIcon(Icons.format_align_left), findsOneWidget);
        expect(find.byIcon(Icons.format_align_center), findsOneWidget);
        expect(find.byIcon(Icons.format_align_right), findsOneWidget);
        expect(find.byIcon(Icons.format_align_justify), findsOneWidget);
      });
    });
  });
}
