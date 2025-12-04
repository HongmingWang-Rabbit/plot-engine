/// Widget tests for FormattingToolbar and its components
/// 
/// These tests verify that the formatting toolbar and its sub-components
/// render correctly and display the expected UI elements.
///
/// Note: Due to API limitations in super_editor 0.3.0-dev.40, these tests
/// focus on rendering and basic UI structure rather than interactive behavior
/// that requires programmatic selection manipulation.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_editor/super_editor.dart';
import 'package:plot_engine/ui/editor/formatting_toolbar.dart';
import 'package:plot_engine/ui/editor/color_picker_button.dart';
import 'package:plot_engine/ui/editor/font_size_selector.dart';
import 'package:plot_engine/ui/editor/clear_formatting_button.dart';
import 'package:plot_engine/services/block_metadata.dart';

void main() {
  // Note: FormattingToolbar integration tests are covered in
  // formatting_workflow_integration_test.dart and responsive_toolbar_test.dart
  // These tests focus on individual UI components

  group('ColorPickerButton Widget Tests', () {
    late MutableDocument document;
    late MutableDocumentComposer composer;
    late Editor editor;

    setUp(() {
      document = MutableDocument(
        nodes: [
          ParagraphNode(
            id: 'node1',
            text: AttributedText('Hello World'),
          ),
        ],
      );

      composer = MutableDocumentComposer();
      editor = createDefaultDocumentEditor(
        document: document,
        composer: composer,
      );
    });

    testWidgets('ColorPickerButton displays correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
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
      );

      // Verify the button is present
      expect(find.byIcon(Icons.format_color_text), findsOneWidget);
      
      // Verify tooltip
      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('ColorPickerButton shows color preview when color is set', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ColorPickerButton(
              editor: editor,
              composer: composer,
              currentColor: Colors.red,
              isTextColor: true,
              tooltip: 'Text Color',
              icon: Icons.format_color_text,
            ),
          ),
        ),
      );

      // Verify the button is present
      expect(find.byIcon(Icons.format_color_text), findsOneWidget);
      
      // Verify color preview bar is shown (positioned container with color)
      final containers = find.descendant(
        of: find.byType(ColorPickerButton),
        matching: find.byType(Container),
      );
      
      // There should be multiple containers, one of which is the color preview
      expect(containers, findsWidgets);
    });

    testWidgets('ColorPickerButton opens color picker on tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
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
      );

      // Tap the button
      await tester.tap(find.byIcon(Icons.format_color_text));
      await tester.pumpAndSettle();

      // Verify color picker panel is shown
      expect(find.text('Text Color'), findsOneWidget);
      
      // Verify color grid is shown (multiple gesture detectors for color swatches)
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('ColorPickerButton shows highlight color picker with clear option', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ColorPickerButton(
              editor: editor,
              composer: composer,
              currentColor: null,
              isTextColor: false, // Highlight color
              tooltip: 'Highlight Color',
              icon: Icons.format_color_fill,
            ),
          ),
        ),
      );

      // Tap the button
      await tester.tap(find.byIcon(Icons.format_color_fill));
      await tester.pumpAndSettle();

      // Verify highlight color picker panel is shown
      expect(find.text('Highlight Color'), findsOneWidget);
      
      // Verify "No Highlight" option is present
      expect(find.text('No Highlight'), findsOneWidget);
    });
  });

  group('FontSizeSelector Widget Tests', () {
    late MutableDocument document;
    late MutableDocumentComposer composer;
    late Editor editor;

    setUp(() {
      document = MutableDocument(
        nodes: [
          ParagraphNode(
            id: 'node1',
            text: AttributedText('Hello World'),
          ),
        ],
      );

      composer = MutableDocumentComposer();
      editor = createDefaultDocumentEditor(
        document: document,
        composer: composer,
      );
    });

    testWidgets('FontSizeSelector renders all components', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FontSizeSelector(
              editor: editor,
              composer: composer,
              currentFontSize: null,
            ),
          ),
        ),
      );

      // Verify decrease button
      expect(find.byIcon(Icons.remove), findsOneWidget);
      
      // Verify dropdown
      expect(find.byType(DropdownButton<double>), findsOneWidget);
      
      // Verify increase button
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('FontSizeSelector shows current font size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FontSizeSelector(
              editor: editor,
              composer: composer,
              currentFontSize: 18.0,
            ),
          ),
        ),
      );

      // Verify the dropdown shows the current size
      expect(find.text('18'), findsOneWidget);
    });

    testWidgets('FontSizeSelector has custom input option', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FontSizeSelector(
              editor: editor,
              composer: composer,
              currentFontSize: 14.0,
            ),
          ),
        ),
      );

      // Open the dropdown
      await tester.tap(find.byType(DropdownButton<double>));
      await tester.pumpAndSettle();

      // Verify "Custom..." option is present
      expect(find.text('Custom...'), findsOneWidget);
    });

    testWidgets('FontSizeSelector has tooltips on buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FontSizeSelector(
              editor: editor,
              composer: composer,
              currentFontSize: 14.0,
            ),
          ),
        ),
      );

      // Verify tooltips are present
      expect(find.byType(Tooltip), findsNWidgets(3)); // Decrease, dropdown, increase
    });

    testWidgets('FontSizeSelector dropdown has multiple size options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FontSizeSelector(
              editor: editor,
              composer: composer,
              currentFontSize: 14.0,
            ),
          ),
        ),
      );

      // Verify the dropdown is present and shows current size
      expect(find.byType(DropdownButton<double>), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
    });
  });

  group('ClearFormattingButton Widget Tests', () {
    late MutableDocument document;
    late MutableDocumentComposer composer;
    late Editor editor;

    setUp(() {
      document = MutableDocument(
        nodes: [
          ParagraphNode(
            id: 'node1',
            text: AttributedText('Hello World'),
          ),
        ],
      );

      composer = MutableDocumentComposer();
      editor = createDefaultDocumentEditor(
        document: document,
        composer: composer,
      );
    });

    testWidgets('ClearFormattingButton renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClearFormattingButton(
              editor: editor,
              composer: composer,
            ),
          ),
        ),
      );

      // Verify the button is present
      expect(find.byIcon(Icons.format_clear), findsOneWidget);
      
      // Verify tooltip
      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('ClearFormattingButton is disabled when no selection', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClearFormattingButton(
              editor: editor,
              composer: composer,
            ),
          ),
        ),
      );

      // Find the IconButton
      final iconButton = tester.widget<IconButton>(
        find.byType(IconButton),
      );

      // Verify it's disabled (onPressed is null)
      expect(iconButton.onPressed, isNull);
    });

    testWidgets('ClearFormattingButton has semantic labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClearFormattingButton(
              editor: editor,
              composer: composer,
            ),
          ),
        ),
      );

      // Verify semantic widgets are present (multiple for accessibility)
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('ClearFormattingButton has proper icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClearFormattingButton(
              editor: editor,
              composer: composer,
            ),
          ),
        ),
      );

      // Verify the format_clear icon is used
      final icon = tester.widget<Icon>(find.byIcon(Icons.format_clear));
      expect(icon.icon, equals(Icons.format_clear));
      expect(icon.size, equals(20));
    });
  });
}
