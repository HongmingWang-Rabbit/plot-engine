/// Property-based tests for color application
/// 
/// Feature: rich-text-styling, Property 13: Color application
/// Validates: Requirements 5.1, 5.2
/// 
/// Property 13: Color application
/// For any text selection and any color, applying text color or highlight color
/// should add the corresponding color attribution to the selected text

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'dart:math';

void main() {
  group('Property 13: Color application', () {
    test('text color application adds ColorAttribution to selected text', () {
      final random = Random(42);
      
      for (int i = 0; i < 100; i++) {
        // Generate random text
        final text = _generateRandomText(random, minLength: 10, maxLength: 100);
        
        // Create document with text
        final document = MutableDocument(
          nodes: [
            ParagraphNode(
              id: 'node1',
              text: AttributedText(text),
            ),
          ],
        );
        
        // Generate random selection
        final selection = _generateRandomSelection(random, text.length);
        
        // Generate random color
        final color = _generateRandomColor(random);
        
        // Apply color attribution
        final node = document.getNodeById('node1') as TextNode;
        node.text.addAttribution(
          ColorAttribution(color),
          SpanRange(selection.start, selection.end - 1),
        );
        
        // Verify: Check that the color attribution exists in the range
        final attributions = node.text.getAttributionSpansInRange(
          attributionFilter: (attr) => attr is ColorAttribution,
          range: SpanRange(selection.start, selection.end - 1),
        );
        
        expect(attributions.isNotEmpty, isTrue,
            reason: 'ColorAttribution should be present after application');
        
        // Verify the color matches
        final colorAttr = attributions.first.attribution as ColorAttribution;
        expect(colorAttr.color, equals(color),
            reason: 'Applied color should match the specified color');
        
        // Verify the attribution covers the entire selection
        expect(attributions.first.start, lessThanOrEqualTo(selection.start),
            reason: 'Attribution should start at or before selection start');
        expect(attributions.first.end, greaterThanOrEqualTo(selection.end - 1),
            reason: 'Attribution should end at or after selection end');
      }
    });
    
    test('highlight color application adds BackgroundColorAttribution to selected text', () {
      final random = Random(43);
      
      for (int i = 0; i < 100; i++) {
        // Generate random text
        final text = _generateRandomText(random, minLength: 10, maxLength: 100);
        
        // Create document with text
        final document = MutableDocument(
          nodes: [
            ParagraphNode(
              id: 'node1',
              text: AttributedText(text),
            ),
          ],
        );
        
        // Generate random selection
        final selection = _generateRandomSelection(random, text.length);
        
        // Generate random color
        final color = _generateRandomColor(random);
        
        // Apply highlight color attribution
        final node = document.getNodeById('node1') as TextNode;
        node.text.addAttribution(
          BackgroundColorAttribution(color),
          SpanRange(selection.start, selection.end - 1),
        );
        
        // Verify: Check that the background color attribution exists in the range
        final attributions = node.text.getAttributionSpansInRange(
          attributionFilter: (attr) => attr is BackgroundColorAttribution,
          range: SpanRange(selection.start, selection.end - 1),
        );
        
        expect(attributions.isNotEmpty, isTrue,
            reason: 'BackgroundColorAttribution should be present after application');
        
        // Verify the color matches
        final colorAttr = attributions.first.attribution as BackgroundColorAttribution;
        expect(colorAttr.color, equals(color),
            reason: 'Applied highlight color should match the specified color');
        
        // Verify the attribution covers the entire selection
        expect(attributions.first.start, lessThanOrEqualTo(selection.start),
            reason: 'Attribution should start at or before selection start');
        expect(attributions.first.end, greaterThanOrEqualTo(selection.end - 1),
            reason: 'Attribution should end at or after selection end');
      }
    });
    
    test('color application works across different text lengths', () {
      final random = Random(44);
      
      // Test with various text lengths
      final testLengths = [1, 5, 10, 50, 100, 500];
      
      for (final length in testLengths) {
        final text = _generateRandomText(random, minLength: length, maxLength: length);
        
        final document = MutableDocument(
          nodes: [
            ParagraphNode(
              id: 'node1',
              text: AttributedText(text),
            ),
          ],
        );
        
        // Select entire text
        final selection = _TextSelection(0, text.length);
        final color = _generateRandomColor(random);
        
        // Apply color
        final node = document.getNodeById('node1') as TextNode;
        node.text.addAttribution(
          ColorAttribution(color),
          SpanRange(selection.start, selection.end - 1),
        );
        
        // Verify
        final attributions = node.text.getAttributionSpansInRange(
          attributionFilter: (attr) => attr is ColorAttribution,
          range: SpanRange(selection.start, selection.end - 1),
        );
        
        expect(attributions.isNotEmpty, isTrue,
            reason: 'Color should be applied to text of length $length');
      }
    });
  });
}

/// Generate random text of specified length
String _generateRandomText(Random random, {required int minLength, required int maxLength}) {
  final length = minLength + random.nextInt(maxLength - minLength + 1);
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ';
  return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
}

/// Generate random selection within text bounds
_TextSelection _generateRandomSelection(Random random, int textLength) {
  if (textLength <= 1) {
    return _TextSelection(0, textLength);
  }
  
  final start = random.nextInt(textLength - 1);
  final end = start + 1 + random.nextInt(textLength - start - 1);
  return _TextSelection(start, end);
}

/// Generate random color
Color _generateRandomColor(Random random) {
  return Color.fromARGB(
    255,
    random.nextInt(256),
    random.nextInt(256),
    random.nextInt(256),
  );
}

/// Simple text selection class
class _TextSelection {
  final int start;
  final int end;
  
  _TextSelection(this.start, this.end);
}
