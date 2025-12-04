/// Property-based tests for font size application
/// 
/// Feature: rich-text-styling, Property 15: Font size application
/// Validates: Requirements 6.1, 6.5
/// 
/// Property 15: Font size application
/// For any text selection and any valid font size (6-200 points), applying that
/// size should add the font size attribution to the selected text

import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'dart:math';

void main() {
  group('Property 15: Font size application', () {
    test('font size application adds FontSizeAttribution to selected text', () {
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
        
        // Generate random valid font size (6-200)
        final fontSize = 6.0 + random.nextDouble() * 194.0;
        
        // Apply font size attribution
        final node = document.getNodeById('node1') as TextNode;
        node.text.addAttribution(
          FontSizeAttribution(fontSize),
          SpanRange(selection.start, selection.end - 1),
        );
        
        // Verify: Check that the font size attribution exists in the range
        final attributions = node.text.getAttributionSpansInRange(
          attributionFilter: (attr) => attr is FontSizeAttribution,
          range: SpanRange(selection.start, selection.end - 1),
        );
        
        expect(attributions.isNotEmpty, isTrue,
            reason: 'FontSizeAttribution should be present after application');
        
        // Verify the font size matches
        final fontSizeAttr = attributions.first.attribution as FontSizeAttribution;
        expect(fontSizeAttr.fontSize, equals(fontSize),
            reason: 'Applied font size should match the specified size');
        
        // Verify the attribution covers the entire selection
        expect(attributions.first.start, lessThanOrEqualTo(selection.start),
            reason: 'Attribution should start at or before selection start');
        expect(attributions.first.end, greaterThanOrEqualTo(selection.end - 1),
            reason: 'Attribution should end at or after selection end');
      }
    });
    
    test('font size application works with boundary values', () {
      final random = Random(43);
      
      // Test minimum and maximum font sizes
      final boundarySizes = [6.0, 200.0];
      
      for (final fontSize in boundarySizes) {
        for (int i = 0; i < 10; i++) {
          final text = _generateRandomText(random, minLength: 10, maxLength: 50);
          
          final document = MutableDocument(
            nodes: [
              ParagraphNode(
                id: 'node1',
                text: AttributedText(text),
              ),
            ],
          );
          
          final selection = _generateRandomSelection(random, text.length);
          
          // Apply boundary font size
          final node = document.getNodeById('node1') as TextNode;
          node.text.addAttribution(
            FontSizeAttribution(fontSize),
            SpanRange(selection.start, selection.end - 1),
          );
          
          // Verify
          final attributions = node.text.getAttributionSpansInRange(
            attributionFilter: (attr) => attr is FontSizeAttribution,
            range: SpanRange(selection.start, selection.end - 1),
          );
          
          expect(attributions.isNotEmpty, isTrue,
              reason: 'Font size $fontSize should be applied successfully');
          
          final fontSizeAttr = attributions.first.attribution as FontSizeAttribution;
          expect(fontSizeAttr.fontSize, equals(fontSize),
              reason: 'Boundary font size $fontSize should be preserved');
        }
      }
    });
    
    test('font size application works with common sizes', () {
      final random = Random(44);
      
      // Test common font sizes from the dropdown
      final commonSizes = [8.0, 10.0, 12.0, 14.0, 16.0, 18.0, 20.0, 24.0, 28.0, 32.0, 36.0, 48.0, 72.0];
      
      for (final fontSize in commonSizes) {
        final text = _generateRandomText(random, minLength: 20, maxLength: 50);
        
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
        
        // Apply common font size
        final node = document.getNodeById('node1') as TextNode;
        node.text.addAttribution(
          FontSizeAttribution(fontSize),
          SpanRange(selection.start, selection.end - 1),
        );
        
        // Verify
        final attributions = node.text.getAttributionSpansInRange(
          attributionFilter: (attr) => attr is FontSizeAttribution,
          range: SpanRange(selection.start, selection.end - 1),
        );
        
        expect(attributions.isNotEmpty, isTrue,
            reason: 'Common font size $fontSize should be applied');
        
        final fontSizeAttr = attributions.first.attribution as FontSizeAttribution;
        expect(fontSizeAttr.fontSize, equals(fontSize),
            reason: 'Common font size $fontSize should be preserved exactly');
      }
    });
    
    test('font size application works across different text lengths', () {
      final random = Random(45);
      
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
        final fontSize = 6.0 + random.nextDouble() * 194.0;
        
        // Apply font size
        final node = document.getNodeById('node1') as TextNode;
        node.text.addAttribution(
          FontSizeAttribution(fontSize),
          SpanRange(selection.start, selection.end - 1),
        );
        
        // Verify
        final attributions = node.text.getAttributionSpansInRange(
          attributionFilter: (attr) => attr is FontSizeAttribution,
          range: SpanRange(selection.start, selection.end - 1),
        );
        
        expect(attributions.isNotEmpty, isTrue,
            reason: 'Font size should be applied to text of length $length');
      }
    });
    
    test('font size application preserves other attributions', () {
      final random = Random(46);
      
      for (int i = 0; i < 50; i++) {
        final text = _generateRandomText(random, minLength: 20, maxLength: 100);
        
        final document = MutableDocument(
          nodes: [
            ParagraphNode(
              id: 'node1',
              text: AttributedText(text),
            ),
          ],
        );
        
        final selection = _generateRandomSelection(random, text.length);
        final fontSize = 6.0 + random.nextDouble() * 194.0;
        
        // Apply bold first
        final node = document.getNodeById('node1') as TextNode;
        node.text.addAttribution(
          boldAttribution,
          SpanRange(selection.start, selection.end - 1),
        );
        
        // Then apply font size
        node.text.addAttribution(
          FontSizeAttribution(fontSize),
          SpanRange(selection.start, selection.end - 1),
        );
        
        // Verify both attributions exist
        final allAttributions = node.text.getAllAttributionsAt(selection.start);
        
        expect(allAttributions.contains(boldAttribution), isTrue,
            reason: 'Bold attribution should be preserved after font size application');
        
        expect(
          allAttributions.any((a) => a is FontSizeAttribution && a.fontSize == fontSize),
          isTrue,
          reason: 'Font size attribution should be present',
        );
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

/// Simple text selection class
class _TextSelection {
  final int start;
  final int end;
  
  _TextSelection(this.start, this.end);
}
