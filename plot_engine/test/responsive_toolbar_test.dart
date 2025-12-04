import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_editor/super_editor.dart';
import 'package:plot_engine/ui/editor/formatting_toolbar.dart';
import 'package:plot_engine/services/formatting_commands.dart';

void main() {
  group('Responsive FormattingToolbar', () {
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

    testWidgets('Desktop viewport shows full toolbar', (tester) async {
      // Set desktop viewport size (1200px wide)
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

      await tester.pumpAndSettle();

      // Verify inline style buttons are visible
      expect(find.byIcon(Icons.format_bold), findsOneWidget);
      expect(find.byIcon(Icons.format_italic), findsOneWidget);
      expect(find.byIcon(Icons.format_underlined), findsOneWidget);
      expect(find.byIcon(Icons.format_strikethrough), findsOneWidget);

      // Verify color picker buttons are visible
      expect(find.byIcon(Icons.format_color_text), findsOneWidget);
      expect(find.byIcon(Icons.format_color_fill), findsOneWidget);

      // Verify list buttons are visible
      expect(find.byIcon(Icons.format_list_bulleted), findsOneWidget);
      expect(find.byIcon(Icons.format_list_numbered), findsOneWidget);

      // Verify alignment buttons are visible
      expect(find.byIcon(Icons.format_align_left), findsOneWidget);
      expect(find.byIcon(Icons.format_align_center), findsOneWidget);
      expect(find.byIcon(Icons.format_align_right), findsOneWidget);
      expect(find.byIcon(Icons.format_align_justify), findsOneWidget);

      // Verify clear formatting button is visible
      expect(find.byIcon(Icons.format_clear), findsOneWidget);

      // Verify overflow menu is NOT visible on desktop
      expect(find.byIcon(Icons.more_vert), findsNothing);
    });

    testWidgets('Tablet viewport shows compact toolbar with overflow menu', (tester) async {
      // Set tablet viewport size (800px wide)
      await tester.binding.setSurfaceSize(const Size(800, 600));

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

      await tester.pumpAndSettle();

      // Verify inline style buttons are visible
      expect(find.byIcon(Icons.format_bold), findsOneWidget);
      expect(find.byIcon(Icons.format_italic), findsOneWidget);
      expect(find.byIcon(Icons.format_underlined), findsOneWidget);
      expect(find.byIcon(Icons.format_strikethrough), findsOneWidget);

      // Verify list buttons are visible on tablet
      expect(find.byIcon(Icons.format_list_bulleted), findsOneWidget);
      expect(find.byIcon(Icons.format_list_numbered), findsOneWidget);

      // Verify overflow menu IS visible on tablet
      expect(find.byIcon(Icons.more_vert), findsOneWidget);

      // Verify alignment buttons are NOT directly visible (in overflow menu)
      expect(find.byIcon(Icons.format_align_left), findsNothing);
      expect(find.byIcon(Icons.format_align_center), findsNothing);
    });

    testWidgets('Mobile viewport shows minimal toolbar with overflow menu', (tester) async {
      // Set mobile viewport size (400px wide)
      await tester.binding.setSurfaceSize(const Size(400, 800));

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

      await tester.pumpAndSettle();

      // Verify inline style buttons are visible
      expect(find.byIcon(Icons.format_bold), findsOneWidget);
      expect(find.byIcon(Icons.format_italic), findsOneWidget);
      expect(find.byIcon(Icons.format_underlined), findsOneWidget);
      expect(find.byIcon(Icons.format_strikethrough), findsOneWidget);

      // Verify overflow menu IS visible on mobile
      expect(find.byIcon(Icons.more_vert), findsOneWidget);

      // Verify list buttons are NOT directly visible on mobile (in overflow menu)
      expect(find.byIcon(Icons.format_list_bulleted), findsNothing);
      expect(find.byIcon(Icons.format_list_numbered), findsNothing);

      // Verify alignment buttons are NOT directly visible (in overflow menu)
      expect(find.byIcon(Icons.format_align_left), findsNothing);
      expect(find.byIcon(Icons.format_align_center), findsNothing);
    });

    testWidgets('Overflow menu shows additional options on mobile', (tester) async {
      // Set mobile viewport size
      await tester.binding.setSurfaceSize(const Size(400, 800));

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

      await tester.pumpAndSettle();

      // Tap overflow menu button
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Verify menu items are visible
      expect(find.text('Block Style'), findsOneWidget);
      expect(find.text('Lists'), findsOneWidget);
      expect(find.text('Alignment'), findsOneWidget);
      expect(find.text('Bullet List'), findsOneWidget);
      expect(find.text('Numbered List'), findsOneWidget);
      expect(find.text('Align Left'), findsOneWidget);
      expect(find.text('Align Center'), findsOneWidget);
      expect(find.text('Align Right'), findsOneWidget);
      expect(find.text('Justify'), findsOneWidget);
      expect(find.text('Clear Formatting'), findsOneWidget);
    });

    testWidgets('Overflow menu shows alignment options on tablet', (tester) async {
      // Set tablet viewport size
      await tester.binding.setSurfaceSize(const Size(800, 600));

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

      await tester.pumpAndSettle();

      // Tap overflow menu button
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Verify alignment menu items are visible
      expect(find.text('Alignment'), findsOneWidget);
      expect(find.text('Align Left'), findsOneWidget);
      expect(find.text('Align Center'), findsOneWidget);
      expect(find.text('Align Right'), findsOneWidget);
      expect(find.text('Justify'), findsOneWidget);

      // Verify block style and list options are NOT in overflow menu on tablet
      // (they're visible directly in the toolbar)
      expect(find.text('Block Style'), findsNothing);
      expect(find.text('Lists'), findsNothing);
    });
  });
}
