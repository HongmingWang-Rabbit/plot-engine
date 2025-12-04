import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'package:plot_engine/services/entity_attribution_service.dart';
import 'package:plot_engine/models/entity.dart';
import 'package:plot_engine/models/entity_type.dart';
import 'dart:math' as math;

void main() {
  group('Formatting Attributions', () {
    // Feature: rich-text-styling, Property 1: Inline style application
    // Validates: Requirements 1.1, 1.2, 1.3, 1.4
    test('Property 1: Inline style application - bold, italic, underline, strikethrough', () {
      final random = math.Random(42); // Fixed seed for reproducibility
      
      for (int iteration = 0; iteration < 100; iteration++) {
        // Generate random text (1-100 characters)
        final textLength = random.nextInt(100) + 1;
        final text = _generateRandomText(textLength, random);
        
        // Generate random selection within text bounds
        final selectionStart = random.nextInt(textLength);
        final selectionEnd = selectionStart + random.nextInt(textLength - selectionStart) + 1;
        final selection = SpanRange(selectionStart, selectionEnd - 1);
        
        // Test each inline style type using super_editor's built-in attributions
        final styles = [
          boldAttribution,
          italicsAttribution,
          underlineAttribution,
          strikethroughAttribution,
        ];
        
        for (final style in styles) {
          // Create a paragraph node with the text
          final attributedText = AttributedText(text);
          final node = ParagraphNode(
            id: 'test-node',
            text: attributedText,
          );
          
          // Apply the style to the selection
          node.text.addAttribution(style, selection);
          
          // Verify: All characters in the selection should have the attribution
          for (int i = selection.start; i <= selection.end; i++) {
            final attributions = node.text.getAllAttributionsAt(i);
            expect(
              attributions.contains(style),
              isTrue,
              reason: 'Character at position $i should have ${style.id} attribution '
                  '(iteration $iteration, text length: $textLength, selection: ${selection.start}-${selection.end})',
            );
          }
          
          // Verify: Characters outside the selection should NOT have the attribution
          for (int i = 0; i < selection.start; i++) {
            final attributions = node.text.getAllAttributionsAt(i);
            expect(
              attributions.contains(style),
              isFalse,
              reason: 'Character at position $i (before selection) should NOT have ${style.id} attribution '
                  '(iteration $iteration)',
            );
          }
          
          if (selection.end < textLength - 1) {
            for (int i = selection.end + 1; i < textLength; i++) {
              final attributions = node.text.getAllAttributionsAt(i);
              expect(
                attributions.contains(style),
                isFalse,
                reason: 'Character at position $i (after selection) should NOT have ${style.id} attribution '
                    '(iteration $iteration)',
              );
            }
          }
        }
      }
    });
    
    // Feature: rich-text-styling, Property 1: Inline style application - text color
    // Validates: Requirements 5.1
    test('Property 1: Inline style application - text color', () {
      final random = math.Random(43);
      
      for (int iteration = 0; iteration < 100; iteration++) {
        final textLength = random.nextInt(100) + 1;
        final text = _generateRandomText(textLength, random);
        
        final selectionStart = random.nextInt(textLength);
        final selectionEnd = selectionStart + random.nextInt(textLength - selectionStart) + 1;
        final selection = SpanRange(selectionStart, selectionEnd - 1);
        
        // Generate random color
        final color = Color.fromARGB(
          255,
          random.nextInt(256),
          random.nextInt(256),
          random.nextInt(256),
        );
        final style = ColorAttribution(color);
        
        final attributedText = AttributedText(text);
        final node = ParagraphNode(
          id: 'test-node',
          text: attributedText,
        );
        
        node.text.addAttribution(style, selection);
        
        // Verify all characters in selection have the color attribution
        for (int i = selection.start; i <= selection.end; i++) {
          final attributions = node.text.getAllAttributionsAt(i);
          expect(
            attributions.any((a) => a is ColorAttribution && a.color == color),
            isTrue,
            reason: 'Character at position $i should have text color attribution '
                '(iteration $iteration)',
          );
        }
      }
    });
    
    // Feature: rich-text-styling, Property 1: Inline style application - highlight color
    // Validates: Requirements 5.2
    test('Property 1: Inline style application - highlight color', () {
      final random = math.Random(44);
      
      for (int iteration = 0; iteration < 100; iteration++) {
        final textLength = random.nextInt(100) + 1;
        final text = _generateRandomText(textLength, random);
        
        final selectionStart = random.nextInt(textLength);
        final selectionEnd = selectionStart + random.nextInt(textLength - selectionStart) + 1;
        final selection = SpanRange(selectionStart, selectionEnd - 1);
        
        // Generate random color
        final color = Color.fromARGB(
          255,
          random.nextInt(256),
          random.nextInt(256),
          random.nextInt(256),
        );
        final style = BackgroundColorAttribution(color);
        
        final attributedText = AttributedText(text);
        final node = ParagraphNode(
          id: 'test-node',
          text: attributedText,
        );
        
        node.text.addAttribution(style, selection);
        
        // Verify all characters in selection have the highlight attribution
        for (int i = selection.start; i <= selection.end; i++) {
          final attributions = node.text.getAllAttributionsAt(i);
          expect(
            attributions.any((a) => a is BackgroundColorAttribution && a.color == color),
            isTrue,
            reason: 'Character at position $i should have highlight color attribution '
                '(iteration $iteration)',
          );
        }
      }
    });
    
    // Feature: rich-text-styling, Property 1: Inline style application - font size
    // Validates: Requirements 6.1
    test('Property 1: Inline style application - font size', () {
      final random = math.Random(45);
      
      for (int iteration = 0; iteration < 100; iteration++) {
        final textLength = random.nextInt(100) + 1;
        final text = _generateRandomText(textLength, random);
        
        final selectionStart = random.nextInt(textLength);
        final selectionEnd = selectionStart + random.nextInt(textLength - selectionStart) + 1;
        final selection = SpanRange(selectionStart, selectionEnd - 1);
        
        // Generate random font size between 6 and 200
        final fontSize = 6.0 + random.nextDouble() * 194.0;
        final style = FontSizeAttribution(fontSize);
        
        final attributedText = AttributedText(text);
        final node = ParagraphNode(
          id: 'test-node',
          text: attributedText,
        );
        
        node.text.addAttribution(style, selection);
        
        // Verify all characters in selection have the font size attribution
        for (int i = selection.start; i <= selection.end; i++) {
          final attributions = node.text.getAllAttributionsAt(i);
          expect(
            attributions.any((a) => a is FontSizeAttribution && a.fontSize == fontSize),
            isTrue,
            reason: 'Character at position $i should have font size attribution '
                '(iteration $iteration)',
          );
        }
      }
    });
    
    // Feature: rich-text-styling, Property 4: Style toggle behavior
    // Validates: Requirements 1.7
    test('Property 4: Style toggle behavior - applying same style twice removes it', () {
      final random = math.Random(46);
      
      for (int iteration = 0; iteration < 100; iteration++) {
        // Generate random text (1-100 characters)
        final textLength = random.nextInt(100) + 1;
        final text = _generateRandomText(textLength, random);
        
        // Generate random selection within text bounds
        final selectionStart = random.nextInt(textLength);
        final selectionEnd = selectionStart + random.nextInt(textLength - selectionStart) + 1;
        final selection = SpanRange(selectionStart, selectionEnd - 1);
        
        // Test each inline style type
        final styles = [
          boldAttribution,
          italicsAttribution,
          underlineAttribution,
          strikethroughAttribution,
        ];
        
        for (final style in styles) {
          // Create a paragraph node with the text
          final attributedText = AttributedText(text);
          final node = ParagraphNode(
            id: 'test-node',
            text: attributedText,
          );
          
          // Apply the style once
          node.text.addAttribution(style, selection);
          
          // Verify it's applied
          for (int i = selection.start; i <= selection.end; i++) {
            final attributions = node.text.getAllAttributionsAt(i);
            expect(
              attributions.contains(style),
              isTrue,
              reason: 'After first application, character at position $i should have ${style.id} '
                  '(iteration $iteration)',
            );
          }
          
          // Apply the style again (toggle off)
          node.text.removeAttribution(style, selection);
          
          // Verify it's removed
          for (int i = selection.start; i <= selection.end; i++) {
            final attributions = node.text.getAllAttributionsAt(i);
            expect(
              attributions.contains(style),
              isFalse,
              reason: 'After toggle off, character at position $i should NOT have ${style.id} '
                  '(iteration $iteration)',
            );
          }
        }
      }
    });
    
    // Feature: rich-text-styling, Property 2: Multiple inline styles coexist
    // Validates: Requirements 1.5
    test('Property 2: Multiple inline styles coexist - all styles present simultaneously', () {
      final random = math.Random(47);
      
      for (int iteration = 0; iteration < 100; iteration++) {
        // Generate random text (1-100 characters)
        final textLength = random.nextInt(100) + 1;
        final text = _generateRandomText(textLength, random);
        
        // Generate random selection within text bounds
        final selectionStart = random.nextInt(textLength);
        final selectionEnd = selectionStart + random.nextInt(textLength - selectionStart) + 1;
        final selection = SpanRange(selectionStart, selectionEnd - 1);
        
        // Create a paragraph node with the text
        final attributedText = AttributedText(text);
        final node = ParagraphNode(
          id: 'test-node',
          text: attributedText,
        );
        
        // Apply multiple styles
        final styles = [
          boldAttribution,
          italicsAttribution,
          underlineAttribution,
          strikethroughAttribution,
        ];
        
        // Randomly select 2-4 styles to apply
        final numStylesToApply = 2 + random.nextInt(3);
        final stylesToApply = <Attribution>[];
        final availableStyles = List<Attribution>.from(styles);
        
        for (int i = 0; i < numStylesToApply; i++) {
          final styleIndex = random.nextInt(availableStyles.length);
          stylesToApply.add(availableStyles[styleIndex]);
          availableStyles.removeAt(styleIndex);
        }
        
        // Apply all selected styles
        for (final style in stylesToApply) {
          node.text.addAttribution(style, selection);
        }
        
        // Verify: All applied styles should be present on all characters in selection
        for (int i = selection.start; i <= selection.end; i++) {
          final attributions = node.text.getAllAttributionsAt(i);
          
          for (final style in stylesToApply) {
            expect(
              attributions.contains(style),
              isTrue,
              reason: 'Character at position $i should have ${style.id} attribution '
                  'when multiple styles are applied (iteration $iteration, '
                  'applied ${stylesToApply.length} styles)',
            );
          }
        }
        
        // Verify: The number of formatting attributions should match what we applied
        for (int i = selection.start; i <= selection.end; i++) {
          final attributions = node.text.getAllAttributionsAt(i);
          final formattingAttributions = attributions.where((a) => 
            a == boldAttribution || 
            a == italicsAttribution || 
            a == underlineAttribution || 
            a == strikethroughAttribution
          ).toSet();
          
          expect(
            formattingAttributions.length,
            equals(stylesToApply.length),
            reason: 'Character at position $i should have exactly ${stylesToApply.length} '
                'formatting attributions (iteration $iteration)',
          );
        }
      }
    });
    
    // Feature: rich-text-styling, Property 21: Entity and formatting coexistence
    // Validates: Requirements 11.1, 11.2, 11.5
    test('Property 21: Entity and formatting coexistence - formatting preserves entity attributions', () {
      final random = math.Random(48);
      
      for (int iteration = 0; iteration < 100; iteration++) {
        // Generate random text (20-100 characters to ensure space for entities)
        final textLength = 20 + random.nextInt(81);
        final text = _generateRandomText(textLength, random);
        
        // Create a paragraph node with the text
        final attributedText = AttributedText(text);
        final node = ParagraphNode(
          id: 'test-node',
          text: attributedText,
        );
        
        // Generate random entity within the text
        final entityStart = random.nextInt(textLength - 5);
        final entityEnd = entityStart + 3 + random.nextInt(math.min(10, textLength - entityStart - 3));
        final entityName = text.substring(entityStart, entityEnd);
        
        final entity = Entity(
          name: entityName,
          type: EntityType.values[random.nextInt(EntityType.values.length)],
          recognized: random.nextBool(),
          startOffset: entityStart,
          endOffset: entityEnd,
        );
        
        // Apply entity attribution
        final entityAttribution = EntityAttribution(entity);
        node.text.addAttribution(
          entityAttribution,
          SpanRange(entityStart, entityEnd - 1),
        );
        
        // Verify entity attribution is applied
        for (int i = entityStart; i < entityEnd; i++) {
          final attributions = node.text.getAllAttributionsAt(i);
          expect(
            attributions.any((a) => a is EntityAttribution && a.entity.name == entityName),
            isTrue,
            reason: 'Entity attribution should be present at position $i before formatting '
                '(iteration $iteration)',
          );
        }
        
        // Generate random formatting selection that overlaps with entity
        // Ensure overlap by selecting a range that includes at least part of the entity
        final formatStart = entityStart - random.nextInt(math.min(5, entityStart + 1));
        final formatEnd = entityEnd + random.nextInt(math.min(10, textLength - entityEnd));
        final formatSelection = SpanRange(formatStart, formatEnd - 1);
        
        // Apply random formatting styles
        final formattingStyles = [
          boldAttribution,
          italicsAttribution,
          underlineAttribution,
          strikethroughAttribution,
        ];
        
        // Randomly select 1-3 formatting styles to apply
        final numStylesToApply = 1 + random.nextInt(3);
        final stylesToApply = <Attribution>[];
        final availableStyles = List<Attribution>.from(formattingStyles);
        
        for (int i = 0; i < numStylesToApply; i++) {
          final styleIndex = random.nextInt(availableStyles.length);
          stylesToApply.add(availableStyles[styleIndex]);
          availableStyles.removeAt(styleIndex);
        }
        
        // Apply all selected formatting styles
        for (final style in stylesToApply) {
          node.text.addAttribution(style, formatSelection);
        }
        
        // VERIFY: Entity attribution should still be present after formatting
        for (int i = entityStart; i < entityEnd; i++) {
          final attributions = node.text.getAllAttributionsAt(i);
          
          // Check entity attribution is preserved
          expect(
            attributions.any((a) => a is EntityAttribution && a.entity.name == entityName),
            isTrue,
            reason: 'Entity attribution should be preserved at position $i after formatting '
                '(iteration $iteration, applied ${stylesToApply.length} formatting styles)',
          );
          
          // Check formatting styles are also present in the overlap region
          if (i >= formatStart && i < formatEnd) {
            for (final style in stylesToApply) {
              expect(
                attributions.contains(style),
                isTrue,
                reason: 'Formatting style ${style.id} should be present at position $i '
                    'alongside entity attribution (iteration $iteration)',
              );
            }
          }
        }
        
        // VERIFY: Both entity and formatting attributions coexist in overlap region
        final overlapStart = math.max(entityStart, formatStart);
        final overlapEnd = math.min(entityEnd, formatEnd);
        
        if (overlapStart < overlapEnd) {
          for (int i = overlapStart; i < overlapEnd; i++) {
            final attributions = node.text.getAllAttributionsAt(i);
            
            // Count different types of attributions
            final hasEntity = attributions.any((a) => a is EntityAttribution);
            final formattingCount = attributions.where((a) => 
              a == boldAttribution || 
              a == italicsAttribution || 
              a == underlineAttribution || 
              a == strikethroughAttribution
            ).length;
            
            expect(
              hasEntity,
              isTrue,
              reason: 'Position $i in overlap region should have entity attribution '
                  '(iteration $iteration)',
            );
            
            expect(
              formattingCount,
              equals(stylesToApply.length),
              reason: 'Position $i in overlap region should have ${stylesToApply.length} '
                  'formatting attributions (iteration $iteration)',
            );
          }
        }
      }
    });
    
    // Feature: rich-text-styling, Property 21: Entity and formatting coexistence - text color with entity
    // Validates: Requirements 11.5
    test('Property 21: Entity and formatting coexistence - text color preserves entity underline', () {
      final random = math.Random(49);
      
      for (int iteration = 0; iteration < 100; iteration++) {
        // Generate random text
        final textLength = 20 + random.nextInt(81);
        final text = _generateRandomText(textLength, random);
        
        final attributedText = AttributedText(text);
        final node = ParagraphNode(
          id: 'test-node',
          text: attributedText,
        );
        
        // Generate random entity
        final entityStart = random.nextInt(textLength - 5);
        final entityEnd = entityStart + 3 + random.nextInt(math.min(10, textLength - entityStart - 3));
        final entityName = text.substring(entityStart, entityEnd);
        
        final entity = Entity(
          name: entityName,
          type: EntityType.character,
          recognized: random.nextBool(),
          startOffset: entityStart,
          endOffset: entityEnd,
        );
        
        // Apply entity attribution
        final entityAttribution = EntityAttribution(entity);
        node.text.addAttribution(
          entityAttribution,
          SpanRange(entityStart, entityEnd - 1),
        );
        
        // Apply text color to the entity
        final textColor = Color.fromARGB(
          255,
          random.nextInt(256),
          random.nextInt(256),
          random.nextInt(256),
        );
        final colorAttribution = ColorAttribution(textColor);
        node.text.addAttribution(
          colorAttribution,
          SpanRange(entityStart, entityEnd - 1),
        );
        
        // VERIFY: Both entity and color attributions are present
        for (int i = entityStart; i < entityEnd; i++) {
          final attributions = node.text.getAllAttributionsAt(i);
          
          expect(
            attributions.any((a) => a is EntityAttribution),
            isTrue,
            reason: 'Entity attribution should be present at position $i with text color '
                '(iteration $iteration)',
          );
          
          expect(
            attributions.any((a) => a is ColorAttribution && a.color == textColor),
            isTrue,
            reason: 'Text color attribution should be present at position $i with entity '
                '(iteration $iteration)',
          );
        }
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
