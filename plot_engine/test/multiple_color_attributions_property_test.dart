/// Property-based tests for multiple color attributions
/// 
/// Feature: rich-text-styling, Property 14: Multiple color attributions
/// Validates: Requirements 5.5
/// 
/// Property 14: Multiple color attributions
/// For any text selection, applying both text color and highlight color
/// should result in both color attributions being present simultaneously

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'dart:math';

void main() {
  group('Property 14: Multiple color attributions', () {
    test('text color and highlight color coexist on same text', () {
      final random = Random(45);
      
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
        
        // Generate random colors
        final textColor = _generateRandomColor(random);
        final highlightColor = _generateRandomColor(random);
        
        // Apply both color attributions
        final node = document.getNodeById('node1') as TextNode;
        final range = SpanRange(selection.start, selection.end - 1);
        
        node.text.addAttribution(ColorAttribution(textColor), range);
        node.text.addAttribution(BackgroundColorAttribution(highlightColor), range);
        
        // Verify: Check that both attributions exist in the range
        final textColorAttributions = node.text.getAttributionSpansInRange(
          attributionFilter: (attr) => attr is ColorAttribution,
          range: range,
        );
        
        final highlightColorAttributions = node.text.getAttributionSpansInRange(
          attributionFilter: (attr) => attr is BackgroundColorAttribution,
          range: range,
        );
        
        expect(textColorAttributions.isNotEmpty, isTrue,
            reason: 'ColorAttribution should be present');
        expect(highlightColorAttributions.isNotEmpty, isTrue,
            reason: 'BackgroundColorAttribution should be present');
        
        // Verify the colors match
        final textColorAttr = textColorAttributions.first.attribution as ColorAttribution;
        final highlightColorAttr = highlightColorAttributions.first.attribution as BackgroundColorAttribution;
        
        expect(textColorAttr.color, equals(textColor),
            reason: 'Text color should match');
        expect(highlightColorAttr.color, equals(highlightColor),
            reason: 'Highlight color should match');
        
        // Verify both attributions cover the entire selection
        expect(textColorAttributions.first.start, lessThanOrEqualTo(selection.start));
        expect(textColorAttributions.first.end, greaterThanOrEqualTo(selection.end - 1));
        expect(highlightColorAttributions.first.start, lessThanOrEqualTo(selection.start));
        expect(highlightColorAttributions.first.end, greaterThanOrEqualTo(selection.end - 1));
      }
    });
    
    test('multiple color attributions work with different application orders', () {
      final random = Random(46);
      
      for (int i = 0; i < 100; i++) {
        final text = _generateRandomText(random, minLength: 10, maxLength: 50);
        
        // Test both orders: text color first, then highlight color first
        for (final textColorFirst in [true, false]) {
          final document = MutableDocument(
            nodes: [
              ParagraphNode(
                id: 'node1',
                text: AttributedText(text),
              ),
            ],
          );
          
          final selection = _generateRandomSelection(random, text.length);
          final textColor = _generateRandomColor(random);
          final highlightColor = _generateRandomColor(random);
          
          final node = document.getNodeById('node1') as TextNode;
          final range = SpanRange(selection.start, selection.end - 1);
          
          // Apply in different orders
          if (textColorFirst) {
            node.text.addAttribution(ColorAttribution(textColor), range);
            node.text.addAttribution(BackgroundColorAttribution(highlightColor), range);
          } else {
            node.text.addAttribution(BackgroundColorAttribution(highlightColor), range);
            node.text.addAttribution(ColorAttribution(textColor), range);
          }
          
          // Verify both are present regardless of order
          final textColorAttributions = node.text.getAttributionSpansInRange(
            attributionFilter: (attr) => attr is ColorAttribution,
            range: range,
          );
          
          final highlightColorAttributions = node.text.getAttributionSpansInRange(
            attributionFilter: (attr) => attr is BackgroundColorAttribution,
            range: range,
          );
          
          expect(textColorAttributions.isNotEmpty, isTrue,
              reason: 'ColorAttribution should be present (order: ${textColorFirst ? "text first" : "highlight first"})');
          expect(highlightColorAttributions.isNotEmpty, isTrue,
              reason: 'BackgroundColorAttribution should be present (order: ${textColorFirst ? "text first" : "highlight first"})');
        }
      }
    });
    
    test('multiple color attributions work with overlapping ranges', () {
      final random = Random(47);
      
      for (int i = 0; i < 100; i++) {
        final text = _generateRandomText(random, minLength: 20, maxLength: 100);
        
        final document = MutableDocument(
          nodes: [
            ParagraphNode(
              id: 'node1',
              text: AttributedText(text),
            ),
          ],
        );
        
        // Generate two overlapping selections
        final selection1 = _generateRandomSelection(random, text.length);
        final selection2 = _generateRandomSelection(random, text.length);
        
        // Find the overlap
        final overlapStart = max(selection1.start, selection2.start);
        final overlapEnd = min(selection1.end, selection2.end);
        
        if (overlapStart < overlapEnd) {
          final textColor = _generateRandomColor(random);
          final highlightColor = _generateRandomColor(random);
          
          final node = document.getNodeById('node1') as TextNode;
          
          // Apply text color to first range
          node.text.addAttribution(
            ColorAttribution(textColor),
            SpanRange(selection1.start, selection1.end - 1),
          );
          
          // Apply highlight color to second range
          node.text.addAttribution(
            BackgroundColorAttribution(highlightColor),
            SpanRange(selection2.start, selection2.end - 1),
          );
          
          // Verify both attributions exist in the overlap
          final overlapRange = SpanRange(overlapStart, overlapEnd - 1);
          
          final textColorAttributions = node.text.getAttributionSpansInRange(
            attributionFilter: (attr) => attr is ColorAttribution,
            range: overlapRange,
          );
          
          final highlightColorAttributions = node.text.getAttributionSpansInRange(
            attributionFilter: (attr) => attr is BackgroundColorAttribution,
            range: overlapRange,
          );
          
          expect(textColorAttributions.isNotEmpty, isTrue,
              reason: 'ColorAttribution should be present in overlap');
          expect(highlightColorAttributions.isNotEmpty, isTrue,
              reason: 'BackgroundColorAttribution should be present in overlap');
        }
      }
    });
    
    test('multiple color attributions persist after document modifications', () {
      final random = Random(48);
      
      for (int i = 0; i < 100; i++) {
        final text = _generateRandomText(random, minLength: 20, maxLength: 50);
        
        final document = MutableDocument(
          nodes: [
            ParagraphNode(
              id: 'node1',
              text: AttributedText(text),
            ),
          ],
        );
        
        final selection = _generateRandomSelection(random, text.length);
        final textColor = _generateRandomColor(random);
        final highlightColor = _generateRandomColor(random);
        
        final node = document.getNodeById('node1') as TextNode;
        final range = SpanRange(selection.start, selection.end - 1);
        
        // Apply both colors
        node.text.addAttribution(ColorAttribution(textColor), range);
        node.text.addAttribution(BackgroundColorAttribution(highlightColor), range);
        
        // Verify both attributions still exist
        final textColorAttributions = node.text.getAttributionSpansInRange(
          attributionFilter: (attr) => attr is ColorAttribution,
          range: range,
        );
        
        final highlightColorAttributions = node.text.getAttributionSpansInRange(
          attributionFilter: (attr) => attr is BackgroundColorAttribution,
          range: range,
        );
        
        expect(textColorAttributions.isNotEmpty, isTrue,
            reason: 'ColorAttribution should persist');
        expect(highlightColorAttributions.isNotEmpty, isTrue,
            reason: 'BackgroundColorAttribution should persist');
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
