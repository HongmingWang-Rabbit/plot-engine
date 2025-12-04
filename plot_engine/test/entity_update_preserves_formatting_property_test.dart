/// Property test for entity update preserves formatting
/// 
/// Feature: rich-text-styling, Property 22: Entity update preserves formatting
/// Validates: Requirements 11.4
/// 
/// This test verifies that when the entity recognition system updates,
/// all user-applied formatting is preserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'package:plot_engine/services/entity_attribution_service.dart';
import 'package:plot_engine/services/entity_recognizer.dart';
import 'package:plot_engine/models/entity.dart';
import 'package:plot_engine/models/entity_type.dart';
import 'dart:math';

void main() {
  group('Property 22: Entity update preserves formatting', () {
    test('entity recognition updates preserve all formatting attributions', () {
      final random = Random(60);
      
      // Run 100 iterations with random inputs
      for (int i = 0; i < 100; i++) {
        // Generate random text (at least 30 characters to have space for entities and formatting)
        final text = _generateRandomText(random, minLength: 30, maxLength: 100);
        
        // Create a paragraph node with the text
        final attributedText = AttributedText(text);
        final node = ParagraphNode(
          id: 'node1',
          text: attributedText,
        );
        
        // Apply random formatting styles to various parts of the text
        // Use non-overlapping ranges to avoid conflicts
        final numFormattingRanges = 2 + random.nextInt(3);
        final appliedFormatting = <(int, int, Attribution)>[];
        final usedRanges = <(int, int)>[];
        
        for (int j = 0; j < numFormattingRanges; j++) {
          // Try to find a non-overlapping range
          int attempts = 0;
          int start = 0;
          int end = 0;
          bool foundRange = false;
          
          while (attempts < 20 && !foundRange) {
            start = random.nextInt(max(1, text.length - 10));
            end = start + 3 + random.nextInt(min(10, text.length - start - 3));
            
            // Check if this range overlaps with any existing range
            bool overlaps = false;
            for (final range in usedRanges) {
              if ((start >= range.$1 && start < range.$2) ||
                  (end > range.$1 && end <= range.$2) ||
                  (start <= range.$1 && end >= range.$2)) {
                overlaps = true;
                break;
              }
            }
            
            if (!overlaps && end <= text.length) {
              foundRange = true;
            }
            attempts++;
          }
          
          if (!foundRange) {
            continue; // Skip this formatting if we couldn't find a non-overlapping range
          }
          
          usedRanges.add((start, end));
          final attribution = _getRandomInlineAttribution(random);
          
          node.text.addAttribution(
            attribution,
            SpanRange(start, end - 1),
          );
          
          appliedFormatting.add((start, end, attribution));
        }
        
        // Verify formatting is present before entity update
        bool hasAnyFormatting = false;
        for (final (start, end, attribution) in appliedFormatting) {
          for (int pos = start; pos < end; pos++) {
            final attributions = node.text.getAllAttributionsAt(pos);
            
            if (_hasMatchingAttribution(attributions, attribution)) {
              hasAnyFormatting = true;
            }
          }
        }
        
        expect(
          hasAnyFormatting,
          isTrue,
          reason: 'Should have some formatting before entity update (iteration $i)',
        );
        
        // Create a mock entity recognizer that will return some entities
        final entities = _generateRandomEntities(text, random, count: 2 + random.nextInt(3));
        final recognizer = MockEntityRecognizer(entities);
        
        // Create entity attribution service and apply entity attributions
        final service = EntityAttributionService(recognizer);
        service.applyEntityAttributions(node);
        
        // Verify all formatting attributions are still present after entity update
        for (final (start, end, attribution) in appliedFormatting) {
          for (int pos = start; pos < end; pos++) {
            final attributions = node.text.getAllAttributionsAt(pos);
            
            expect(
              _hasMatchingAttribution(attributions, attribution),
              isTrue,
              reason: 'Formatting should be preserved at position $pos after entity update (iteration $i)',
            );
          }
        }
        
        // Verify entity attributions were added
        for (final entity in entities) {
          for (int pos = entity.startOffset; pos < entity.endOffset; pos++) {
            final attributions = node.text.getAllAttributionsAt(pos);
            
            expect(
              attributions.any((a) => a is EntityAttribution && a.entity.name == entity.name),
              isTrue,
              reason: 'Entity "${entity.name}" should be present at position $pos (iteration $i)',
            );
          }
        }
        
        // Verify text content is unchanged
        expect(
          node.text.text,
          equals(text),
          reason: 'Text content should be unchanged (iteration $i)',
        );
      }
    });
    
    test('multiple entity updates preserve formatting', () {
      final random = Random(61);
      
      for (int i = 0; i < 50; i++) {
        final text = _generateRandomText(random, minLength: 40, maxLength: 80);
        
        final attributedText = AttributedText(text);
        final node = ParagraphNode(
          id: 'node1',
          text: attributedText,
        );
        
        // Apply comprehensive formatting to the entire text
        node.text.addAttribution(boldAttribution, SpanRange(0, text.length - 1));
        
        // Apply italic to first half
        final midpoint = text.length ~/ 2;
        node.text.addAttribution(italicsAttribution, SpanRange(0, midpoint - 1));
        
        // Apply underline to second half
        node.text.addAttribution(underlineAttribution, SpanRange(midpoint, text.length - 1));
        
        // Apply color to a section
        final colorStart = text.length ~/ 4;
        final colorEnd = (text.length * 3) ~/ 4;
        final textColor = ColorAttribution(Color(random.nextInt(0xFFFFFF) + 0xFF000000));
        node.text.addAttribution(textColor, SpanRange(colorStart, colorEnd - 1));
        
        // First entity update
        final entities1 = _generateRandomEntities(text, random, count: 2);
        final recognizer1 = MockEntityRecognizer(entities1);
        final service1 = EntityAttributionService(recognizer1);
        service1.applyEntityAttributions(node);
        
        // Verify formatting is preserved after first update
        for (int pos = 0; pos < text.length; pos++) {
          final attributions = node.text.getAllAttributionsAt(pos);
          
          expect(
            attributions.contains(boldAttribution),
            isTrue,
            reason: 'Bold should be preserved at position $pos after first update (iteration $i)',
          );
          
          if (pos < midpoint) {
            expect(
              attributions.contains(italicsAttribution),
              isTrue,
              reason: 'Italic should be preserved at position $pos after first update (iteration $i)',
            );
          }
          
          if (pos >= midpoint) {
            expect(
              attributions.contains(underlineAttribution),
              isTrue,
              reason: 'Underline should be preserved at position $pos after first update (iteration $i)',
            );
          }
          
          if (pos >= colorStart && pos < colorEnd) {
            expect(
              attributions.any((a) => a is ColorAttribution),
              isTrue,
              reason: 'Color should be preserved at position $pos after first update (iteration $i)',
            );
          }
        }
        
        // Second entity update with different entities
        final entities2 = _generateRandomEntities(text, random, count: 3);
        final recognizer2 = MockEntityRecognizer(entities2);
        final service2 = EntityAttributionService(recognizer2);
        service2.applyEntityAttributions(node);
        
        // Verify formatting is still preserved after second update
        for (int pos = 0; pos < text.length; pos++) {
          final attributions = node.text.getAllAttributionsAt(pos);
          
          expect(
            attributions.contains(boldAttribution),
            isTrue,
            reason: 'Bold should be preserved at position $pos after second update (iteration $i)',
          );
          
          if (pos < midpoint) {
            expect(
              attributions.contains(italicsAttribution),
              isTrue,
              reason: 'Italic should be preserved at position $pos after second update (iteration $i)',
            );
          }
          
          if (pos >= midpoint) {
            expect(
              attributions.contains(underlineAttribution),
              isTrue,
              reason: 'Underline should be preserved at position $pos after second update (iteration $i)',
            );
          }
          
          if (pos >= colorStart && pos < colorEnd) {
            expect(
              attributions.any((a) => a is ColorAttribution),
              isTrue,
              reason: 'Color should be preserved at position $pos after second update (iteration $i)',
            );
          }
        }
        
        // Verify new entities are present
        for (final entity in entities2) {
          for (int pos = entity.startOffset; pos < entity.endOffset; pos++) {
            final attributions = node.text.getAllAttributionsAt(pos);
            
            expect(
              attributions.any((a) => a is EntityAttribution && a.entity.name == entity.name),
              isTrue,
              reason: 'New entity "${entity.name}" should be present at position $pos (iteration $i)',
            );
          }
        }
        
        // Note: Old entities being replaced is expected behavior
        // The entity attribution service removes old entity attributions before applying new ones
        // This is correct - we just need to verify formatting is preserved
      }
    });
    
    test('entity updates with overlapping formatting and entities', () {
      final random = Random(62);
      
      for (int i = 0; i < 50; i++) {
        final text = _generateRandomText(random, minLength: 50, maxLength: 100);
        
        final attributedText = AttributedText(text);
        final node = ParagraphNode(
          id: 'node1',
          text: attributedText,
        );
        
        // Apply various formatting styles that will overlap with entities
        final formattingRanges = <(int, int, Attribution)>[
          (0, text.length ~/ 3, boldAttribution),
          (text.length ~/ 4, (text.length * 3) ~/ 4, italicsAttribution),
          ((text.length * 2) ~/ 3, text.length, underlineAttribution),
        ];
        
        for (final (start, end, attribution) in formattingRanges) {
          node.text.addAttribution(attribution, SpanRange(start, end - 1));
        }
        
        // Add font size to middle section
        final fontSizeStart = text.length ~/ 3;
        final fontSizeEnd = (text.length * 2) ~/ 3;
        final fontSize = FontSizeAttribution(16.0 + random.nextDouble() * 24.0);
        node.text.addAttribution(fontSize, SpanRange(fontSizeStart, fontSizeEnd - 1));
        
        // Generate entities that will overlap with formatting
        final entities = _generateRandomEntities(text, random, count: 3);
        final recognizer = MockEntityRecognizer(entities);
        
        // Apply entity attributions
        final service = EntityAttributionService(recognizer);
        service.applyEntityAttributions(node);
        
        // Verify all formatting is preserved
        for (final (start, end, attribution) in formattingRanges) {
          for (int pos = start; pos < end; pos++) {
            final attributions = node.text.getAllAttributionsAt(pos);
            
            expect(
              attributions.contains(attribution),
              isTrue,
              reason: 'Formatting should be preserved at position $pos with overlapping entities (iteration $i)',
            );
          }
        }
        
        // Verify font size is preserved
        for (int pos = fontSizeStart; pos < fontSizeEnd; pos++) {
          final attributions = node.text.getAllAttributionsAt(pos);
          
          expect(
            attributions.any((a) => a is FontSizeAttribution),
            isTrue,
            reason: 'Font size should be preserved at position $pos (iteration $i)',
          );
        }
        
        // Verify entities are present
        for (final entity in entities) {
          for (int pos = entity.startOffset; pos < entity.endOffset; pos++) {
            final attributions = node.text.getAllAttributionsAt(pos);
            
            expect(
              attributions.any((a) => a is EntityAttribution && a.entity.name == entity.name),
              isTrue,
              reason: 'Entity "${entity.name}" should be present at position $pos (iteration $i)',
            );
          }
        }
        
        // Verify both formatting and entities coexist at overlapping positions
        for (final entity in entities) {
          for (int pos = entity.startOffset; pos < entity.endOffset; pos++) {
            final attributions = node.text.getAllAttributionsAt(pos);
            
            final hasEntity = attributions.any((a) => a is EntityAttribution);
            final hasFormatting = attributions.any((a) => _isInlineStyleAttribution(a));
            
            // At least one should be true (entity is guaranteed, formatting depends on overlap)
            expect(
              hasEntity,
              isTrue,
              reason: 'Entity should be present at position $pos (iteration $i)',
            );
            
            // If this position had formatting before, it should still have it
            bool shouldHaveFormatting = false;
            for (final (start, end, _) in formattingRanges) {
              if (pos >= start && pos < end) {
                shouldHaveFormatting = true;
                break;
              }
            }
            if (pos >= fontSizeStart && pos < fontSizeEnd) {
              shouldHaveFormatting = true;
            }
            
            if (shouldHaveFormatting) {
              expect(
                hasFormatting,
                isTrue,
                reason: 'Formatting should coexist with entity at position $pos (iteration $i)',
              );
            }
          }
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

/// Check if a set of attributions contains a matching attribution
bool _hasMatchingAttribution(Set<Attribution> attributions, Attribution target) {
  if (target == boldAttribution) {
    return attributions.contains(boldAttribution);
  } else if (target == italicsAttribution) {
    return attributions.contains(italicsAttribution);
  } else if (target == underlineAttribution) {
    return attributions.contains(underlineAttribution);
  } else if (target == strikethroughAttribution) {
    return attributions.contains(strikethroughAttribution);
  } else if (target is ColorAttribution) {
    return attributions.any((a) => a is ColorAttribution && a.color == target.color);
  } else if (target is BackgroundColorAttribution) {
    return attributions.any((a) => a is BackgroundColorAttribution && a.color == target.color);
  } else if (target is FontSizeAttribution) {
    return attributions.any((a) => a is FontSizeAttribution && a.fontSize == target.fontSize);
  }
  return false;
}

/// Generate random entities within the text
List<Entity> _generateRandomEntities(String text, Random random, {required int count}) {
  final entities = <Entity>[];
  final usedRanges = <(int, int)>[];
  
  for (int i = 0; i < count; i++) {
    // Try to find a non-overlapping range
    int attempts = 0;
    int entityStart = 0;
    int entityEnd = 0;
    bool foundRange = false;
    
    while (attempts < 20 && !foundRange) {
      entityStart = random.nextInt(max(1, text.length - 10));
      entityEnd = entityStart + 3 + random.nextInt(min(8, text.length - entityStart - 3));
      
      // Check if this range overlaps with any existing entity
      bool overlaps = false;
      for (final range in usedRanges) {
        if ((entityStart >= range.$1 && entityStart < range.$2) ||
            (entityEnd > range.$1 && entityEnd <= range.$2) ||
            (entityStart <= range.$1 && entityEnd >= range.$2)) {
          overlaps = true;
          break;
        }
      }
      
      if (!overlaps && entityEnd <= text.length) {
        foundRange = true;
      }
      attempts++;
    }
    
    if (!foundRange) {
      continue; // Skip this entity if we couldn't find a non-overlapping range
    }
    
    usedRanges.add((entityStart, entityEnd));
    final entityName = text.substring(entityStart, entityEnd);
    
    final entity = Entity(
      name: entityName,
      type: EntityType.values[random.nextInt(EntityType.values.length)],
      recognized: random.nextBool(),
      startOffset: entityStart,
      endOffset: entityEnd,
    );
    
    entities.add(entity);
  }
  
  return entities;
}

/// Mock entity recognizer for testing
class MockEntityRecognizer implements EntityRecognizer {
  final List<Entity> entities;
  
  MockEntityRecognizer(this.entities);
  
  @override
  List<Entity> recognizeEntities(String text) {
    return entities;
  }
}

