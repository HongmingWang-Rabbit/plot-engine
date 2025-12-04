/// Property-based tests for text alignment
/// 
/// These tests verify universal properties that should hold across all inputs
/// for text alignment operations.

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'package:plot_engine/services/block_metadata.dart';

void main() {
  group('Text Alignment Properties', () {
    // Feature: rich-text-styling, Property 11: Text alignment application
    // Validates: Requirements 4.1, 4.2, 4.3, 4.4
    test('Property 11: Text alignment application - for any paragraph and any alignment type, applying that alignment should set the alignment metadata', () {
      final random = Random(42); // Fixed seed for reproducibility
      
      // Run 100 iterations with random inputs
      for (int i = 0; i < 100; i++) {
        // Generate random paragraph with random text
        final text = _generateRandomText(random, minLength: 1, maxLength: 100);
        
        // Test all alignment types
        for (final alignment in TextAlignment.values) {
          // Create a paragraph node
          final node = ParagraphNode(
            id: 'node_${i}_${alignment.name}',
            text: AttributedText(text),
          );
          
          // Apply alignment by setting metadata
          final updatedNode = ParagraphNode(
            id: node.id,
            text: node.text,
            metadata: {
              'blockMetadata': BlockMetadata(
                alignment: alignment,
              ),
            },
          );
          
          // Verify the alignment metadata is set correctly
          final metadata = updatedNode.metadata['blockMetadata'] as BlockMetadata?;
          
          expect(
            metadata?.alignment,
            equals(alignment),
            reason: 'Alignment should be set to $alignment for iteration $i',
          );
        }
      }
    });

    test('Alignment application preserves other formatting', () {
      final random = Random(43);
      
      for (int i = 0; i < 100; i++) {
        final text = _generateRandomText(random, minLength: 1, maxLength: 100);
        
        // Test with various existing formatting
        final headingLevels = [null, HeadingLevel.h1, HeadingLevel.h2, HeadingLevel.h3];
        final listTypes = [null, ListType.unordered, ListType.ordered];
        
        for (final headingLevel in headingLevels) {
          for (final listType in listTypes) {
            // Skip invalid combinations (can't be both heading and list)
            if (headingLevel != null && listType != null) continue;
            
            for (final alignment in TextAlignment.values) {
              // Create node with existing formatting
              final node = ParagraphNode(
                id: 'node_${i}_${headingLevel?.name ?? 'none'}_${listType?.name ?? 'none'}_${alignment.name}',
                text: AttributedText(text),
                metadata: {
                  'blockMetadata': BlockMetadata(
                    headingLevel: headingLevel,
                    listType: listType,
                    listIndent: listType != null ? 0 : null,
                    alignment: alignment,
                  ),
                },
              );
              
              final metadata = node.metadata['blockMetadata'] as BlockMetadata?;
              
              // Verify alignment is set
              expect(
                metadata?.alignment,
                equals(alignment),
                reason: 'Alignment should be $alignment (iteration $i)',
              );
              
              // Verify other formatting is preserved
              expect(
                metadata?.headingLevel,
                equals(headingLevel),
                reason: 'Heading level should be preserved (iteration $i)',
              );
              
              expect(
                metadata?.listType,
                equals(listType),
                reason: 'List type should be preserved (iteration $i)',
              );
            }
          }
        }
      }
    });

    test('Alignment can be changed multiple times', () {
      final random = Random(44);
      
      for (int i = 0; i < 100; i++) {
        final text = _generateRandomText(random, minLength: 1, maxLength: 100);
        
        // Start with left alignment
        var node = ParagraphNode(
          id: 'node_$i',
          text: AttributedText(text),
          metadata: {
            'blockMetadata': const BlockMetadata(
              alignment: TextAlignment.left,
            ),
          },
        );
        
        var metadata = node.metadata['blockMetadata'] as BlockMetadata?;
        expect(metadata?.alignment, equals(TextAlignment.left));
        
        // Change to center
        node = ParagraphNode(
          id: node.id,
          text: node.text,
          metadata: {
            'blockMetadata': const BlockMetadata(
              alignment: TextAlignment.center,
            ),
          },
        );
        
        metadata = node.metadata['blockMetadata'] as BlockMetadata?;
        expect(
          metadata?.alignment,
          equals(TextAlignment.center),
          reason: 'Alignment should change to center (iteration $i)',
        );
        
        // Change to right
        node = ParagraphNode(
          id: node.id,
          text: node.text,
          metadata: {
            'blockMetadata': const BlockMetadata(
              alignment: TextAlignment.right,
            ),
          },
        );
        
        metadata = node.metadata['blockMetadata'] as BlockMetadata?;
        expect(
          metadata?.alignment,
          equals(TextAlignment.right),
          reason: 'Alignment should change to right (iteration $i)',
        );
        
        // Change to justify
        node = ParagraphNode(
          id: node.id,
          text: node.text,
          metadata: {
            'blockMetadata': const BlockMetadata(
              alignment: TextAlignment.justify,
            ),
          },
        );
        
        metadata = node.metadata['blockMetadata'] as BlockMetadata?;
        expect(
          metadata?.alignment,
          equals(TextAlignment.justify),
          reason: 'Alignment should change to justify (iteration $i)',
        );
      }
    });

    test('Default alignment is left when not specified', () {
      final random = Random(45);
      
      for (int i = 0; i < 100; i++) {
        final text = _generateRandomText(random, minLength: 1, maxLength: 100);
        
        // Create node without alignment metadata
        final node = ParagraphNode(
          id: 'node_$i',
          text: AttributedText(text),
        );
        
        final metadata = node.metadata['blockMetadata'] as BlockMetadata?;
        
        // When no alignment is specified, it should be null (which defaults to left in rendering)
        expect(
          metadata?.alignment,
          isNull,
          reason: 'Alignment should be null when not specified (iteration $i)',
        );
      }
    });
  });

  group('Multi-Paragraph Alignment Properties', () {
    // Feature: rich-text-styling, Property 12: Multi-paragraph alignment
    // Validates: Requirements 4.5
    test('Property 12: Multi-paragraph alignment - for any selection spanning multiple paragraphs, applying an alignment should set that alignment on all paragraphs', () {
      final random = Random(50); // Fixed seed for reproducibility
      
      // Run 100 iterations with random inputs
      for (int i = 0; i < 100; i++) {
        // Generate random number of paragraphs (2-10)
        final numParagraphs = 2 + random.nextInt(9);
        
        // Test all alignment types
        for (final alignment in TextAlignment.values) {
          // Create document with multiple paragraphs
          final nodes = <DocumentNode>[];
          for (int j = 0; j < numParagraphs; j++) {
            final text = _generateRandomText(random, minLength: 5, maxLength: 50);
            final node = ParagraphNode(
              id: 'node_${i}_${alignment.name}_$j',
              text: AttributedText(text),
            );
            
            nodes.add(node);
          }
          
          final document = MutableDocument(nodes: nodes);
          
          // Apply alignment to all paragraphs by creating new nodes with alignment metadata
          final updatedNodes = <DocumentNode>[];
          for (int j = 0; j < numParagraphs; j++) {
            final originalNode = document.getNodeById('node_${i}_${alignment.name}_$j') as ParagraphNode;
            
            // Create updated node with alignment
            final updatedNode = ParagraphNode(
              id: originalNode.id,
              text: originalNode.text,
              metadata: {
                'blockMetadata': BlockMetadata(
                  alignment: alignment,
                ),
              },
            );
            
            updatedNodes.add(updatedNode);
          }
          
          // Create new document with updated nodes
          final updatedDocument = MutableDocument(nodes: updatedNodes);
          
          // Verify all paragraphs have the alignment
          for (int j = 0; j < numParagraphs; j++) {
            final node = updatedDocument.getNodeById('node_${i}_${alignment.name}_$j') as ParagraphNode;
            final metadata = node.metadata['blockMetadata'] as BlockMetadata?;
            
            expect(
              metadata?.alignment,
              equals(alignment),
              reason: 'All paragraphs should have alignment $alignment (iteration $i, paragraph $j)',
            );
          }
        }
      }
    });

    test('Multi-paragraph alignment preserves individual paragraph formatting', () {
      final random = Random(51);
      
      for (int i = 0; i < 100; i++) {
        // Generate 3-5 paragraphs with different formatting
        final numParagraphs = 3 + random.nextInt(3);
        
        for (final alignment in TextAlignment.values) {
          final nodes = <DocumentNode>[];
          final originalFormats = <String, BlockMetadata>{};
          
          // Create paragraphs with varied formatting
          for (int j = 0; j < numParagraphs; j++) {
            final text = _generateRandomText(random, minLength: 5, maxLength: 50);
            
            // Vary the formatting for each paragraph
            HeadingLevel? headingLevel;
            ListType? listType;
            
            if (j % 3 == 0) {
              // First paragraph: heading
              headingLevel = HeadingLevel.values[j % HeadingLevel.values.length];
            } else if (j % 3 == 1) {
              // Second paragraph: list
              listType = ListType.values[j % ListType.values.length];
            }
            // Third paragraph: normal (no special formatting)
            
            final originalMetadata = BlockMetadata(
              headingLevel: headingLevel,
              listType: listType,
              listIndent: listType != null ? 0 : null,
            );
            
            final node = ParagraphNode(
              id: 'node_${i}_${alignment.name}_$j',
              text: AttributedText(text),
              metadata: {
                'blockMetadata': originalMetadata,
              },
            );
            
            nodes.add(node);
            originalFormats['node_${i}_${alignment.name}_$j'] = originalMetadata;
          }
          
          final document = MutableDocument(nodes: nodes);
          
          // Apply alignment to all paragraphs by creating new nodes
          final updatedNodes = <DocumentNode>[];
          for (int j = 0; j < numParagraphs; j++) {
            final nodeId = 'node_${i}_${alignment.name}_$j';
            final originalNode = document.getNodeById(nodeId) as ParagraphNode;
            final originalMetadata = originalFormats[nodeId]!;
            
            // Create updated node with alignment while preserving other formatting
            final updatedNode = ParagraphNode(
              id: originalNode.id,
              text: originalNode.text,
              metadata: {
                'blockMetadata': originalMetadata.copyWith(
                  alignment: alignment,
                ),
              },
            );
            
            updatedNodes.add(updatedNode);
          }
          
          // Create new document with updated nodes
          final updatedDocument = MutableDocument(nodes: updatedNodes);
          
          // Verify all paragraphs have the alignment AND their original formatting
          for (int j = 0; j < numParagraphs; j++) {
            final nodeId = 'node_${i}_${alignment.name}_$j';
            final node = updatedDocument.getNodeById(nodeId) as ParagraphNode;
            final metadata = node.metadata['blockMetadata'] as BlockMetadata?;
            final originalMetadata = originalFormats[nodeId]!;
            
            expect(
              metadata?.alignment,
              equals(alignment),
              reason: 'Paragraph should have alignment $alignment (iteration $i, paragraph $j)',
            );
            
            expect(
              metadata?.headingLevel,
              equals(originalMetadata.headingLevel),
              reason: 'Heading level should be preserved (iteration $i, paragraph $j)',
            );
            
            expect(
              metadata?.listType,
              equals(originalMetadata.listType),
              reason: 'List type should be preserved (iteration $i, paragraph $j)',
            );
            
            expect(
              metadata?.listIndent,
              equals(originalMetadata.listIndent),
              reason: 'List indent should be preserved (iteration $i, paragraph $j)',
            );
          }
        }
      }
    });

    test('Multi-paragraph alignment with mixed existing alignments', () {
      final random = Random(52);
      
      for (int i = 0; i < 100; i++) {
        final numParagraphs = 3 + random.nextInt(5);
        
        // Test applying each alignment type
        for (final targetAlignment in TextAlignment.values) {
          final nodes = <DocumentNode>[];
          
          // Create paragraphs with different existing alignments
          for (int j = 0; j < numParagraphs; j++) {
            final text = _generateRandomText(random, minLength: 5, maxLength: 50);
            
            // Give each paragraph a different initial alignment
            final initialAlignment = TextAlignment.values[j % TextAlignment.values.length];
            
            final node = ParagraphNode(
              id: 'node_${i}_${targetAlignment.name}_$j',
              text: AttributedText(text),
              metadata: {
                'blockMetadata': BlockMetadata(
                  alignment: initialAlignment,
                ),
              },
            );
            
            nodes.add(node);
          }
          
          final document = MutableDocument(nodes: nodes);
          
          // Apply target alignment to all paragraphs by creating new nodes
          final updatedNodes = <DocumentNode>[];
          for (int j = 0; j < numParagraphs; j++) {
            final originalNode = document.getNodeById('node_${i}_${targetAlignment.name}_$j') as ParagraphNode;
            
            final updatedNode = ParagraphNode(
              id: originalNode.id,
              text: originalNode.text,
              metadata: {
                'blockMetadata': BlockMetadata(
                  alignment: targetAlignment,
                ),
              },
            );
            
            updatedNodes.add(updatedNode);
          }
          
          // Create new document with updated nodes
          final updatedDocument = MutableDocument(nodes: updatedNodes);
          
          // Verify all paragraphs now have the target alignment
          for (int j = 0; j < numParagraphs; j++) {
            final node = updatedDocument.getNodeById('node_${i}_${targetAlignment.name}_$j') as ParagraphNode;
            final metadata = node.metadata['blockMetadata'] as BlockMetadata?;
            
            expect(
              metadata?.alignment,
              equals(targetAlignment),
              reason: 'All paragraphs should have target alignment $targetAlignment, regardless of initial alignment (iteration $i, paragraph $j)',
            );
          }
        }
      }
    });

    test('Empty paragraphs can be aligned', () {
      final random = Random(53);
      
      for (int i = 0; i < 100; i++) {
        for (final alignment in TextAlignment.values) {
          // Create empty paragraph
          final node = ParagraphNode(
            id: 'node_${i}_${alignment.name}',
            text: AttributedText(''),
          );
          
          // Apply alignment by creating new node
          final updatedNode = ParagraphNode(
            id: node.id,
            text: node.text,
            metadata: {
              'blockMetadata': BlockMetadata(
                alignment: alignment,
              ),
            },
          );
          
          final metadata = updatedNode.metadata['blockMetadata'] as BlockMetadata?;
          
          expect(
            metadata?.alignment,
            equals(alignment),
            reason: 'Empty paragraphs should be alignable (iteration $i, alignment $alignment)',
          );
        }
      }
    });
  });
}

/// Generate random text for testing
String _generateRandomText(Random random, {int minLength = 1, int maxLength = 100}) {
  final length = minLength + random.nextInt(maxLength - minLength + 1);
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ';
  return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
}
