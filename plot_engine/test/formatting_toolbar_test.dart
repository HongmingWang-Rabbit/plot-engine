import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'package:plot_engine/ui/editor/formatting_toolbar.dart';
import 'package:plot_engine/services/block_metadata.dart';
import 'dart:math' as math;

void main() {
  group('FormattingToolbar', () {
    // Feature: rich-text-styling, Property 26: Toolbar reflects selection formatting
    // Validates: Requirements 9.1, 9.2, 9.3, 9.4
    test('Property 26: Toolbar reflects selection formatting - inline styles', () {
      final random = math.Random(50);
      
      for (int iteration = 0; iteration < 100; iteration++) {
        // Generate random text (10-100 characters)
        final textLength = 10 + random.nextInt(91);
        final text = _generateRandomText(textLength, random);
        
        // Create a document with the text
        final attributedText = AttributedText(text);
        final node = ParagraphNode(
          id: 'test-node',
          text: attributedText,
        );
        final document = MutableDocument(nodes: [node]);
        
        // Generate random selection within text bounds
        final selectionStart = random.nextInt(textLength);
        final selectionEnd = selectionStart + random.nextInt(textLength - selectionStart) + 1;
        
        // Randomly apply inline styles to the selection
        final styles = [
          boldAttribution,
          italicsAttribution,
          underlineAttribution,
          strikethroughAttribution,
        ];
        
        // Randomly select 0-4 styles to apply
        final numStylesToApply = random.nextInt(5);
        final appliedStyles = <Attribution>{};
        
        for (int i = 0; i < numStylesToApply && i < styles.length; i++) {
          final style = styles[i];
          node.text.addAttribution(
            style,
            SpanRange(selectionStart, selectionEnd - 1),
          );
          appliedStyles.add(style);
        }
        
        // Create selection
        final selection = DocumentSelection(
          base: DocumentPosition(
            nodeId: node.id,
            nodePosition: TextNodePosition(offset: selectionStart),
          ),
          extent: DocumentPosition(
            nodeId: node.id,
            nodePosition: TextNodePosition(offset: selectionEnd),
          ),
        );
        
        // Extract formatting state
        final formattingState = FormattingState.fromSelection(document, selection, {});
        
        // VERIFY: Toolbar state reflects applied inline styles
        expect(
          formattingState.isBold,
          equals(appliedStyles.contains(boldAttribution)),
          reason: 'Toolbar should show bold=${appliedStyles.contains(boldAttribution)} '
              '(iteration $iteration)',
        );
        
        expect(
          formattingState.isItalic,
          equals(appliedStyles.contains(italicsAttribution)),
          reason: 'Toolbar should show italic=${appliedStyles.contains(italicsAttribution)} '
              '(iteration $iteration)',
        );
        
        expect(
          formattingState.isUnderline,
          equals(appliedStyles.contains(underlineAttribution)),
          reason: 'Toolbar should show underline=${appliedStyles.contains(underlineAttribution)} '
              '(iteration $iteration)',
        );
        
        expect(
          formattingState.isStrikethrough,
          equals(appliedStyles.contains(strikethroughAttribution)),
          reason: 'Toolbar should show strikethrough=${appliedStyles.contains(strikethroughAttribution)} '
              '(iteration $iteration)',
        );
        
        expect(
          formattingState.hasSelection,
          isTrue,
          reason: 'Toolbar should indicate selection is present (iteration $iteration)',
        );
      }
    });
    
    // Feature: rich-text-styling, Property 26: Toolbar reflects selection formatting - block styles
    // Validates: Requirements 9.3
    test('Property 26: Toolbar reflects selection formatting - heading levels', () {
      final random = math.Random(51);
      
      for (int iteration = 0; iteration < 100; iteration++) {
        // Generate random text
        final textLength = 10 + random.nextInt(91);
        final text = _generateRandomText(textLength, random);
        
        // Randomly select a heading level or null (normal paragraph)
        HeadingLevel? headingLevel;
        final hasHeading = random.nextBool();
        if (hasHeading) {
          headingLevel = HeadingLevel.values[random.nextInt(HeadingLevel.values.length)];
        }
        
        // Create a paragraph node with block metadata
        final attributedText = AttributedText(text);
        final node = ParagraphNode(
          id: 'test-node',
          text: attributedText,
          metadata: {
            'blockMetadata': BlockMetadata(headingLevel: headingLevel),
          },
        );
        final document = MutableDocument(nodes: [node]);
        
        // Create selection (collapsed at start)
        final selection = DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: node.id,
            nodePosition: const TextNodePosition(offset: 0),
          ),
        );
        
        // Extract formatting state
        final formattingState = FormattingState.fromSelection(document, selection, {});
        
        // VERIFY: Toolbar state reflects heading level
        expect(
          formattingState.headingLevel,
          equals(headingLevel),
          reason: 'Toolbar should show heading level $headingLevel (iteration $iteration)',
        );
      }
    });
    
    // Feature: rich-text-styling, Property 26: Toolbar reflects selection formatting - list types
    // Validates: Requirements 9.4
    test('Property 26: Toolbar reflects selection formatting - list types', () {
      final random = math.Random(52);
      
      for (int iteration = 0; iteration < 100; iteration++) {
        // Generate random text
        final textLength = 10 + random.nextInt(91);
        final text = _generateRandomText(textLength, random);
        
        // Randomly select a list type or null (not a list)
        ListType? listType;
        final hasList = random.nextBool();
        if (hasList) {
          listType = ListType.values[random.nextInt(ListType.values.length)];
        }
        
        // Create a paragraph node with block metadata
        final attributedText = AttributedText(text);
        final node = ParagraphNode(
          id: 'test-node',
          text: attributedText,
          metadata: {
            'blockMetadata': BlockMetadata(listType: listType, listIndent: 0),
          },
        );
        final document = MutableDocument(nodes: [node]);
        
        // Create selection (collapsed at start)
        final selection = DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: node.id,
            nodePosition: const TextNodePosition(offset: 0),
          ),
        );
        
        // Extract formatting state
        final formattingState = FormattingState.fromSelection(document, selection, {});
        
        // VERIFY: Toolbar state reflects list type
        expect(
          formattingState.listType,
          equals(listType),
          reason: 'Toolbar should show list type $listType (iteration $iteration)',
        );
      }
    });
    
    // Feature: rich-text-styling, Property 26: Toolbar reflects selection formatting - text alignment
    // Validates: Requirements 9.3
    test('Property 26: Toolbar reflects selection formatting - text alignment', () {
      final random = math.Random(53);
      
      for (int iteration = 0; iteration < 100; iteration++) {
        // Generate random text
        final textLength = 10 + random.nextInt(91);
        final text = _generateRandomText(textLength, random);
        
        // Randomly select an alignment
        final alignment = TextAlignment.values[random.nextInt(TextAlignment.values.length)];
        
        // Create a paragraph node with block metadata
        final attributedText = AttributedText(text);
        final node = ParagraphNode(
          id: 'test-node',
          text: attributedText,
          metadata: {
            'blockMetadata': BlockMetadata(alignment: alignment),
          },
        );
        final document = MutableDocument(nodes: [node]);
        
        // Create selection (collapsed at start)
        final selection = DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: node.id,
            nodePosition: const TextNodePosition(offset: 0),
          ),
        );
        
        // Extract formatting state
        final formattingState = FormattingState.fromSelection(document, selection, {});
        
        // VERIFY: Toolbar state reflects alignment
        expect(
          formattingState.alignment,
          equals(alignment),
          reason: 'Toolbar should show alignment $alignment (iteration $iteration)',
        );
      }
    });
    
    // Feature: rich-text-styling, Property 26: Toolbar reflects selection formatting - combined formatting
    // Validates: Requirements 9.1, 9.2, 9.3, 9.4
    test('Property 26: Toolbar reflects selection formatting - combined inline and block styles', () {
      final random = math.Random(54);
      
      for (int iteration = 0; iteration < 100; iteration++) {
        // Generate random text
        final textLength = 10 + random.nextInt(91);
        final text = _generateRandomText(textLength, random);
        
        // Randomly apply inline styles
        final attributedText = AttributedText(text);
        final node = ParagraphNode(
          id: 'test-node',
          text: attributedText,
        );
        
        final selectionStart = random.nextInt(textLength);
        final selectionEnd = selectionStart + random.nextInt(textLength - selectionStart) + 1;
        
        final applyBold = random.nextBool();
        final applyItalic = random.nextBool();
        final applyUnderline = random.nextBool();
        
        if (applyBold) {
          node.text.addAttribution(
            boldAttribution,
            SpanRange(selectionStart, selectionEnd - 1),
          );
        }
        if (applyItalic) {
          node.text.addAttribution(
            italicsAttribution,
            SpanRange(selectionStart, selectionEnd - 1),
          );
        }
        if (applyUnderline) {
          node.text.addAttribution(
            underlineAttribution,
            SpanRange(selectionStart, selectionEnd - 1),
          );
        }
        
        // Randomly apply block styles
        HeadingLevel? headingLevel;
        ListType? listType;
        TextAlignment? alignment;
        
        final styleChoice = random.nextInt(3);
        if (styleChoice == 0) {
          headingLevel = HeadingLevel.values[random.nextInt(HeadingLevel.values.length)];
        } else if (styleChoice == 1) {
          listType = ListType.values[random.nextInt(ListType.values.length)];
        }
        
        alignment = TextAlignment.values[random.nextInt(TextAlignment.values.length)];
        
        // Update node metadata using the metadata map
        final updatedNode = ParagraphNode(
          id: node.id,
          text: node.text,
          metadata: {
            'blockMetadata': BlockMetadata(
              headingLevel: headingLevel,
              listType: listType,
              alignment: alignment,
            ),
          },
        );
        
        // Replace the node in the document
        final document = MutableDocument(nodes: [updatedNode]);
        
        // Create selection
        final selection = DocumentSelection(
          base: DocumentPosition(
            nodeId: updatedNode.id,
            nodePosition: TextNodePosition(offset: selectionStart),
          ),
          extent: DocumentPosition(
            nodeId: updatedNode.id,
            nodePosition: TextNodePosition(offset: selectionEnd),
          ),
        );
        
        // Extract formatting state
        final formattingState = FormattingState.fromSelection(document, selection, {});
        
        // VERIFY: Toolbar state reflects all applied formatting
        expect(
          formattingState.isBold,
          equals(applyBold),
          reason: 'Toolbar should show bold=$applyBold (iteration $iteration)',
        );
        
        expect(
          formattingState.isItalic,
          equals(applyItalic),
          reason: 'Toolbar should show italic=$applyItalic (iteration $iteration)',
        );
        
        expect(
          formattingState.isUnderline,
          equals(applyUnderline),
          reason: 'Toolbar should show underline=$applyUnderline (iteration $iteration)',
        );
        
        expect(
          formattingState.headingLevel,
          equals(headingLevel),
          reason: 'Toolbar should show heading level $headingLevel (iteration $iteration)',
        );
        
        expect(
          formattingState.listType,
          equals(listType),
          reason: 'Toolbar should show list type $listType (iteration $iteration)',
        );
        
        expect(
          formattingState.alignment,
          equals(alignment),
          reason: 'Toolbar should show alignment $alignment (iteration $iteration)',
        );
        
        expect(
          formattingState.hasSelection,
          isTrue,
          reason: 'Toolbar should indicate selection is present (iteration $iteration)',
        );
      }
    });
    
    // Feature: rich-text-styling, Property 26: Toolbar reflects selection formatting - no selection
    // Validates: Requirements 9.1, 9.2
    test('Property 26: Toolbar reflects selection formatting - null selection shows defaults', () {
      final random = math.Random(55);
      
      for (int iteration = 0; iteration < 100; iteration++) {
        // Generate random text
        final textLength = 10 + random.nextInt(91);
        final text = _generateRandomText(textLength, random);
        
        final attributedText = AttributedText(text);
        final node = ParagraphNode(
          id: 'test-node',
          text: attributedText,
        );
        final document = MutableDocument(nodes: [node]);
        
        // Extract formatting state with null selection
        final formattingState = FormattingState.fromSelection(document, null, {});
        
        // VERIFY: Toolbar state shows defaults when no selection
        expect(
          formattingState.isBold,
          isFalse,
          reason: 'Toolbar should show bold=false with no selection (iteration $iteration)',
        );
        
        expect(
          formattingState.isItalic,
          isFalse,
          reason: 'Toolbar should show italic=false with no selection (iteration $iteration)',
        );
        
        expect(
          formattingState.isUnderline,
          isFalse,
          reason: 'Toolbar should show underline=false with no selection (iteration $iteration)',
        );
        
        expect(
          formattingState.isStrikethrough,
          isFalse,
          reason: 'Toolbar should show strikethrough=false with no selection (iteration $iteration)',
        );
        
        expect(
          formattingState.hasSelection,
          isFalse,
          reason: 'Toolbar should indicate no selection (iteration $iteration)',
        );
        
        expect(
          formattingState.alignment,
          equals(TextAlignment.left),
          reason: 'Toolbar should show default left alignment with no selection (iteration $iteration)',
        );
      }
    });
  });
}

/// Generate random text of specified length
String _generateRandomText(int length, math.Random random) {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,!?';
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ),
  );
}
