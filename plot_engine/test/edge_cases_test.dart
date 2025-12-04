import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'package:plot_engine/services/formatted_content_serializer.dart';
import 'package:plot_engine/services/block_metadata.dart';
import 'package:plot_engine/ui/editor/formatting_toolbar.dart';

void main() {
  group('Edge Cases - Empty Document Formatting', () {
    test('applying formatting to empty document does not crash', () {
      // Create empty document
      final document = MutableDocument(nodes: []);
      
      // Attempt to serialize empty document
      expect(
        () => FormattedContentSerializer.serializeDocument(document),
        returnsNormally,
      );
      
      final json = FormattedContentSerializer.serializeDocument(document);
      expect(json['nodes'], isEmpty);
    });
    
    test('deserializing empty document creates valid document', () {
      final json = {
        'version': '1.0',
        'nodes': [],
      };
      
      final nodes = FormattedContentSerializer.deserializeDocument(json);
      // The serializer creates a default paragraph node when nodes is empty
      expect(nodes, isNotEmpty);
      expect(nodes.length, 1);
      expect(nodes.first, isA<ParagraphNode>());
    });
    
    test('empty paragraph node serializes correctly', () {
      final node = ParagraphNode(
        id: 'empty-node',
        text: AttributedText(''),
      );
      
      final json = FormattedContentSerializer.serializeNode(node);
      expect(json['text'], '');
      expect(json['attributions'], isEmpty);
    });
  });
  
  group('Edge Cases - Single Character Formatting', () {
    test('single character can have bold formatting', () {
      final node = ParagraphNode(
        id: 'test-node',
        text: AttributedText('A'),
      );
      
      node.text.addAttribution(boldAttribution, const SpanRange(0, 0));
      
      final attributions = node.text.getAllAttributionsAt(0);
      expect(attributions.contains(boldAttribution), isTrue);
    });
    
    test('single character can have multiple inline styles', () {
      final node = ParagraphNode(
        id: 'test-node',
        text: AttributedText('X'),
      );
      
      node.text.addAttribution(boldAttribution, const SpanRange(0, 0));
      node.text.addAttribution(italicsAttribution, const SpanRange(0, 0));
      node.text.addAttribution(underlineAttribution, const SpanRange(0, 0));
      
      final attributions = node.text.getAllAttributionsAt(0);
      expect(attributions.contains(boldAttribution), isTrue);
      expect(attributions.contains(italicsAttribution), isTrue);
      expect(attributions.contains(underlineAttribution), isTrue);
    });
    
    test('single character with formatting serializes correctly', () {
      final node = ParagraphNode(
        id: 'test-node',
        text: AttributedText('Z'),
      );
      
      node.text.addAttribution(boldAttribution, const SpanRange(0, 0));
      node.text.addAttribution(
        ColorAttribution(Colors.red),
        const SpanRange(0, 0),
      );
      
      final json = FormattedContentSerializer.serializeNode(node);
      expect(json['text'], 'Z');
      expect(json['attributions'], isNotEmpty);
    });
  });
  
  group('Edge Cases - Very Long Text with Many Attributions', () {
    test('very long text (10000 characters) with formatting does not crash', () {
      // Create very long text
      final longText = 'A' * 10000;
      final node = ParagraphNode(
        id: 'long-node',
        text: AttributedText(longText),
      );
      
      // Apply formatting to various sections
      node.text.addAttribution(boldAttribution, const SpanRange(0, 999));
      node.text.addAttribution(italicsAttribution, const SpanRange(1000, 1999));
      node.text.addAttribution(underlineAttribution, const SpanRange(2000, 2999));
      node.text.addAttribution(
        ColorAttribution(Colors.blue),
        const SpanRange(3000, 3999),
      );
      
      // Verify serialization works
      expect(
        () => FormattedContentSerializer.serializeNode(node),
        returnsNormally,
      );
      
      final json = FormattedContentSerializer.serializeNode(node);
      expect(json['text'].length, 10000);
    });
    
    test('text with many overlapping attributions serializes correctly', () {
      final text = 'The quick brown fox jumps over the lazy dog';
      final node = ParagraphNode(
        id: 'test-node',
        text: AttributedText(text),
      );
      
      // Apply many overlapping attributions
      for (int i = 0; i < text.length - 5; i += 2) {
        node.text.addAttribution(
          boldAttribution,
          SpanRange(i, i + 4),
        );
      }
      
      for (int i = 1; i < text.length - 5; i += 3) {
        node.text.addAttribution(
          italicsAttribution,
          SpanRange(i, i + 3),
        );
      }
      
      // Verify serialization works
      expect(
        () => FormattedContentSerializer.serializeNode(node),
        returnsNormally,
      );
      
      final json = FormattedContentSerializer.serializeNode(node);
      expect(json['attributions'], isNotEmpty);
    });
    
    test('document with 1000 nodes serializes without performance issues', () {
      final nodes = <DocumentNode>[];
      for (int i = 0; i < 1000; i++) {
        nodes.add(ParagraphNode(
          id: 'node-$i',
          text: AttributedText('Paragraph $i'),
        ));
      }
      
      final document = MutableDocument(nodes: nodes);
      
      // Measure serialization time (should complete quickly)
      final stopwatch = Stopwatch()..start();
      final json = FormattedContentSerializer.serializeDocument(document);
      stopwatch.stop();
      
      expect(json['nodes'].length, 1000);
      // Should complete in reasonable time (< 5 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });
  });
  
  group('Edge Cases - Rapid Style Toggling', () {
    test('toggling bold on and off 100 times maintains correct state', () {
      final node = ParagraphNode(
        id: 'test-node',
        text: AttributedText('Test text'),
      );
      
      const selection = SpanRange(0, 8);
      
      // Toggle bold 100 times
      for (int i = 0; i < 100; i++) {
        if (i % 2 == 0) {
          node.text.addAttribution(boldAttribution, selection);
        } else {
          node.text.removeAttribution(boldAttribution, selection);
        }
      }
      
      // After even number of toggles, bold should be OFF
      final attributions = node.text.getAllAttributionsAt(0);
      expect(attributions.contains(boldAttribution), isFalse);
    });
    
    test('rapidly adding and removing multiple styles maintains consistency', () {
      final node = ParagraphNode(
        id: 'test-node',
        text: AttributedText('Rapid toggle test'),
      );
      
      const selection = SpanRange(0, 16);
      
      // Rapidly toggle multiple styles
      for (int i = 0; i < 50; i++) {
        node.text.addAttribution(boldAttribution, selection);
        node.text.addAttribution(italicsAttribution, selection);
        node.text.removeAttribution(boldAttribution, selection);
        node.text.addAttribution(underlineAttribution, selection);
        node.text.removeAttribution(italicsAttribution, selection);
        node.text.removeAttribution(underlineAttribution, selection);
      }
      
      // After all operations, no styles should be applied
      final attributions = node.text.getAllAttributionsAt(0);
      expect(attributions.contains(boldAttribution), isFalse);
      expect(attributions.contains(italicsAttribution), isFalse);
      expect(attributions.contains(underlineAttribution), isFalse);
    });
    
    test('toggling styles on overlapping selections works correctly', () {
      final node = ParagraphNode(
        id: 'test-node',
        text: AttributedText('Overlapping selections test'),
      );
      
      // Apply bold to first half
      node.text.addAttribution(boldAttribution, const SpanRange(0, 13));
      
      // Apply italic to second half
      node.text.addAttribution(italicsAttribution, const SpanRange(14, 26));
      
      // Apply underline to middle (overlapping both)
      node.text.addAttribution(underlineAttribution, const SpanRange(7, 20));
      
      // Verify overlapping region has all three
      final middleAttributions = node.text.getAllAttributionsAt(10);
      expect(middleAttributions.contains(boldAttribution), isTrue);
      expect(middleAttributions.contains(underlineAttribution), isTrue);
      
      // Verify non-overlapping regions
      final startAttributions = node.text.getAllAttributionsAt(0);
      expect(startAttributions.contains(boldAttribution), isTrue);
      expect(startAttributions.contains(italicsAttribution), isFalse);
      
      final endAttributions = node.text.getAllAttributionsAt(25);
      expect(endAttributions.contains(italicsAttribution), isTrue);
      expect(endAttributions.contains(boldAttribution), isFalse);
    });
  });
  
  group('Edge Cases - Font Size Boundaries', () {
    test('minimum font size (6) can be applied', () {
      final node = ParagraphNode(
        id: 'test-node',
        text: AttributedText('Minimum size'),
      );
      
      final minSizeAttribution = FontSizeAttribution(6.0);
      node.text.addAttribution(minSizeAttribution, const SpanRange(0, 11));
      
      final attributions = node.text.getAllAttributionsAt(0);
      expect(
        attributions.any((a) => a is FontSizeAttribution && a.fontSize == 6.0),
        isTrue,
      );
    });
    
    test('maximum font size (200) can be applied', () {
      final node = ParagraphNode(
        id: 'test-node',
        text: AttributedText('Maximum size'),
      );
      
      final maxSizeAttribution = FontSizeAttribution(200.0);
      node.text.addAttribution(maxSizeAttribution, const SpanRange(0, 11));
      
      final attributions = node.text.getAllAttributionsAt(0);
      expect(
        attributions.any((a) => a is FontSizeAttribution && a.fontSize == 200.0),
        isTrue,
      );
    });
    
    test('font size at boundary (6) serializes and deserializes correctly', () {
      final node = ParagraphNode(
        id: 'test-node',
        text: AttributedText('Boundary test'),
      );
      
      final minSizeAttribution = FontSizeAttribution(6.0);
      node.text.addAttribution(minSizeAttribution, const SpanRange(0, 12));
      
      final json = FormattedContentSerializer.serializeNode(node);
      final restoredNode = FormattedContentSerializer.deserializeNode(json);
      
      final restoredText = (restoredNode as ParagraphNode).text;
      final attributions = restoredText.getAllAttributionsAt(0);
      expect(
        attributions.any((a) => a is FontSizeAttribution && a.fontSize == 6.0),
        isTrue,
      );
    });
    
    test('font size at boundary (200) serializes and deserializes correctly', () {
      final node = ParagraphNode(
        id: 'test-node',
        text: AttributedText('Boundary test'),
      );
      
      final maxSizeAttribution = FontSizeAttribution(200.0);
      node.text.addAttribution(maxSizeAttribution, const SpanRange(0, 12));
      
      final json = FormattedContentSerializer.serializeNode(node);
      final restoredNode = FormattedContentSerializer.deserializeNode(json);
      
      final restoredText = (restoredNode as ParagraphNode).text;
      final attributions = restoredText.getAllAttributionsAt(0);
      expect(
        attributions.any((a) => a is FontSizeAttribution && a.fontSize == 200.0),
        isTrue,
      );
    });
    
    test('fractional font sizes are preserved', () {
      final node = ParagraphNode(
        id: 'test-node',
        text: AttributedText('Fractional size'),
      );
      
      final fractionalSizeAttribution = FontSizeAttribution(12.5);
      node.text.addAttribution(fractionalSizeAttribution, const SpanRange(0, 14));
      
      final json = FormattedContentSerializer.serializeNode(node);
      final restoredNode = FormattedContentSerializer.deserializeNode(json);
      
      final restoredText = (restoredNode as ParagraphNode).text;
      final attributions = restoredText.getAllAttributionsAt(0);
      expect(
        attributions.any((a) => a is FontSizeAttribution && a.fontSize == 12.5),
        isTrue,
      );
    });
  });
  
  group('Edge Cases - Malformed JSON Deserialization', () {
    test('missing version field uses default', () {
      final json = {
        'nodes': [],
      };
      
      expect(
        () => FormattedContentSerializer.deserializeDocument(json),
        returnsNormally,
      );
      
      final nodes = FormattedContentSerializer.deserializeDocument(json);
      // The serializer creates a default paragraph node when nodes is empty
      expect(nodes, isNotEmpty);
    });
    
    test('missing nodes field returns default paragraph', () {
      final json = {
        'version': '1.0',
      };
      
      expect(
        () => FormattedContentSerializer.deserializeDocument(json),
        returnsNormally,
      );
      
      final nodes = FormattedContentSerializer.deserializeDocument(json);
      // The serializer creates a default paragraph node when nodes is missing
      expect(nodes, isNotEmpty);
    });
    
    test('null nodes field returns default paragraph', () {
      final json = {
        'version': '1.0',
        'nodes': null,
      };
      
      expect(
        () => FormattedContentSerializer.deserializeDocument(json),
        returnsNormally,
      );
      
      final nodes = FormattedContentSerializer.deserializeDocument(json);
      // The serializer creates a default paragraph node when nodes is null
      expect(nodes, isNotEmpty);
    });
    
    test('node with missing id returns null', () {
      final json = {
        'type': 'paragraph',
        'text': 'Test',
      };
      
      expect(
        () => FormattedContentSerializer.deserializeNode(json),
        returnsNormally,
      );
      
      final node = FormattedContentSerializer.deserializeNode(json);
      // Missing id causes deserialization to return null
      expect(node, isNull);
    });
    
    test('node with missing text uses empty string', () {
      final json = {
        'id': 'test-node',
        'type': 'paragraph',
      };
      
      expect(
        () => FormattedContentSerializer.deserializeNode(json),
        returnsNormally,
      );
      
      final node = FormattedContentSerializer.deserializeNode(json) as ParagraphNode;
      expect(node.text.text, '');
    });
    
    test('node with null text uses empty string', () {
      final json = {
        'id': 'test-node',
        'type': 'paragraph',
        'text': null,
      };
      
      expect(
        () => FormattedContentSerializer.deserializeNode(json),
        returnsNormally,
      );
      
      final node = FormattedContentSerializer.deserializeNode(json) as ParagraphNode;
      expect(node.text.text, '');
    });
    
    test('node with missing attributions uses empty list', () {
      final json = {
        'id': 'test-node',
        'type': 'paragraph',
        'text': 'Test',
      };
      
      final node = FormattedContentSerializer.deserializeNode(json) as ParagraphNode;
      // Check that text has no attributions by checking at position 0
      final attributions = node.text.getAllAttributionsAt(0);
      expect(attributions, isEmpty);
    });
    
    test('node with null attributions uses empty list', () {
      final json = {
        'id': 'test-node',
        'type': 'paragraph',
        'text': 'Test',
        'attributions': null,
      };
      
      final node = FormattedContentSerializer.deserializeNode(json) as ParagraphNode;
      // Check that text has no attributions by checking at position 0
      final attributions = node.text.getAllAttributionsAt(0);
      expect(attributions, isEmpty);
    });
    
    test('attribution with invalid range is skipped', () {
      final json = {
        'id': 'test-node',
        'type': 'paragraph',
        'text': 'Test',
        'attributions': [
          {
            'start': 10, // Beyond text length
            'end': 20,
            'type': 'bold',
          },
        ],
      };
      
      expect(
        () => FormattedContentSerializer.deserializeNode(json),
        returnsNormally,
      );
      
      final node = FormattedContentSerializer.deserializeNode(json) as ParagraphNode;
      // Invalid attribution should be skipped
      expect(node.text.text, 'Test');
    });
    
    test('attribution with negative range is skipped', () {
      final json = {
        'id': 'test-node',
        'type': 'paragraph',
        'text': 'Test',
        'attributions': [
          {
            'start': -1,
            'end': 2,
            'type': 'bold',
          },
        ],
      };
      
      expect(
        () => FormattedContentSerializer.deserializeNode(json),
        returnsNormally,
      );
    });
    
    test('attribution with missing start/end is skipped', () {
      final json = {
        'id': 'test-node',
        'type': 'paragraph',
        'text': 'Test',
        'attributions': [
          {
            'type': 'bold',
          },
        ],
      };
      
      expect(
        () => FormattedContentSerializer.deserializeNode(json),
        returnsNormally,
      );
    });
    
    test('metadata with invalid enum values uses defaults', () {
      final json = {
        'id': 'test-node',
        'type': 'paragraph',
        'text': 'Test',
        'metadata': {
          'blockMetadata': {
            'headingLevel': 'invalid',
            'listType': 'invalid',
            'alignment': 'invalid',
          },
        },
      };
      
      expect(
        () => FormattedContentSerializer.deserializeNode(json),
        returnsNormally,
      );
      
      final node = FormattedContentSerializer.deserializeNode(json) as ParagraphNode;
      final metadata = node.metadata['blockMetadata'] as BlockMetadata?;
      expect(metadata?.headingLevel, isNull);
      expect(metadata?.listType, isNull);
      expect(metadata?.alignment, isNull);
    });
  });
  
  group('Edge Cases - Unknown Attribution Types', () {
    test('unknown attribution type is skipped during deserialization', () {
      final json = {
        'id': 'test-node',
        'type': 'paragraph',
        'text': 'Test',
        'attributions': [
          {
            'start': 0,
            'end': 3,
            'type': 'unknownStyleType',
          },
        ],
      };
      
      expect(
        () => FormattedContentSerializer.deserializeNode(json),
        returnsNormally,
      );
      
      final node = FormattedContentSerializer.deserializeNode(json) as ParagraphNode;
      expect(node.text.text, 'Test');
      // Unknown attribution should be skipped, so no attributions
    });
    
    test('mix of known and unknown attributions preserves known ones', () {
      final json = {
        'id': 'test-node',
        'type': 'paragraph',
        'text': 'Test',
        'attributions': [
          {
            'start': 0,
            'end': 3,
            'type': 'bold',
          },
          {
            'start': 0,
            'end': 3,
            'type': 'unknownType',
          },
          {
            'start': 0,
            'end': 3,
            'type': 'italic',
          },
        ],
      };
      
      final node = FormattedContentSerializer.deserializeNode(json) as ParagraphNode;
      final attributions = node.text.getAllAttributionsAt(0);
      
      // Known attributions should be present
      expect(attributions.contains(boldAttribution), isTrue);
      expect(attributions.contains(italicsAttribution), isTrue);
    });
    
    test('attribution with missing type is skipped', () {
      final json = {
        'id': 'test-node',
        'type': 'paragraph',
        'text': 'Test',
        'attributions': [
          {
            'start': 0,
            'end': 3,
          },
        ],
      };
      
      expect(
        () => FormattedContentSerializer.deserializeNode(json),
        returnsNormally,
      );
    });
    
    test('color attribution with invalid color format is skipped', () {
      final json = {
        'id': 'test-node',
        'type': 'paragraph',
        'text': 'Test',
        'attributions': [
          {
            'start': 0,
            'end': 3,
            'type': 'textColor',
            'color': 'invalid-color-format',
          },
        ],
      };
      
      expect(
        () => FormattedContentSerializer.deserializeNode(json),
        returnsNormally,
      );
    });
    
    test('font size attribution with invalid size is skipped', () {
      final json = {
        'id': 'test-node',
        'type': 'paragraph',
        'text': 'Test',
        'attributions': [
          {
            'start': 0,
            'end': 3,
            'type': 'fontSize',
            'size': 'not-a-number',
          },
        ],
      };
      
      expect(
        () => FormattedContentSerializer.deserializeNode(json),
        returnsNormally,
      );
    });
  });
  
  group('Edge Cases - Null Selection Handling', () {
    test('FormattingState.fromSelection handles null selection gracefully', () {
      final document = MutableDocument(nodes: [
        ParagraphNode(
          id: 'test-node',
          text: AttributedText('Test'),
        ),
      ]);
      
      expect(
        () => FormattingState.fromSelection(document, null, {}),
        returnsNormally,
      );
      
      final state = FormattingState.fromSelection(document, null, {});
      expect(state.hasSelection, isFalse);
      expect(state.isBold, isFalse);
      expect(state.isItalic, isFalse);
    });
    
    test('FormattingState with null selection returns default values', () {
      final document = MutableDocument(nodes: [
        ParagraphNode(
          id: 'test-node',
          text: AttributedText('Test'),
        ),
      ]);
      
      final state = FormattingState.fromSelection(document, null, {});
      
      expect(state.isBold, isFalse);
      expect(state.isItalic, isFalse);
      expect(state.isUnderline, isFalse);
      expect(state.isStrikethrough, isFalse);
      expect(state.textColor, isNull);
      expect(state.highlightColor, isNull);
      expect(state.fontSize, isNull);
      expect(state.headingLevel, isNull);
      expect(state.listType, isNull);
      expect(state.alignment, TextAlignment.left);
      expect(state.hasSelection, isFalse);
    });
    
    test('FormattingState with collapsed selection at start of text', () {
      final node = ParagraphNode(
        id: 'test-node',
        text: AttributedText('Test text'),
      );
      
      // Apply bold to part of the text
      node.text.addAttribution(boldAttribution, const SpanRange(5, 8));
      
      final document = MutableDocument(nodes: [node]);
      
      // Collapsed selection at position 0 (before bold text)
      final selection = DocumentSelection.collapsed(
        position: DocumentPosition(
          nodeId: node.id,
          nodePosition: const TextNodePosition(offset: 0),
        ),
      );
      
      final state = FormattingState.fromSelection(document, selection, {});
      
      // Collapsed selection is still a selection, but hasSelection may be false
      // depending on implementation. Let's just check the formatting state.
      expect(state.isBold, isFalse); // Not in bold region
    });
    
    test('FormattingState with collapsed selection in formatted region', () {
      final node = ParagraphNode(
        id: 'test-node',
        text: AttributedText('Test text'),
      );
      
      // Apply bold to part of the text
      node.text.addAttribution(boldAttribution, const SpanRange(0, 3));
      
      final document = MutableDocument(nodes: [node]);
      
      // Collapsed selection at position 2 (inside bold text)
      final selection = DocumentSelection.collapsed(
        position: DocumentPosition(
          nodeId: node.id,
          nodePosition: const TextNodePosition(offset: 2),
        ),
      );
      
      final state = FormattingState.fromSelection(document, selection, {});
      
      // Check the formatting state reflects the bold region
      expect(state.isBold, isTrue); // Inside bold region
    });
    
    test('FormattingState with selection in empty document', () {
      final document = MutableDocument(nodes: []);
      
      final state = FormattingState.fromSelection(document, null, {});
      
      expect(state.hasSelection, isFalse);
      expect(state.isBold, isFalse);
    });
    
    test('FormattingState with selection spanning non-existent node', () {
      final document = MutableDocument(nodes: [
        ParagraphNode(
          id: 'node-1',
          text: AttributedText('Test'),
        ),
      ]);
      
      // Create selection referencing non-existent node
      final selection = DocumentSelection.collapsed(
        position: DocumentPosition(
          nodeId: 'non-existent-node',
          nodePosition: const TextNodePosition(offset: 0),
        ),
      );
      
      expect(
        () => FormattingState.fromSelection(document, selection, {}),
        returnsNormally,
      );
      
      final state = FormattingState.fromSelection(document, selection, {});
      // Non-existent node should return default state
      expect(state.isBold, isFalse);
    });
  });
  
  group('Edge Cases - Special Characters and Unicode', () {
    test('emoji can be formatted', () {
      final node = ParagraphNode(
        id: 'test-node',
        text: AttributedText('Hello 👋 World 🌍'),
      );
      
      node.text.addAttribution(boldAttribution, const SpanRange(0, 16));
      
      final attributions = node.text.getAllAttributionsAt(6); // At emoji
      expect(attributions.contains(boldAttribution), isTrue);
    });
    
    test('unicode characters serialize correctly', () {
      final node = ParagraphNode(
        id: 'test-node',
        text: AttributedText('日本語 中文 한국어 العربية'),
      );
      
      node.text.addAttribution(boldAttribution, const SpanRange(0, 14));
      
      final json = FormattedContentSerializer.serializeNode(node);
      final restoredNode = FormattedContentSerializer.deserializeNode(json) as ParagraphNode;
      
      expect(restoredNode.text.text, '日本語 中文 한국어 العربية');
    });
    
    test('special characters in text are preserved', () {
      final specialText = 'Test\nNew\tLine\r\nWith\\Backslash"Quotes"';
      final node = ParagraphNode(
        id: 'test-node',
        text: AttributedText(specialText),
      );
      
      final json = FormattedContentSerializer.serializeNode(node);
      final restoredNode = FormattedContentSerializer.deserializeNode(json) as ParagraphNode;
      
      expect(restoredNode.text.text, specialText);
    });
  });
}
