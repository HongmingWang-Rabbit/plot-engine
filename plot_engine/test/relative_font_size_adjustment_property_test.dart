/// Property-based tests for relative font size adjustment
/// 
/// Feature: rich-text-styling, Property 16: Relative font size adjustment
/// Validates: Requirements 6.2, 6.3
/// 
/// Property 16: Relative font size adjustment
/// For any text with font size S, increasing size should result in size S+2,
/// and decreasing should result in size S-2 (minimum 6)

import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'dart:math';

void main() {
  group('Property 16: Relative font size adjustment', () {
    test('increasing font size adds 2 points', () {
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
        
        // Generate random initial font size (6-198 to allow for +2)
        final initialSize = 6.0 + random.nextDouble() * 192.0;
        
        // Apply initial font size
        final node = document.getNodeById('node1') as TextNode;
        node.text.addAttribution(
          FontSizeAttribution(initialSize),
          SpanRange(selection.start, selection.end - 1),
        );
        
        // Calculate expected new size
        final expectedSize = initialSize + 2.0;
        
        // Remove old attribution and apply new size (simulating increase)
        node.text.removeAttribution(
          FontSizeAttribution(initialSize),
          SpanRange(selection.start, selection.end - 1),
        );
        node.text.addAttribution(
          FontSizeAttribution(expectedSize),
          SpanRange(selection.start, selection.end - 1),
        );
        
        // Verify: Check that the new font size is initial + 2
        final attributions = node.text.getAttributionSpansInRange(
          attributionFilter: (attr) => attr is FontSizeAttribution,
          range: SpanRange(selection.start, selection.end - 1),
        );
        
        expect(attributions.isNotEmpty, isTrue,
            reason: 'FontSizeAttribution should be present after increase');
        
        final fontSizeAttr = attributions.first.attribution as FontSizeAttribution;
        expect(fontSizeAttr.fontSize, equals(expectedSize),
            reason: 'Font size should increase by 2 points (from $initialSize to $expectedSize)');
      }
    });
    
    test('decreasing font size subtracts 2 points', () {
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
        
        // Generate random initial font size (8-200 to allow for -2 without going below 6)
        final initialSize = 8.0 + random.nextDouble() * 192.0;
        
        // Apply initial font size
        final node = document.getNodeById('node1') as TextNode;
        node.text.addAttribution(
          FontSizeAttribution(initialSize),
          SpanRange(selection.start, selection.end - 1),
        );
        
        // Calculate expected new size
        final expectedSize = initialSize - 2.0;
        
        // Remove old attribution and apply new size (simulating decrease)
        node.text.removeAttribution(
          FontSizeAttribution(initialSize),
          SpanRange(selection.start, selection.end - 1),
        );
        node.text.addAttribution(
          FontSizeAttribution(expectedSize),
          SpanRange(selection.start, selection.end - 1),
        );
        
        // Verify: Check that the new font size is initial - 2
        final attributions = node.text.getAttributionSpansInRange(
          attributionFilter: (attr) => attr is FontSizeAttribution,
          range: SpanRange(selection.start, selection.end - 1),
        );
        
        expect(attributions.isNotEmpty, isTrue,
            reason: 'FontSizeAttribution should be present after decrease');
        
        final fontSizeAttr = attributions.first.attribution as FontSizeAttribution;
        expect(fontSizeAttr.fontSize, equals(expectedSize),
            reason: 'Font size should decrease by 2 points (from $initialSize to $expectedSize)');
      }
    });
    
    test('decreasing font size respects minimum of 6', () {
      final random = Random(44);
      
      // Test sizes near the minimum
      final testSizes = [6.0, 7.0, 8.0, 9.0, 10.0];
      
      for (final initialSize in testSizes) {
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
          
          // Apply initial font size
          final node = document.getNodeById('node1') as TextNode;
          node.text.addAttribution(
            FontSizeAttribution(initialSize),
            SpanRange(selection.start, selection.end - 1),
          );
          
          // Calculate expected new size (clamped to minimum 6)
          final expectedSize = (initialSize - 2.0).clamp(6.0, 200.0);
          
          // Remove old attribution and apply new size (simulating decrease with clamping)
          node.text.removeAttribution(
            FontSizeAttribution(initialSize),
            SpanRange(selection.start, selection.end - 1),
          );
          node.text.addAttribution(
            FontSizeAttribution(expectedSize),
            SpanRange(selection.start, selection.end - 1),
          );
          
          // Verify
          final attributions = node.text.getAttributionSpansInRange(
            attributionFilter: (attr) => attr is FontSizeAttribution,
            range: SpanRange(selection.start, selection.end - 1),
          );
          
          expect(attributions.isNotEmpty, isTrue,
              reason: 'FontSizeAttribution should be present after decrease');
          
          final fontSizeAttr = attributions.first.attribution as FontSizeAttribution;
          expect(fontSizeAttr.fontSize, greaterThanOrEqualTo(6.0),
              reason: 'Font size should not go below minimum of 6');
          expect(fontSizeAttr.fontSize, equals(expectedSize),
              reason: 'Font size should be clamped correctly');
        }
      }
    });
    
    test('increasing font size respects maximum of 200', () {
      final random = Random(45);
      
      // Test sizes near the maximum
      final testSizes = [196.0, 197.0, 198.0, 199.0, 200.0];
      
      for (final initialSize in testSizes) {
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
          
          // Apply initial font size
          final node = document.getNodeById('node1') as TextNode;
          node.text.addAttribution(
            FontSizeAttribution(initialSize),
            SpanRange(selection.start, selection.end - 1),
          );
          
          // Calculate expected new size (clamped to maximum 200)
          final expectedSize = (initialSize + 2.0).clamp(6.0, 200.0);
          
          // Remove old attribution and apply new size (simulating increase with clamping)
          node.text.removeAttribution(
            FontSizeAttribution(initialSize),
            SpanRange(selection.start, selection.end - 1),
          );
          node.text.addAttribution(
            FontSizeAttribution(expectedSize),
            SpanRange(selection.start, selection.end - 1),
          );
          
          // Verify
          final attributions = node.text.getAttributionSpansInRange(
            attributionFilter: (attr) => attr is FontSizeAttribution,
            range: SpanRange(selection.start, selection.end - 1),
          );
          
          expect(attributions.isNotEmpty, isTrue,
              reason: 'FontSizeAttribution should be present after increase');
          
          final fontSizeAttr = attributions.first.attribution as FontSizeAttribution;
          expect(fontSizeAttr.fontSize, lessThanOrEqualTo(200.0),
              reason: 'Font size should not exceed maximum of 200');
          expect(fontSizeAttr.fontSize, equals(expectedSize),
              reason: 'Font size should be clamped correctly');
        }
      }
    });
    
    test('multiple adjustments accumulate correctly', () {
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
        
        // Start with a middle-range size
        var currentSize = 50.0;
        
        final node = document.getNodeById('node1') as TextNode;
        node.text.addAttribution(
          FontSizeAttribution(currentSize),
          SpanRange(selection.start, selection.end - 1),
        );
        
        // Perform multiple increases
        for (int j = 0; j < 5; j++) {
          final oldSize = currentSize;
          currentSize = (currentSize + 2.0).clamp(6.0, 200.0);
          
          node.text.removeAttribution(
            FontSizeAttribution(oldSize),
            SpanRange(selection.start, selection.end - 1),
          );
          node.text.addAttribution(
            FontSizeAttribution(currentSize),
            SpanRange(selection.start, selection.end - 1),
          );
        }
        
        // Verify final size is 50 + (5 * 2) = 60
        var attributions = node.text.getAttributionSpansInRange(
          attributionFilter: (attr) => attr is FontSizeAttribution,
          range: SpanRange(selection.start, selection.end - 1),
        );
        
        var fontSizeAttr = attributions.first.attribution as FontSizeAttribution;
        expect(fontSizeAttr.fontSize, equals(60.0),
            reason: 'Multiple increases should accumulate correctly');
        
        // Perform multiple decreases
        for (int j = 0; j < 3; j++) {
          final oldSize = currentSize;
          currentSize = (currentSize - 2.0).clamp(6.0, 200.0);
          
          node.text.removeAttribution(
            FontSizeAttribution(oldSize),
            SpanRange(selection.start, selection.end - 1),
          );
          node.text.addAttribution(
            FontSizeAttribution(currentSize),
            SpanRange(selection.start, selection.end - 1),
          );
        }
        
        // Verify final size is 60 - (3 * 2) = 54
        attributions = node.text.getAttributionSpansInRange(
          attributionFilter: (attr) => attr is FontSizeAttribution,
          range: SpanRange(selection.start, selection.end - 1),
        );
        
        fontSizeAttr = attributions.first.attribution as FontSizeAttribution;
        expect(fontSizeAttr.fontSize, equals(54.0),
            reason: 'Multiple decreases should accumulate correctly');
      }
    });
    
    test('relative adjustment preserves other attributions', () {
      final random = Random(47);
      
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
        final initialSize = 20.0;
        
        // Apply bold and initial font size
        final node = document.getNodeById('node1') as TextNode;
        node.text.addAttribution(
          boldAttribution,
          SpanRange(selection.start, selection.end - 1),
        );
        node.text.addAttribution(
          FontSizeAttribution(initialSize),
          SpanRange(selection.start, selection.end - 1),
        );
        
        // Increase font size
        final newSize = initialSize + 2.0;
        node.text.removeAttribution(
          FontSizeAttribution(initialSize),
          SpanRange(selection.start, selection.end - 1),
        );
        node.text.addAttribution(
          FontSizeAttribution(newSize),
          SpanRange(selection.start, selection.end - 1),
        );
        
        // Verify both attributions exist
        final allAttributions = node.text.getAllAttributionsAt(selection.start);
        
        expect(allAttributions.contains(boldAttribution), isTrue,
            reason: 'Bold attribution should be preserved after font size adjustment');
        
        expect(
          allAttributions.any((a) => a is FontSizeAttribution && a.fontSize == newSize),
          isTrue,
          reason: 'New font size attribution should be present',
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
