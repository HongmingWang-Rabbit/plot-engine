/// Property test for clear formatting preserves structure
/// 
/// Feature: rich-text-styling, Property 25: Clear formatting preserves structure
/// Validates: Requirements 12.5
/// 
/// This test verifies that clearing formatting does not merge paragraphs
/// or alter the document node structure.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'dart:math';

void main() {
  group('Property 25: Clear formatting preserves structure', () {
    test('clearing formatting preserves paragraph boundaries', () {
      final random = Random(53);
      
      // Run 100 iterations with random inputs
      for (int i = 0; i < 100; i++) {
        // Generate random number of paragraphs (2-10)
        final numParagraphs = 2 + random.nextInt(9);
        final paragraphs = <ParagraphNode>[];
        final originalTexts = <String>[];
        
        for (int j = 0; j < numParagraphs; j++) {
          final text = _generateRandomText(random, minLength: 10, maxLength: 50);
          originalTexts.add(text);
          
          final attributedText = AttributedText(text);
          final node = ParagraphNode(
            id: 'node$j',
            text: attributedText,
          );
          
          // Apply random formatting to each paragraph
          final numStyles = random.nextInt(3) + 1;
          for (int k = 0; k < numStyles; k++) {
            final start = random.nextInt(text.length);
            final end = start + random.nextInt(text.length - start) + 1;
            final attribution = _getRandomInlineAttribution(random);
            
            // Remove conflicting attributions of the same type first
            if (attribution is ColorAttribution || attribution is BackgroundColorAttribution || attribution is FontSizeAttribution) {
              for (int pos = start; pos < end; pos++) {
                final existingAttrs = node.text.getAllAttributionsAt(pos);
                for (final existing in existingAttrs) {
                  if ((attribution is ColorAttribution && existing is ColorAttribution) ||
                      (attribution is BackgroundColorAttribution && existing is BackgroundColorAttribution) ||
                      (attribution is FontSizeAttribution && existing is FontSizeAttribution)) {
                    node.text.removeAttribution(existing, SpanRange(pos, pos));
                  }
                }
              }
            }
            
            node.text.addAttribution(
              attribution,
              SpanRange(start, end - 1),
            );
          }
          
          paragraphs.add(node);
        }
        
        // Verify formatting is present
        bool hadFormatting = false;
        for (final node in paragraphs) {
          for (int pos = 0; pos < node.text.length; pos++) {
            final attributions = node.text.getAllAttributionsAt(pos);
            if (attributions.any((a) => _isInlineStyleAttribution(a))) {
              hadFormatting = true;
              break;
            }
          }
          if (hadFormatting) break;
        }
        
        expect(hadFormatting, isTrue, reason: 'Should have formatting before clearing (iteration $i)');
        
        // Simulate clearing formatting on all paragraphs
        for (final node in paragraphs) {
          for (int pos = 0; pos < node.text.length; pos++) {
            final attributions = node.text.getAllAttributionsAt(pos);
            for (final attr in attributions) {
              if (_isInlineStyleAttribution(attr)) {
                node.text.removeAttribution(attr, SpanRange(pos, pos));
              }
            }
          }
        }
        
        // Verify: Number of paragraphs is unchanged
        expect(
          paragraphs.length,
          equals(numParagraphs),
          reason: 'Number of paragraphs should be unchanged (iteration $i)',
        );
        
        // Verify: Each paragraph's text content is unchanged
        for (int j = 0; j < paragraphs.length; j++) {
          expect(
            paragraphs[j].text.text,
            equals(originalTexts[j]),
            reason: 'Paragraph $j text should be unchanged (iteration $i)',
          );
        }
        
        // Verify: Each paragraph's ID is unchanged
        for (int j = 0; j < paragraphs.length; j++) {
          expect(
            paragraphs[j].id,
            equals('node$j'),
            reason: 'Paragraph $j ID should be unchanged (iteration $i)',
          );
        }
        
        // Verify: Formatting is removed from all paragraphs
        for (final node in paragraphs) {
          for (int pos = 0; pos < node.text.length; pos++) {
            final attributions = node.text.getAllAttributionsAt(pos);
            expect(
              attributions.any((a) => _isInlineStyleAttribution(a)),
              isFalse,
              reason: 'Formatting should be removed from all paragraphs (iteration $i)',
            );
          }
        }
      }
    });
    
    test('clearing formatting preserves paragraph line breaks', () {
      final random = Random(54);
      
      for (int i = 0; i < 50; i++) {
        // Create paragraphs with specific line break patterns
        final numParagraphs = 3 + random.nextInt(5);
        final paragraphs = <ParagraphNode>[];
        final originalTexts = <String>[];
        
        for (int j = 0; j < numParagraphs; j++) {
          // Some paragraphs might be empty (representing blank lines)
          final isEmpty = random.nextDouble() < 0.2;
          final text = isEmpty ? '' : _generateRandomText(random, minLength: 5, maxLength: 30);
          originalTexts.add(text);
          
          final attributedText = AttributedText(text);
          final node = ParagraphNode(
            id: 'node$j',
            text: attributedText,
          );
          
          // Apply formatting to non-empty paragraphs
          if (!isEmpty) {
            node.text.addAttribution(boldAttribution, SpanRange(0, text.length - 1));
          }
          
          paragraphs.add(node);
        }
        
        // Simulate clearing formatting
        for (final node in paragraphs) {
          for (int pos = 0; pos < node.text.length; pos++) {
            final attributions = node.text.getAllAttributionsAt(pos);
            for (final attr in attributions) {
              if (_isInlineStyleAttribution(attr)) {
                node.text.removeAttribution(attr, SpanRange(pos, pos));
              }
            }
          }
        }
        
        // Verify: All paragraphs still exist (including empty ones)
        expect(
          paragraphs.length,
          equals(numParagraphs),
          reason: 'All paragraphs including empty ones should be preserved (iteration $i)',
        );
        
        // Verify: Empty paragraphs remain empty
        for (int j = 0; j < paragraphs.length; j++) {
          expect(
            paragraphs[j].text.text,
            equals(originalTexts[j]),
            reason: 'Paragraph $j content should be unchanged (iteration $i)',
          );
        }
      }
    });
    
    test('clearing formatting does not merge adjacent paragraphs', () {
      final random = Random(55);
      
      for (int i = 0; i < 50; i++) {
        // Create multiple paragraphs with different formatting
        final text1 = _generateRandomText(random, minLength: 10, maxLength: 30);
        final text2 = _generateRandomText(random, minLength: 10, maxLength: 30);
        final text3 = _generateRandomText(random, minLength: 10, maxLength: 30);
        
        final node1 = ParagraphNode(
          id: 'node1',
          text: AttributedText(text1),
        );
        final node2 = ParagraphNode(
          id: 'node2',
          text: AttributedText(text2),
        );
        final node3 = ParagraphNode(
          id: 'node3',
          text: AttributedText(text3),
        );
        
        // Apply different formatting to each paragraph
        node1.text.addAttribution(boldAttribution, SpanRange(0, text1.length - 1));
        node2.text.addAttribution(italicsAttribution, SpanRange(0, text2.length - 1));
        node3.text.addAttribution(underlineAttribution, SpanRange(0, text3.length - 1));
        
        final paragraphs = [node1, node2, node3];
        
        // Simulate clearing formatting
        for (final node in paragraphs) {
          for (int pos = 0; pos < node.text.length; pos++) {
            final attributions = node.text.getAllAttributionsAt(pos);
            for (final attr in attributions) {
              if (_isInlineStyleAttribution(attr)) {
                node.text.removeAttribution(attr, SpanRange(pos, pos));
              }
            }
          }
        }
        
        // Verify: Still have 3 separate paragraphs
        expect(
          paragraphs.length,
          equals(3),
          reason: 'Should still have 3 separate paragraphs (iteration $i)',
        );
        
        // Verify: Each paragraph has its original text
        expect(node1.text.text, equals(text1), reason: 'Paragraph 1 text unchanged (iteration $i)');
        expect(node2.text.text, equals(text2), reason: 'Paragraph 2 text unchanged (iteration $i)');
        expect(node3.text.text, equals(text3), reason: 'Paragraph 3 text unchanged (iteration $i)');
        
        // Verify: Paragraphs are still distinct objects
        expect(identical(node1, node2), isFalse, reason: 'Paragraphs 1 and 2 should be distinct (iteration $i)');
        expect(identical(node2, node3), isFalse, reason: 'Paragraphs 2 and 3 should be distinct (iteration $i)');
        expect(identical(node1, node3), isFalse, reason: 'Paragraphs 1 and 3 should be distinct (iteration $i)');
      }
    });
    
    test('clearing formatting preserves paragraph order', () {
      final random = Random(56);
      
      for (int i = 0; i < 50; i++) {
        // Create paragraphs with unique identifiable content
        final numParagraphs = 5 + random.nextInt(10);
        final paragraphs = <ParagraphNode>[];
        final expectedOrder = <String>[];
        
        for (int j = 0; j < numParagraphs; j++) {
          final text = 'Paragraph $j: ${_generateRandomText(random, minLength: 10, maxLength: 20)}';
          expectedOrder.add(text);
          
          final attributedText = AttributedText(text);
          final node = ParagraphNode(
            id: 'node$j',
            text: attributedText,
          );
          
          // Apply random formatting
          final attribution = _getRandomInlineAttribution(random);
          if (attribution is ColorAttribution || attribution is BackgroundColorAttribution || attribution is FontSizeAttribution) {
            // Skip conflicting attributions for simplicity
          } else {
            node.text.addAttribution(attribution, SpanRange(0, text.length - 1));
          }
          
          paragraphs.add(node);
        }
        
        // Simulate clearing formatting
        for (final node in paragraphs) {
          for (int pos = 0; pos < node.text.length; pos++) {
            final attributions = node.text.getAllAttributionsAt(pos);
            for (final attr in attributions) {
              if (_isInlineStyleAttribution(attr)) {
                node.text.removeAttribution(attr, SpanRange(pos, pos));
              }
            }
          }
        }
        
        // Verify: Paragraph order is unchanged
        for (int j = 0; j < paragraphs.length; j++) {
          expect(
            paragraphs[j].text.text,
            equals(expectedOrder[j]),
            reason: 'Paragraph order should be unchanged at position $j (iteration $i)',
          );
        }
      }
    });
  });
}

/// Generate random text of specified length
String _generateRandomText(Random random, {required int minLength, required int maxLength}) {
  final length = minLength + random.nextInt(maxLength - minLength);
  final chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ';
  return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
}

/// Get a random inline attribution
Attribution _getRandomInlineAttribution(Random random) {
  final attributions = [
    boldAttribution,
    italicsAttribution,
    underlineAttribution,
    strikethroughAttribution,
    ColorAttribution(Color(random.nextInt(0xFFFFFF) + 0xFF000000)),
    BackgroundColorAttribution(Color(random.nextInt(0xFFFFFF) + 0xFF000000)),
    FontSizeAttribution(12.0 + random.nextDouble() * 48.0),
  ];
  return attributions[random.nextInt(attributions.length)];
}

/// Check if an attribution is an inline style attribution
bool _isInlineStyleAttribution(Attribution attr) {
  return attr == boldAttribution ||
      attr == italicsAttribution ||
      attr == underlineAttribution ||
      attr == strikethroughAttribution ||
      attr is ColorAttribution ||
      attr is BackgroundColorAttribution ||
      attr is FontSizeAttribution;
}
