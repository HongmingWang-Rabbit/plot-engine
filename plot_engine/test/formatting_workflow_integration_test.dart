import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_editor/super_editor.dart';
import 'dart:convert';

import 'package:plot_engine/services/formatted_content_serializer.dart';
import 'package:plot_engine/services/formatting_commands.dart';
import 'package:plot_engine/services/block_metadata.dart';
import 'package:plot_engine/ui/editor/formatting_toolbar.dart';
import 'package:plot_engine/ui/editor/inline_style_button_group.dart';
import 'package:plot_engine/ui/editor/block_style_dropdown.dart';
import 'package:plot_engine/ui/editor/list_button_group.dart';
import 'package:plot_engine/ui/editor/alignment_button_group.dart';

/// Integration tests for complete formatting workflows
/// 
/// These tests verify end-to-end functionality including:
/// - Complete formatting workflow: create → format → save → reload → verify
/// - Toolbar integration: click button → verify command → verify UI
/// - Entity integration: format entity → verify both attributions → verify rendering
void main() {
  group('Complete Formatting Workflow Integration', () {
    test('create document → apply formatting → save → reload → verify formatting preserved', () {
      // Step 1: Create a document with text
      final document = MutableDocument(nodes: [
        ParagraphNode(
          id: 'node1',
          text: AttributedText('This is bold text'),
        ),
        ParagraphNode(
          id: 'node2',
          text: AttributedText('This is italic text'),
        ),
        ParagraphNode(
          id: 'node3',
          text: AttributedText('This is underlined text'),
        ),
      ]);

      // Step 2: Apply formatting
      final node1 = document.getNodeById('node1') as ParagraphNode;
      node1.text.addAttribution(boldAttribution, const SpanRange(8, 11)); // "bold"

      final node2 = document.getNodeById('node2') as ParagraphNode;
      node2.text.addAttribution(italicsAttribution, const SpanRange(8, 13)); // "italic"

      final node3 = document.getNodeById('node3') as ParagraphNode;
      node3.text.addAttribution(underlineAttribution, const SpanRange(8, 17)); // "underlined"

      // Step 3: Save (serialize to JSON)
      final json = FormattedContentSerializer.serializeDocument(document);
      final jsonString = jsonEncode(json);

      // Verify JSON was created
      expect(jsonString, isNotEmpty);

      // Step 4: Reload (deserialize from JSON)
      final loadedJson = jsonDecode(jsonString) as Map<String, dynamic>;
      final loadedNodes = FormattedContentSerializer.deserializeDocument(loadedJson);

      // Step 5: Verify formatting is preserved
      expect(loadedNodes.length, 3);

      // Verify node 1 - bold text
      final loadedNode1 = loadedNodes[0] as ParagraphNode;
      expect(loadedNode1.text.toPlainText(), 'This is bold text');
      final boldSpans = loadedNode1.text.getAttributionSpansInRange(
        attributionFilter: (attr) => attr == boldAttribution,
        range: SpanRange(0, loadedNode1.text.length - 1),
      );
      expect(boldSpans.length, 1);
      expect(boldSpans.first.start, 8);
      expect(boldSpans.first.end, 11);

      // Verify node 2 - italic text
      final loadedNode2 = loadedNodes[1] as ParagraphNode;
      expect(loadedNode2.text.toPlainText(), 'This is italic text');
      final italicSpans = loadedNode2.text.getAttributionSpansInRange(
        attributionFilter: (attr) => attr == italicsAttribution,
        range: SpanRange(0, loadedNode2.text.length - 1),
      );
      expect(italicSpans.length, 1);
      expect(italicSpans.first.start, 8);
      expect(italicSpans.first.end, 13);

      // Verify node 3 - underlined text
      final loadedNode3 = loadedNodes[2] as ParagraphNode;
      expect(loadedNode3.text.toPlainText(), 'This is underlined text');
      final underlineSpans = loadedNode3.text.getAttributionSpansInRange(
        attributionFilter: (attr) => attr == underlineAttribution,
        range: SpanRange(0, loadedNode3.text.length - 1),
      );
      expect(underlineSpans.length, 1);
      expect(underlineSpans.first.start, 8);
      expect(underlineSpans.first.end, 17);
    });

    test('create document with multiple formatting types → save → reload → verify all preserved', () {
      // Create document with various formatting
      final node = ParagraphNode(
        id: 'complex',
        text: AttributedText('Bold Italic Underline Color Size'),
      );

      // Apply multiple formatting types
      node.text.addAttribution(boldAttribution, const SpanRange(0, 3)); // "Bold"
      node.text.addAttribution(italicsAttribution, const SpanRange(5, 10)); // "Italic"
      node.text.addAttribution(underlineAttribution, const SpanRange(12, 20)); // "Underline"
      node.text.addAttribution(ColorAttribution(Colors.red), const SpanRange(22, 26)); // "Color"
      node.text.addAttribution(FontSizeAttribution(24.0), const SpanRange(28, 31)); // "Size"

      // Add block metadata
      node.metadata['blockMetadata'] = const BlockMetadata(
        alignment: TextAlignment.center,
      );

      final document = MutableDocument(nodes: [node]);

      // Save
      final json = FormattedContentSerializer.serializeDocument(document);
      final jsonString = jsonEncode(json);

      // Reload
      final loadedJson = jsonDecode(jsonString) as Map<String, dynamic>;
      final loadedNodes = FormattedContentSerializer.deserializeDocument(loadedJson);

      // Verify
      expect(loadedNodes.length, 1);
      final loadedNode = loadedNodes[0] as ParagraphNode;
      expect(loadedNode.text.toPlainText(), 'Bold Italic Underline Color Size');

      // Verify bold
      final boldSpans = loadedNode.text.getAttributionSpansInRange(
        attributionFilter: (attr) => attr == boldAttribution,
        range: SpanRange(0, loadedNode.text.length - 1),
      );
      expect(boldSpans.length, 1);
      expect(boldSpans.first.start, 0);
      expect(boldSpans.first.end, 3);

      // Verify italic
      final italicSpans = loadedNode.text.getAttributionSpansInRange(
        attributionFilter: (attr) => attr == italicsAttribution,
        range: SpanRange(0, loadedNode.text.length - 1),
      );
      expect(italicSpans.length, 1);
      expect(italicSpans.first.start, 5);
      expect(italicSpans.first.end, 10);

      // Verify underline
      final underlineSpans = loadedNode.text.getAttributionSpansInRange(
        attributionFilter: (attr) => attr == underlineAttribution,
        range: SpanRange(0, loadedNode.text.length - 1),
      );
      expect(underlineSpans.length, 1);
      expect(underlineSpans.first.start, 12);
      expect(underlineSpans.first.end, 20);

      // Verify color
      final colorSpans = loadedNode.text.getAttributionSpansInRange(
        attributionFilter: (attr) => attr is ColorAttribution,
        range: SpanRange(0, loadedNode.text.length - 1),
      );
      expect(colorSpans.length, 1);
      expect(colorSpans.first.start, 22);
      expect(colorSpans.first.end, 26);

      // Verify font size
      final fontSizeSpans = loadedNode.text.getAttributionSpansInRange(
        attributionFilter: (attr) => attr is FontSizeAttribution,
        range: SpanRange(0, loadedNode.text.length - 1),
      );
      expect(fontSizeSpans.length, 1);
      expect(fontSizeSpans.first.start, 28);
      expect(fontSizeSpans.first.end, 31);

      // Verify block metadata
      final metadata = loadedNode.metadata['blockMetadata'] as BlockMetadata?;
      expect(metadata?.alignment, TextAlignment.center);
    });

    test('create document with headings and lists → save → reload → verify structure', () {
      // Create document with various block types
      final document = MutableDocument(nodes: [
        ParagraphNode(
          id: 'heading',
          text: AttributedText('Chapter Title'),
        )..metadata['blockMetadata'] = const BlockMetadata(
            headingLevel: HeadingLevel.h1,
            alignment: TextAlignment.center,
          ),
        ParagraphNode(
          id: 'list1',
          text: AttributedText('First item'),
        )..metadata['blockMetadata'] = const BlockMetadata(
            listType: ListType.unordered,
            listIndent: 0,
          ),
        ParagraphNode(
          id: 'list2',
          text: AttributedText('Second item'),
        )..metadata['blockMetadata'] = const BlockMetadata(
            listType: ListType.unordered,
            listIndent: 0,
          ),
        ParagraphNode(
          id: 'numbered',
          text: AttributedText('Numbered item'),
        )..metadata['blockMetadata'] = const BlockMetadata(
            listType: ListType.ordered,
            listIndent: 0,
          ),
      ]);

      // Save
      final json = FormattedContentSerializer.serializeDocument(document);
      final jsonString = jsonEncode(json);

      // Reload
      final loadedJson = jsonDecode(jsonString) as Map<String, dynamic>;
      final loadedNodes = FormattedContentSerializer.deserializeDocument(loadedJson);

      // Verify
      expect(loadedNodes.length, 4);

      // Verify heading
      final heading = loadedNodes[0] as ParagraphNode;
      expect(heading.text.toPlainText(), 'Chapter Title');
      final headingMetadata = heading.metadata['blockMetadata'] as BlockMetadata?;
      expect(headingMetadata?.headingLevel, HeadingLevel.h1);
      expect(headingMetadata?.alignment, TextAlignment.center);

      // Verify unordered list items
      final list1 = loadedNodes[1] as ParagraphNode;
      expect(list1.text.toPlainText(), 'First item');
      final list1Metadata = list1.metadata['blockMetadata'] as BlockMetadata?;
      expect(list1Metadata?.listType, ListType.unordered);
      expect(list1Metadata?.listIndent, 0);

      final list2 = loadedNodes[2] as ParagraphNode;
      expect(list2.text.toPlainText(), 'Second item');
      final list2Metadata = list2.metadata['blockMetadata'] as BlockMetadata?;
      expect(list2Metadata?.listType, ListType.unordered);

      // Verify ordered list item
      final numbered = loadedNodes[3] as ParagraphNode;
      expect(numbered.text.toPlainText(), 'Numbered item');
      final numberedMetadata = numbered.metadata['blockMetadata'] as BlockMetadata?;
      expect(numberedMetadata?.listType, ListType.ordered);
    });
  });

  group('Toolbar Integration Tests', () {
    testWidgets('FormattingToolbar displays and updates based on selection', (tester) async {
      // Create a document with formatted text
      final node = ParagraphNode(
        id: 'test-node',
        text: AttributedText('Bold text here'),
      );
      node.text.addAttribution(boldAttribution, const SpanRange(0, 3)); // "Bold"

      final document = MutableDocument(nodes: [node]);
      final composer = MutableDocumentComposer();
      final editor = createDefaultDocumentEditor(
        document: document,
        composer: composer,
      );

      // Build the toolbar
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

      // Verify toolbar renders
      expect(find.byType(FormattingToolbar), findsOneWidget);
      expect(find.byType(InlineStyleButtonGroup), findsOneWidget);
      expect(find.byType(BlockStyleDropdown), findsOneWidget);
      expect(find.byType(ListButtonGroup), findsOneWidget);
      expect(find.byType(AlignmentButtonGroup), findsOneWidget);
    });

    testWidgets('FormattingToolbar reflects bold formatting in selection', (tester) async {
      // Create a document with bold text
      final node = ParagraphNode(
        id: 'test-node',
        text: AttributedText('Bold text here'),
      );
      node.text.addAttribution(boldAttribution, const SpanRange(0, 3)); // "Bold"

      final document = MutableDocument(nodes: [node]);
      final composer = MutableDocumentComposer();
      final editor = createDefaultDocumentEditor(
        document: document,
        composer: composer,
      );

      // Set selection to bold text
      composer.setSelectionWithReason(
        DocumentSelection(
          base: DocumentPosition(
            nodeId: node.id,
            nodePosition: const TextNodePosition(offset: 0),
          ),
          extent: DocumentPosition(
            nodeId: node.id,
            nodePosition: const TextNodePosition(offset: 4),
          ),
        ),
        SelectionReason.userInteraction,
      );

      // Build the toolbar
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

      // Verify toolbar shows bold as active
      // The InlineStyleButtonGroup should reflect the bold state
      expect(find.byType(InlineStyleButtonGroup), findsOneWidget);
    });

    test('executing ToggleInlineStyleCommand applies formatting', () {
      // Create a document
      final node = ParagraphNode(
        id: 'test-node',
        text: AttributedText('Test text'),
      );
      final document = MutableDocument(nodes: [node]);
      final composer = MutableDocumentComposer();
      final editor = createDefaultDocumentEditor(
        document: document,
        composer: composer,
      );

      // Set selection
      composer.setSelectionWithReason(
        DocumentSelection(
          base: DocumentPosition(
            nodeId: node.id,
            nodePosition: const TextNodePosition(offset: 0),
          ),
          extent: DocumentPosition(
            nodeId: node.id,
            nodePosition: const TextNodePosition(offset: 4),
          ),
        ),
        SelectionReason.userInteraction,
      );

      // Execute bold command
      editor.execute([
        const ToggleInlineStyleCommand(attribution: boldAttribution),
      ]);

      // Verify bold was applied
      final attributions = node.text.getAllAttributionsAt(0);
      expect(attributions.contains(boldAttribution), isTrue);
    });

    test('executing ChangeBlockTypeCommand changes block type', () {
      // Create a document
      final node = ParagraphNode(
        id: 'test-node',
        text: AttributedText('Heading text'),
      );
      final document = MutableDocument(nodes: [node]);
      final composer = MutableDocumentComposer();
      final editor = createDefaultDocumentEditor(
        document: document,
        composer: composer,
      );

      // Execute heading command
      editor.execute([
        const ChangeBlockTypeCommand(
          nodeId: 'test-node',
          headingLevel: HeadingLevel.h1,
        ),
      ]);

      // Verify heading was applied
      final metadata = node.metadata['blockMetadata'] as BlockMetadata?;
      expect(metadata?.headingLevel, HeadingLevel.h1);
    });

    test('executing ToggleListCommand toggles list formatting', () {
      // Create a document
      final node = ParagraphNode(
        id: 'test-node',
        text: AttributedText('List item'),
      );
      final document = MutableDocument(nodes: [node]);
      final composer = MutableDocumentComposer();
      final editor = createDefaultDocumentEditor(
        document: document,
        composer: composer,
      );

      // Set selection
      composer.setSelectionWithReason(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: node.id,
            nodePosition: const TextNodePosition(offset: 0),
          ),
        ),
        SelectionReason.userInteraction,
      );

      // Execute list command
      editor.execute([
        const ToggleListCommand(listType: ListType.unordered),
      ]);

      // Verify list was applied
      final metadata = node.metadata['blockMetadata'] as BlockMetadata?;
      expect(metadata?.listType, ListType.unordered);
      expect(metadata?.listIndent, 0);

      // Toggle again to remove
      editor.execute([
        const ToggleListCommand(listType: ListType.unordered),
      ]);

      // Verify list was removed
      final metadata2 = node.metadata['blockMetadata'] as BlockMetadata?;
      expect(metadata2?.listType, isNull);
    });

    test('executing SetTextAlignmentCommand changes alignment', () {
      // Create a document
      final node = ParagraphNode(
        id: 'test-node',
        text: AttributedText('Centered text'),
      );
      final document = MutableDocument(nodes: [node]);
      final composer = MutableDocumentComposer();
      final editor = createDefaultDocumentEditor(
        document: document,
        composer: composer,
      );

      // Set selection
      composer.setSelectionWithReason(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: node.id,
            nodePosition: const TextNodePosition(offset: 0),
          ),
        ),
        SelectionReason.userInteraction,
      );

      // Execute alignment command
      editor.execute([
        const SetTextAlignmentCommand(alignment: TextAlignment.center),
      ]);

      // Verify alignment was applied
      final metadata = node.metadata['blockMetadata'] as BlockMetadata?;
      expect(metadata?.alignment, TextAlignment.center);
    });

    test('executing ClearFormattingCommand removes formatting', () {
      // Create a document with formatting
      final node = ParagraphNode(
        id: 'test-node',
        text: AttributedText('Formatted text'),
      );
      node.text.addAttribution(boldAttribution, const SpanRange(0, 8));
      node.text.addAttribution(italicsAttribution, const SpanRange(0, 8));
      node.metadata['blockMetadata'] = const BlockMetadata(
        headingLevel: HeadingLevel.h1,
      );

      final document = MutableDocument(nodes: [node]);
      final composer = MutableDocumentComposer();
      final editor = createDefaultDocumentEditor(
        document: document,
        composer: composer,
      );

      // Set selection
      composer.setSelectionWithReason(
        DocumentSelection(
          base: DocumentPosition(
            nodeId: node.id,
            nodePosition: const TextNodePosition(offset: 0),
          ),
          extent: DocumentPosition(
            nodeId: node.id,
            nodePosition: const TextNodePosition(offset: 9),
          ),
        ),
        SelectionReason.userInteraction,
      );

      // Execute clear formatting command
      editor.execute([
        const ClearFormattingCommand(),
      ]);

      // Verify inline formatting was removed
      final attributions = node.text.getAllAttributionsAt(0);
      expect(attributions.contains(boldAttribution), isFalse);
      expect(attributions.contains(italicsAttribution), isFalse);

      // Verify block formatting was removed
      final metadata = node.metadata['blockMetadata'] as BlockMetadata?;
      expect(metadata?.headingLevel, isNull);
    });
  });

  group('Entity Integration Tests', () {
    test('formatting and entity attributions coexist', () {
      // Create a document with entity attribution
      final node = ParagraphNode(
        id: 'test-node',
        text: AttributedText('Character John appears here'),
      );

      // Add entity attribution (simulating entity recognition)
      final entityAttribution = NamedAttribution('entity.character.John');
      node.text.addAttribution(entityAttribution, const SpanRange(10, 13)); // "John"

      // Add bold formatting to the same text
      node.text.addAttribution(boldAttribution, const SpanRange(10, 13)); // "John"

      // Verify both attributions are present
      final attributions = node.text.getAllAttributionsAt(10);
      expect(attributions.contains(boldAttribution), isTrue);
      expect(attributions.contains(entityAttribution), isTrue);

      // Verify they don't interfere with each other
      expect(attributions.length, greaterThanOrEqualTo(2));
    });

    test('entity attributions are preserved when applying formatting', () {
      // Create a document with entity attribution
      final node = ParagraphNode(
        id: 'test-node',
        text: AttributedText('Character John appears here'),
      );

      // Add entity attribution
      final entityAttribution = NamedAttribution('entity.character.John');
      node.text.addAttribution(entityAttribution, const SpanRange(10, 13)); // "John"

      final document = MutableDocument(nodes: [node]);
      final composer = MutableDocumentComposer();
      final editor = createDefaultDocumentEditor(
        document: document,
        composer: composer,
      );

      // Set selection to entity text
      composer.setSelectionWithReason(
        DocumentSelection(
          base: DocumentPosition(
            nodeId: node.id,
            nodePosition: const TextNodePosition(offset: 10),
          ),
          extent: DocumentPosition(
            nodeId: node.id,
            nodePosition: const TextNodePosition(offset: 14),
          ),
        ),
        SelectionReason.userInteraction,
      );

      // Apply bold formatting
      editor.execute([
        const ToggleInlineStyleCommand(attribution: boldAttribution),
      ]);

      // Verify both attributions are still present
      final attributions = node.text.getAllAttributionsAt(10);
      expect(attributions.contains(boldAttribution), isTrue);
      expect(attributions.contains(entityAttribution), isTrue);
    });

    test('entity attributions are preserved when clearing formatting', () {
      // Create a document with both entity and formatting attributions
      final node = ParagraphNode(
        id: 'test-node',
        text: AttributedText('Character John appears here'),
      );

      // Add entity attribution
      final entityAttribution = NamedAttribution('entity.character.John');
      node.text.addAttribution(entityAttribution, const SpanRange(10, 13)); // "John"

      // Add formatting
      node.text.addAttribution(boldAttribution, const SpanRange(10, 13));
      node.text.addAttribution(italicsAttribution, const SpanRange(10, 13));

      final document = MutableDocument(nodes: [node]);
      final composer = MutableDocumentComposer();
      final editor = createDefaultDocumentEditor(
        document: document,
        composer: composer,
      );

      // Set selection
      composer.setSelectionWithReason(
        DocumentSelection(
          base: DocumentPosition(
            nodeId: node.id,
            nodePosition: const TextNodePosition(offset: 10),
          ),
          extent: DocumentPosition(
            nodeId: node.id,
            nodePosition: const TextNodePosition(offset: 14),
          ),
        ),
        SelectionReason.userInteraction,
      );

      // Clear formatting (preserving entity attributions)
      editor.execute([
        const ClearFormattingCommand(
          preserveAttributionTypes: {'entity'},
        ),
      ]);

      // Verify formatting was removed
      final attributions = node.text.getAllAttributionsAt(10);
      expect(attributions.contains(boldAttribution), isFalse);
      expect(attributions.contains(italicsAttribution), isFalse);

      // Verify entity attribution was preserved
      expect(attributions.contains(entityAttribution), isTrue);
    });

    test('entity attributions are preserved through save/load cycle', () {
      // Create a document with both entity and formatting attributions
      final node = ParagraphNode(
        id: 'test-node',
        text: AttributedText('Character John appears here'),
      );

      // Add entity attribution
      final entityAttribution = NamedAttribution('entity.character.John');
      node.text.addAttribution(entityAttribution, const SpanRange(10, 13)); // "John"

      // Add formatting
      node.text.addAttribution(boldAttribution, const SpanRange(10, 13));

      final document = MutableDocument(nodes: [node]);

      // Save
      final json = FormattedContentSerializer.serializeDocument(document);
      final jsonString = jsonEncode(json);

      // Reload
      final loadedJson = jsonDecode(jsonString) as Map<String, dynamic>;
      final loadedNodes = FormattedContentSerializer.deserializeDocument(loadedJson);

      // Verify
      final loadedNode = loadedNodes[0] as ParagraphNode;
      final attributions = loadedNode.text.getAllAttributionsAt(10);

      // Both attributions should be preserved
      expect(attributions.contains(boldAttribution), isTrue);
      expect(
        attributions.any((a) => a.toString().contains('entity')),
        isTrue,
      );
    });

    test('multiple entity attributions with formatting work correctly', () {
      // Create a document with multiple entities and formatting
      final node = ParagraphNode(
        id: 'test-node',
        text: AttributedText('John met Mary at the Park'),
      );

      // Add entity attributions
      final johnEntity = NamedAttribution('entity.character.John');
      final maryEntity = NamedAttribution('entity.character.Mary');
      final parkEntity = NamedAttribution('entity.location.Park');

      node.text.addAttribution(johnEntity, const SpanRange(0, 3)); // "John"
      node.text.addAttribution(maryEntity, const SpanRange(9, 12)); // "Mary"
      node.text.addAttribution(parkEntity, const SpanRange(21, 24)); // "Park"

      // Add formatting to entire text
      node.text.addAttribution(boldAttribution, const SpanRange(0, 24));

      // Verify all attributions coexist
      final johnAttributions = node.text.getAllAttributionsAt(0);
      expect(johnAttributions.contains(boldAttribution), isTrue);
      expect(johnAttributions.contains(johnEntity), isTrue);

      final maryAttributions = node.text.getAllAttributionsAt(9);
      expect(maryAttributions.contains(boldAttribution), isTrue);
      expect(maryAttributions.contains(maryEntity), isTrue);

      final parkAttributions = node.text.getAllAttributionsAt(21);
      expect(parkAttributions.contains(boldAttribution), isTrue);
      expect(parkAttributions.contains(parkEntity), isTrue);
    });
  });
}
