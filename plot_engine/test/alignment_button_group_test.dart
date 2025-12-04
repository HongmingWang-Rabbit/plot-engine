/// Widget tests for AlignmentButtonGroup
/// 
/// These tests verify that the alignment button group renders correctly
/// and executes the correct commands.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'package:plot_engine/ui/editor/alignment_button_group.dart';
import 'package:plot_engine/services/block_metadata.dart';

void main() {
  group('AlignmentButtonGroup Widget Tests', () {
    late Editor editor;
    late DocumentComposer composer;
    late MutableDocument document;

    setUp(() {
      // Create a simple document with one paragraph
      document = MutableDocument(
        nodes: [
          ParagraphNode(
            id: 'node1',
            text: AttributedText('Test paragraph'),
          ),
        ],
      );

      composer = MutableDocumentComposer();
      editor = createDefaultDocumentEditor(
        document: document,
        composer: composer,
      );
    });

    testWidgets('renders all four alignment buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlignmentButtonGroup(
              editor: editor,
              composer: composer,
              currentAlignment: TextAlignment.left,
            ),
          ),
        ),
      );

      // Verify all four alignment buttons are present
      expect(find.byIcon(Icons.format_align_left), findsOneWidget);
      expect(find.byIcon(Icons.format_align_center), findsOneWidget);
      expect(find.byIcon(Icons.format_align_right), findsOneWidget);
      expect(find.byIcon(Icons.format_align_justify), findsOneWidget);
    });

    testWidgets('highlights the current alignment button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlignmentButtonGroup(
              editor: editor,
              composer: composer,
              currentAlignment: TextAlignment.center,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The center button should be highlighted
      // We can verify this by checking the Material widget's color
      final centerButton = tester.widget<Material>(
        find.ancestor(
          of: find.byIcon(Icons.format_align_center),
          matching: find.byType(Material),
        ).first,
      );

      // The active button should have a non-transparent color
      expect(centerButton.color, isNot(Colors.transparent));
    });

    testWidgets('executes SetTextAlignmentCommand when button is tapped', (tester) async {
      // Set up a selection
      composer.selection = DocumentSelection(
        base: DocumentPosition(
          nodeId: 'node1',
          nodePosition: const TextNodePosition(offset: 0),
        ),
        extent: DocumentPosition(
          nodeId: 'node1',
          nodePosition: const TextNodePosition(offset: 4),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlignmentButtonGroup(
              editor: editor,
              composer: composer,
              currentAlignment: TextAlignment.left,
            ),
          ),
        ),
      );

      // Tap the center alignment button
      await tester.tap(find.byIcon(Icons.format_align_center));
      await tester.pumpAndSettle();

      // Verify the command was executed by checking the node metadata
      final node = document.getNodeById('node1') as ParagraphNode;
      final metadata = node.metadata['blockMetadata'] as BlockMetadata?;
      
      expect(metadata?.alignment, equals(TextAlignment.center));
    });

    testWidgets('shows tooltips with keyboard shortcuts', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlignmentButtonGroup(
              editor: editor,
              composer: composer,
              currentAlignment: TextAlignment.left,
            ),
          ),
        ),
      );

      // Long press on the left align button to show tooltip
      await tester.longPress(find.byIcon(Icons.format_align_left));
      await tester.pumpAndSettle();

      // Verify tooltip is shown (contains "Align Left")
      expect(find.text('Align Left (⌘+Shift+L)', findRichText: true), findsOneWidget);
    });

    testWidgets('all alignment buttons are tappable', (tester) async {
      composer.selection = DocumentSelection(
        base: DocumentPosition(
          nodeId: 'node1',
          nodePosition: const TextNodePosition(offset: 0),
        ),
        extent: DocumentPosition(
          nodeId: 'node1',
          nodePosition: const TextNodePosition(offset: 4),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlignmentButtonGroup(
              editor: editor,
              composer: composer,
              currentAlignment: TextAlignment.left,
            ),
          ),
        ),
      );

      final node = document.getNodeById('node1') as ParagraphNode;

      // Test left alignment
      await tester.tap(find.byIcon(Icons.format_align_left));
      await tester.pumpAndSettle();
      var metadata = node.metadata['blockMetadata'] as BlockMetadata?;
      expect(metadata?.alignment, equals(TextAlignment.left));

      // Test center alignment
      await tester.tap(find.byIcon(Icons.format_align_center));
      await tester.pumpAndSettle();
      metadata = node.metadata['blockMetadata'] as BlockMetadata?;
      expect(metadata?.alignment, equals(TextAlignment.center));

      // Test right alignment
      await tester.tap(find.byIcon(Icons.format_align_right));
      await tester.pumpAndSettle();
      metadata = node.metadata['blockMetadata'] as BlockMetadata?;
      expect(metadata?.alignment, equals(TextAlignment.right));

      // Test justify alignment
      await tester.tap(find.byIcon(Icons.format_align_justify));
      await tester.pumpAndSettle();
      metadata = node.metadata['blockMetadata'] as BlockMetadata?;
      expect(metadata?.alignment, equals(TextAlignment.justify));
    });
  });
}
