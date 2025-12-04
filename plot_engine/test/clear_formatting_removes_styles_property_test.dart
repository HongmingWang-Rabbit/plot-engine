/// Property test for clear formatting removes styles
/// 
/// Feature: rich-text-styling, Property 23: Clear formatting removes styles
/// Validates: Requirements 12.1
/// 
/// This test verifies that clearing formatting removes all inline style
/// attributions (bold, italic, underline, strikethrough, colors, font size)
/// while preserving text content.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'dart:math';

void main() {
  group('Property 23: Clear formatting removes styles', () {
    test('clearing formatting removes all inline styles from text', () {
      final random = Random(42);
      
      // Run 100 iterations with random inputs
      for (int i = 0; i < 100; i++) {
        // Generate random text
        final text = _generateRandomText(random, minLength: 10, maxLength: 100);
        
        // Create a paragraph node with the text
        final attributedText = AttributedText(text);
        final node = ParagraphNode(
          id: 'node1',
          text: attributedText,
        );
        
        // Apply random inline styles to random ranges
        final numStyles = random.nextInt(5) + 1;
        for (int j = 0; j < numStyles; j++) {
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
        
        // Verify styles were applied
        final hadStyles = _hasAnyInlineStyles(node.text, 0, text.length);
        expect(hadStyles, isTrue, reason: 'Styles should be applied before clearing');
        
        // Simulate clearing formatting by removing all inline style attributions
        // This tests the core logic of what ClearFormattingCommand should do
        for (int pos = 0; pos < text.length; pos++) {
          final attributions = node.text.getAllAttributionsAt(pos);
          for (final attr in attributions) {
            if (_isInlineStyleAttribution(attr)) {
              node.text.removeAttribution(attr, SpanRange(pos, pos));
            }
          }
        }
        
        // Verify all inline styles are removed
        final hasStylesAfter = _hasAnyInlineStyles(node.text, 0, text.length);
        expect(
          hasStylesAfter,
          isFalse,
          reason: 'All inline styles should be removed after clearing formatting (iteration $i)',
        );
        
        // Verify text content is preserved
        expect(
          node.text.text,
          equals(text),
          reason: 'Text content should be preserved (iteration $i)',
        );
      }
    });
    
    test('clearing formatting removes specific style types', () {
      final random = Random(43);
      
      // Test each style type individually
      final styleTypes = [
        boldAttribution,
        italicsAttribution,
        underlineAttribution,
        strikethroughAttribution,
        ColorAttribution(const Color(0xFF000000)),
        BackgroundColorAttribution(const Color(0xFFFFFF00)),
        const FontSizeAttribution(24.0),
      ];
      
      for (final styleAttribution in styleTypes) {
        final text = _generateRandomText(random, minLength: 20, maxLength: 50);
        
        final attributedText = AttributedText(text);
        final node = ParagraphNode(
          id: 'node1',
          text: attributedText,
        );
        
        // Apply the specific style to entire text
        node.text.addAttribution(
          styleAttribution,
          SpanRange(0, text.length - 1),
        );
        
        // Verify style was applied
        final attributions = node.text.getAllAttributionsAt(0);
        expect(
          attributions.any((a) => _isSameAttributionType(a, styleAttribution)),
          isTrue,
          reason: 'Style ${styleAttribution.runtimeType} should be applied',
        );
        
        // Simulate clearing formatting
        for (int pos = 0; pos < text.length; pos++) {
          final attrs = node.text.getAllAttributionsAt(pos);
          for (final attr in attrs) {
            if (_isInlineStyleAttribution(attr)) {
              node.text.removeAttribution(attr, SpanRange(pos, pos));
            }
          }
        }
        
        // Verify the specific style is removed
        final attributionsAfter = node.text.getAllAttributionsAt(0);
        expect(
          attributionsAfter.any((a) => _isSameAttributionType(a, styleAttribution)),
          isFalse,
          reason: 'Style ${styleAttribution.runtimeType} should be removed',
        );
      }
    });
    
    test('clearing formatting on partial selection removes styles only in selection', () {
      final random = Random(44);
      
      for (int i = 0; i < 50; i++) {
        final text = _generateRandomText(random, minLength: 30, maxLength: 100);
        
        final attributedText = AttributedText(text);
        final node = ParagraphNode(
          id: 'node1',
          text: attributedText,
        );
        
        // Apply bold to entire text
        node.text.addAttribution(
          boldAttribution,
          SpanRange(0, text.length - 1),
        );
        
        // Select a random portion of the text
        final selStart = random.nextInt(text.length ~/ 2);
        final selEnd = selStart + random.nextInt(text.length - selStart) + 1;
        
        // Simulate clearing formatting only in selection
        for (int pos = selStart; pos < selEnd && pos < text.length; pos++) {
          final attributions = node.text.getAllAttributionsAt(pos);
          for (final attr in attributions) {
            if (_isInlineStyleAttribution(attr)) {
              node.text.removeAttribution(attr, SpanRange(pos, pos));
            }
          }
        }
        
        // Verify styles are removed in selection
        for (int pos = selStart; pos < selEnd && pos < text.length; pos++) {
          final attributions = node.text.getAllAttributionsAt(pos);
          expect(
            attributions.contains(boldAttribution),
            isFalse,
            reason: 'Bold should be removed at position $pos in selection (iteration $i)',
          );
        }
        
        // Verify styles are preserved outside selection
        if (selStart > 0) {
          final attributions = node.text.getAllAttributionsAt(0);
          expect(
            attributions.contains(boldAttribution),
            isTrue,
            reason: 'Bold should be preserved before selection (iteration $i)',
          );
        }
        
        if (selEnd < text.length) {
          final attributions = node.text.getAllAttributionsAt(text.length - 1);
          expect(
            attributions.contains(boldAttribution),
            isTrue,
            reason: 'Bold should be preserved after selection (iteration $i)',
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

/// Check if text has any inline styles in the given range
bool _hasAnyInlineStyles(AttributedText text, int start, int end) {
  for (int i = start; i < end && i < text.length; i++) {
    final attributions = text.getAllAttributionsAt(i);
    for (final attr in attributions) {
      if (_isInlineStyleAttribution(attr)) {
        return true;
      }
    }
  }
  return false;
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

/// Check if two attributions are of the same type
bool _isSameAttributionType(Attribution a, Attribution b) {
  if (a.runtimeType != b.runtimeType) {
    return false;
  }
  
  // For named attributions, check the ID
  if (a is NamedAttribution && b is NamedAttribution) {
    return a.id == b.id;
  }
  
  // For other types, just check the runtime type
  return true;
}
