/// Property test for clear formatting preserves entities
/// 
/// Feature: rich-text-styling, Property 24: Clear formatting preserves entities
/// Validates: Requirements 12.4
/// 
/// This test verifies that clearing formatting removes only formatting
/// attributions while preserving entity attributions.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'package:plot_engine/services/entity_attribution_service.dart';
import 'package:plot_engine/models/entity.dart';
import 'package:plot_engine/models/entity_type.dart';
import 'dart:math';

void main() {
  group('Property 24: Clear formatting preserves entities', () {
    test('clearing formatting preserves entity attributions', () {
      final random = Random(50);
      
      // Run 100 iterations with random inputs
      for (int i = 0; i < 100; i++) {
        // Generate random text (at least 20 characters to have space for entities)
        final text = _generateRandomText(random, minLength: 20, maxLength: 100);
        
        // Create a paragraph node with the text
        final attributedText = AttributedText(text);
        final node = ParagraphNode(
          id: 'node1',
          text: attributedText,
        );
        
        // Generate random entity within the text
        final entityStart = random.nextInt(text.length - 5);
        final entityEnd = entityStart + 3 + random.nextInt(min(10, text.length - entityStart - 3));
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
        
        // Apply random formatting styles that overlap with the entity
        final numStyles = random.nextInt(3) + 1;
        for (int j = 0; j < numStyles; j++) {
          final start = max(0, entityStart - random.nextInt(5));
          final end = min(text.length, entityEnd + random.nextInt(5));
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
        
        // Verify both entity and formatting attributions are present
        bool hadFormatting = false;
        for (int pos = entityStart; pos < entityEnd; pos++) {
          final attributions = node.text.getAllAttributionsAt(pos);
          
          // Check entity is present
          expect(
            attributions.any((a) => a is EntityAttribution && a.entity.name == entityName),
            isTrue,
            reason: 'Entity should be present at position $pos before clearing (iteration $i)',
          );
          
          // Check formatting is present
          if (attributions.any((a) => _isInlineStyleAttribution(a))) {
            hadFormatting = true;
          }
        }
        
        expect(hadFormatting, isTrue, reason: 'Should have formatting before clearing (iteration $i)');
        
        // Simulate clearing formatting (remove only inline style attributions, not entity attributions)
        for (int pos = 0; pos < text.length; pos++) {
          final attributions = node.text.getAllAttributionsAt(pos);
          for (final attr in attributions) {
            if (_isInlineStyleAttribution(attr)) {
              node.text.removeAttribution(attr, SpanRange(pos, pos));
            }
          }
        }
        
        // Verify entity attributions are still present
        for (int pos = entityStart; pos < entityEnd; pos++) {
          final attributions = node.text.getAllAttributionsAt(pos);
          
          expect(
            attributions.any((a) => a is EntityAttribution && a.entity.name == entityName),
            isTrue,
            reason: 'Entity should be preserved at position $pos after clearing formatting (iteration $i)',
          );
        }
        
        // Verify formatting attributions are removed
        for (int pos = 0; pos < text.length; pos++) {
          final attributions = node.text.getAllAttributionsAt(pos);
          
          expect(
            attributions.any((a) => _isInlineStyleAttribution(a)),
            isFalse,
            reason: 'Formatting should be removed at position $pos (iteration $i)',
          );
        }
        
        // Verify text content is preserved
        expect(
          node.text.text,
          equals(text),
          reason: 'Text content should be preserved (iteration $i)',
        );
      }
    });
    
    test('clearing formatting preserves multiple entity attributions', () {
      final random = Random(51);
      
      for (int i = 0; i < 50; i++) {
        // Generate random text
        final text = _generateRandomText(random, minLength: 50, maxLength: 150);
        
        final attributedText = AttributedText(text);
        final node = ParagraphNode(
          id: 'node1',
          text: attributedText,
        );
        
        // Add multiple non-overlapping entities
        final numEntities = 2 + random.nextInt(3);
        final entities = <Entity>[];
        final usedRanges = <(int, int)>[];
        
        for (int j = 0; j < numEntities; j++) {
          // Try to find a non-overlapping range
          int attempts = 0;
          int entityStart = 0;
          int entityEnd = 0;
          bool foundRange = false;
          
          while (attempts < 20 && !foundRange) {
            entityStart = random.nextInt(text.length - 10);
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
            
            if (!overlaps) {
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
          
          // Apply entity attribution
          final entityAttribution = EntityAttribution(entity);
          node.text.addAttribution(
            entityAttribution,
            SpanRange(entityStart, entityEnd - 1),
          );
        }
        
        // Apply formatting to entire text
        node.text.addAttribution(boldAttribution, SpanRange(0, text.length - 1));
        node.text.addAttribution(italicsAttribution, SpanRange(0, text.length - 1));
        
        // Simulate clearing formatting
        for (int pos = 0; pos < text.length; pos++) {
          final attributions = node.text.getAllAttributionsAt(pos);
          for (final attr in attributions) {
            if (_isInlineStyleAttribution(attr)) {
              node.text.removeAttribution(attr, SpanRange(pos, pos));
            }
          }
        }
        
        // Verify all entities are preserved
        for (final entity in entities) {
          for (int pos = entity.startOffset; pos < entity.endOffset; pos++) {
            final attributions = node.text.getAllAttributionsAt(pos);
            
            expect(
              attributions.any((a) => a is EntityAttribution && a.entity.name == entity.name),
              isTrue,
              reason: 'Entity "${entity.name}" should be preserved at position $pos (iteration $i)',
            );
          }
        }
        
        // Verify formatting is removed
        for (int pos = 0; pos < text.length; pos++) {
          final attributions = node.text.getAllAttributionsAt(pos);
          
          expect(
            attributions.contains(boldAttribution),
            isFalse,
            reason: 'Bold should be removed at position $pos (iteration $i)',
          );
          
          expect(
            attributions.contains(italicsAttribution),
            isFalse,
            reason: 'Italic should be removed at position $pos (iteration $i)',
          );
        }
      }
    });
    
    test('clearing formatting with overlapping entities and formatting', () {
      final random = Random(52);
      
      for (int i = 0; i < 50; i++) {
        final text = _generateRandomText(random, minLength: 30, maxLength: 80);
        
        final attributedText = AttributedText(text);
        final node = ParagraphNode(
          id: 'node1',
          text: attributedText,
        );
        
        // Add entity in the middle
        final entityStart = text.length ~/ 3;
        final entityEnd = entityStart + 10;
        final entityName = text.substring(entityStart, entityEnd);
        
        final entity = Entity(
          name: entityName,
          type: EntityType.character,
          recognized: true,
          startOffset: entityStart,
          endOffset: entityEnd,
        );
        
        final entityAttribution = EntityAttribution(entity);
        node.text.addAttribution(
          entityAttribution,
          SpanRange(entityStart, entityEnd - 1),
        );
        
        // Add formatting that partially overlaps with entity
        // Before entity
        node.text.addAttribution(boldAttribution, SpanRange(0, entityStart + 5));
        // After entity
        node.text.addAttribution(italicsAttribution, SpanRange(entityEnd - 5, text.length - 1));
        // Spanning entity
        node.text.addAttribution(underlineAttribution, SpanRange(entityStart - 5, entityEnd + 5));
        
        // Simulate clearing formatting
        for (int pos = 0; pos < text.length; pos++) {
          final attributions = node.text.getAllAttributionsAt(pos);
          for (final attr in attributions) {
            if (_isInlineStyleAttribution(attr)) {
              node.text.removeAttribution(attr, SpanRange(pos, pos));
            }
          }
        }
        
        // Verify entity is preserved
        for (int pos = entityStart; pos < entityEnd; pos++) {
          final attributions = node.text.getAllAttributionsAt(pos);
          
          expect(
            attributions.any((a) => a is EntityAttribution && a.entity.name == entityName),
            isTrue,
            reason: 'Entity should be preserved at position $pos with overlapping formatting (iteration $i)',
          );
        }
        
        // Verify all formatting is removed everywhere
        for (int pos = 0; pos < text.length; pos++) {
          final attributions = node.text.getAllAttributionsAt(pos);
          
          expect(
            attributions.any((a) => _isInlineStyleAttribution(a)),
            isFalse,
            reason: 'All formatting should be removed at position $pos (iteration $i)',
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
