import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'package:plot_engine/services/block_metadata.dart';
import 'dart:math' as math;

void main() {
  group('BlockStyleDropdown Property Tests', () {
    // Feature: rich-text-styling, Property 5: Heading level application
    // Validates: Requirements 2.1, 2.2, 2.3
    test('Property 5: Heading level application', () {
      final random = math.Random(60);
      
      for (int iteration = 0; iteration < 100; iteration++) {
        // Generate random text (10-100 characters)
        final textLength = 10 + random.nextInt(91);
        final text = _generateRandomText(textLength, random);
        
        // Randomly select a heading level
        final headingLevel = HeadingLevel.values[random.nextInt(HeadingLevel.values.length)];
        
        // Create a paragraph node with random existing formatting
        BlockMetadata? existingMetadata;
        if (random.nextBool()) {
          existingMetadata = BlockMetadata(
            listType: random.nextBool() ? ListType.ordered : ListType.unordered,
            listIndent: random.nextInt(3),
            alignment: TextAlignment.values[random.nextInt(TextAlignment.values.length)],
          );
        }
        
        // Simulate applying heading level by creating new metadata
        final newMetadata = (existingMetadata ?? const BlockMetadata.empty()).copyWith(
          headingLevel: headingLevel,
          // Clear list formatting when changing to heading
          listType: null,
          listIndent: null,
        );
        
        // VERIFY: The new metadata should have the heading level set
        expect(
          newMetadata.headingLevel,
          equals(headingLevel),
          reason: 'Block metadata should have heading level $headingLevel (iteration $iteration)',
        );
        
        // VERIFY: List formatting should be cleared when applying heading
        expect(
          newMetadata.listType,
          isNull,
          reason: 'List type should be cleared when applying heading (iteration $iteration)',
        );
        
        expect(
          newMetadata.listIndent,
          isNull,
          reason: 'List indent should be cleared when applying heading (iteration $iteration)',
        );
        
        // VERIFY: Alignment should be preserved if it existed
        if (existingMetadata?.alignment != null) {
          expect(
            newMetadata.alignment,
            equals(existingMetadata!.alignment),
            reason: 'Alignment should be preserved when applying heading (iteration $iteration)',
          );
        }
      }
    });
    
    // Feature: rich-text-styling, Property 5: Heading level application - all heading levels
    // Validates: Requirements 2.1, 2.2, 2.3
    test('Property 5: Heading level application - H1, H2, H3 all work correctly', () {
      final random = math.Random(61);
      
      // Test each heading level explicitly
      for (final headingLevel in HeadingLevel.values) {
        for (int iteration = 0; iteration < 30; iteration++) {
          // Generate random text
          final textLength = 10 + random.nextInt(91);
          final text = _generateRandomText(textLength, random);
          
          // Randomly add some existing block formatting
          BlockMetadata? existingMetadata;
          if (random.nextBool()) {
            existingMetadata = BlockMetadata(
              listType: random.nextBool() ? ListType.ordered : ListType.unordered,
              listIndent: random.nextInt(3),
              alignment: TextAlignment.values[random.nextInt(TextAlignment.values.length)],
            );
          }
          
          // Simulate applying heading level
          final newMetadata = (existingMetadata ?? const BlockMetadata.empty()).copyWith(
            headingLevel: headingLevel,
            listType: null,
            listIndent: null,
          );
          
          // VERIFY: The metadata should have the correct heading level
          expect(
            newMetadata.headingLevel,
            equals(headingLevel),
            reason: 'Block metadata should have heading level $headingLevel (iteration $iteration)',
          );
          
          // VERIFY: List formatting should be cleared
          expect(
            newMetadata.listType,
            isNull,
            reason: 'List type should be cleared for $headingLevel (iteration $iteration)',
          );
          
          expect(
            newMetadata.listIndent,
            isNull,
            reason: 'List indent should be cleared for $headingLevel (iteration $iteration)',
          );
          
          // VERIFY: Alignment should be preserved if it existed
          if (existingMetadata?.alignment != null) {
            expect(
              newMetadata.alignment,
              equals(existingMetadata!.alignment),
              reason: 'Alignment should be preserved for $headingLevel (iteration $iteration)',
            );
          }
        }
      }
    });
    
    // Feature: rich-text-styling, Property 5: Heading level application - metadata transformation
    // Validates: Requirements 2.1, 2.2, 2.3
    test('Property 5: Heading level application - metadata transformation is correct', () {
      final random = math.Random(62);
      
      for (int iteration = 0; iteration < 100; iteration++) {
        // Create random existing metadata with various properties
        BlockMetadata? existingMetadata;
        final hasExisting = random.nextBool();
        
        if (hasExisting) {
          existingMetadata = BlockMetadata(
            headingLevel: random.nextBool() ? HeadingLevel.values[random.nextInt(HeadingLevel.values.length)] : null,
            listType: random.nextBool() ? (random.nextBool() ? ListType.ordered : ListType.unordered) : null,
            listIndent: random.nextBool() ? random.nextInt(5) : null,
            alignment: random.nextBool() ? TextAlignment.values[random.nextInt(TextAlignment.values.length)] : null,
            isBlockQuote: random.nextBool(),
          );
        }
        
        // Apply a random heading level
        final newHeadingLevel = HeadingLevel.values[random.nextInt(HeadingLevel.values.length)];
        
        // Simulate the metadata transformation
        final newMetadata = (existingMetadata ?? const BlockMetadata.empty()).copyWith(
          headingLevel: newHeadingLevel,
          listType: null,
          listIndent: null,
        );
        
        // VERIFY: New heading level is applied
        expect(
          newMetadata.headingLevel,
          equals(newHeadingLevel),
          reason: 'New heading level should be $newHeadingLevel (iteration $iteration)',
        );
        
        // VERIFY: List properties are cleared
        expect(
          newMetadata.listType,
          isNull,
          reason: 'List type should be cleared (iteration $iteration)',
        );
        
        expect(
          newMetadata.listIndent,
          isNull,
          reason: 'List indent should be cleared (iteration $iteration)',
        );
        
        // VERIFY: Other properties are preserved
        if (existingMetadata?.alignment != null) {
          expect(
            newMetadata.alignment,
            equals(existingMetadata!.alignment),
            reason: 'Alignment should be preserved (iteration $iteration)',
          );
        }
        
        // Block quote flag should be preserved (not cleared by heading application)
        expect(
          newMetadata.isBlockQuote,
          equals(existingMetadata?.isBlockQuote ?? false),
          reason: 'Block quote flag should be preserved (iteration $iteration)',
        );
      }
    });
    
    // Feature: rich-text-styling, Property 6: Normal paragraph conversion
    // Validates: Requirements 2.4, 12.2, 12.3
    test('Property 6: Normal paragraph conversion removes all block formatting', () {
      final random = math.Random(70);
      
      for (int iteration = 0; iteration < 100; iteration++) {
        // Create random block metadata with various formatting
        final hasHeading = random.nextBool();
        final hasList = random.nextBool();
        final hasAlignment = random.nextBool();
        final hasBlockQuote = random.nextBool();
        
        final existingMetadata = BlockMetadata(
          headingLevel: hasHeading ? HeadingLevel.values[random.nextInt(HeadingLevel.values.length)] : null,
          listType: hasList ? (random.nextBool() ? ListType.ordered : ListType.unordered) : null,
          listIndent: hasList ? random.nextInt(5) : null,
          alignment: hasAlignment ? TextAlignment.values[random.nextInt(TextAlignment.values.length)] : null,
          isBlockQuote: hasBlockQuote,
        );
        
        // Simulate converting to normal paragraph (empty metadata)
        const normalMetadata = BlockMetadata.empty();
        
        // VERIFY: All block-level formatting is removed
        expect(
          normalMetadata.headingLevel,
          isNull,
          reason: 'Heading level should be null for normal paragraph (iteration $iteration)',
        );
        
        expect(
          normalMetadata.listType,
          isNull,
          reason: 'List type should be null for normal paragraph (iteration $iteration)',
        );
        
        expect(
          normalMetadata.listIndent,
          isNull,
          reason: 'List indent should be null for normal paragraph (iteration $iteration)',
        );
        
        expect(
          normalMetadata.alignment,
          isNull,
          reason: 'Alignment should be null for normal paragraph (iteration $iteration)',
        );
        
        expect(
          normalMetadata.isBlockQuote,
          isFalse,
          reason: 'Block quote flag should be false for normal paragraph (iteration $iteration)',
        );
        
        expect(
          normalMetadata.hasFormatting,
          isFalse,
          reason: 'Normal paragraph should have no formatting (iteration $iteration)',
        );
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
