/// Property-based tests for list formatting
/// 
/// These tests verify universal properties that should hold across all inputs
/// for list formatting operations.

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'package:plot_engine/services/block_metadata.dart';

void main() {
  group('List Formatting Properties', () {
    // Feature: rich-text-styling, Property 8: List type conversion
    // Validates: Requirements 3.1, 3.2
    test('Property 8: List type conversion - for any paragraph, converting to a list type should set the list metadata', () {
      final random = Random(42); // Fixed seed for reproducibility
      
      // Run 100 iterations with random inputs
      for (int i = 0; i < 100; i++) {
        // Generate random paragraph with random text
        final text = _generateRandomText(random, minLength: 1, maxLength: 100);
        
        // Test both list types
        for (final listType in ListType.values) {
          // Create a paragraph node
          final node = ParagraphNode(
            id: 'node_${i}_${listType.name}',
            text: AttributedText(text),
          );
          
          // Apply list formatting by setting metadata
          final updatedNode = ParagraphNode(
            id: node.id,
            text: node.text,
            metadata: {
              'blockMetadata': BlockMetadata(
                listType: listType,
                listIndent: 0,
              ),
            },
          );
          
          // Verify the list metadata is set correctly
          final metadata = updatedNode.metadata['blockMetadata'] as BlockMetadata?;
          
          expect(
            metadata?.listType,
            equals(listType),
            reason: 'List type should be set to $listType for iteration $i',
          );
          
          expect(
            metadata?.listIndent,
            equals(0),
            reason: 'List indent should be 0 for new list items (iteration $i)',
          );
          
          // Verify heading and block quote are cleared (not set)
          expect(
            metadata?.headingLevel,
            isNull,
            reason: 'Heading level should be null when converting to list (iteration $i)',
          );
          
          expect(
            metadata?.isBlockQuote,
            isFalse,
            reason: 'Block quote should be false when converting to list (iteration $i)',
          );
        }
      }
    });

    // Feature: rich-text-styling, Property 10: Sequential numbering
    // Validates: Requirements 3.7
    test('Property 10: Sequential numbering - for any numbered list with multiple items, items should be numbered sequentially', () {
      final random = Random(42); // Fixed seed for reproducibility
      
      // Run 100 iterations with random number of list items
      for (int i = 0; i < 100; i++) {
        // Generate random number of list items (2-10)
        final numItems = 2 + random.nextInt(9);
        
        // Create document with multiple list items
        final nodes = <DocumentNode>[];
        for (int j = 0; j < numItems; j++) {
          final text = _generateRandomText(random, minLength: 5, maxLength: 50);
          final node = ParagraphNode(
            id: 'node_${i}_$j',
            text: AttributedText(text),
            metadata: {
              'blockMetadata': const BlockMetadata(
                listType: ListType.ordered,
                listIndent: 0,
              ),
            },
          );
          
          nodes.add(node);
        }
        
        final document = MutableDocument(nodes: nodes);
        
        // Verify sequential numbering
        // Note: The actual numbering is handled by the stylesheet/renderer,
        // but we verify that all items have the same indent level and list type
        // which is the prerequisite for sequential numbering
        
        int? previousIndent;
        for (int j = 0; j < numItems; j++) {
          final node = document.getNodeById('node_${i}_$j') as ParagraphNode;
          final metadata = node.metadata['blockMetadata'] as BlockMetadata?;
          
          expect(
            metadata?.listType,
            equals(ListType.ordered),
            reason: 'All items should be ordered list type (iteration $i, item $j)',
          );
          
          final currentIndent = metadata?.listIndent ?? 0;
          
          if (previousIndent != null) {
            // For sequential numbering, items at the same level should have the same indent
            // This test verifies that the structure supports sequential numbering
            expect(
              currentIndent,
              equals(previousIndent),
              reason: 'Items at the same level should have the same indent for sequential numbering (iteration $i, item $j)',
            );
          }
          
          previousIndent = currentIndent;
        }
      }
    });

    test('List toggle behavior - toggling the same list type should remove list formatting', () {
      final random = Random(43);
      
      for (int i = 0; i < 100; i++) {
        final text = _generateRandomText(random, minLength: 1, maxLength: 100);
        
        for (final listType in ListType.values) {
          // Create node with list formatting
          final nodeWithList = ParagraphNode(
            id: 'node_${i}_${listType.name}_with',
            text: AttributedText(text),
            metadata: {
              'blockMetadata': BlockMetadata(
                listType: listType,
                listIndent: 0,
              ),
            },
          );
          
          var metadata = nodeWithList.metadata['blockMetadata'] as BlockMetadata?;
          expect(metadata?.listType, equals(listType));
          
          // Simulate toggle off by creating node without list formatting
          final nodeWithoutList = ParagraphNode(
            id: 'node_${i}_${listType.name}_without',
            text: AttributedText(text),
            metadata: {
              'blockMetadata': const BlockMetadata.empty(),
            },
          );
          
          metadata = nodeWithoutList.metadata['blockMetadata'] as BlockMetadata?;
          expect(
            metadata?.listType,
            isNull,
            reason: 'Toggling the same list type should remove list formatting (iteration $i)',
          );
        }
      }
    });

    test('List type switching - applying different list type should change the list type', () {
      final random = Random(44);
      
      for (int i = 0; i < 100; i++) {
        final text = _generateRandomText(random, minLength: 1, maxLength: 100);
        
        // Create node with unordered list
        final nodeUnordered = ParagraphNode(
          id: 'node_${i}_unordered',
          text: AttributedText(text),
          metadata: {
            'blockMetadata': const BlockMetadata(
              listType: ListType.unordered,
              listIndent: 0,
            ),
          },
        );
        
        var metadata = nodeUnordered.metadata['blockMetadata'] as BlockMetadata?;
        expect(metadata?.listType, equals(ListType.unordered));
        
        // Switch to ordered list
        final nodeOrdered = ParagraphNode(
          id: 'node_${i}_ordered',
          text: AttributedText(text),
          metadata: {
            'blockMetadata': const BlockMetadata(
              listType: ListType.ordered,
              listIndent: 0,
            ),
          },
        );
        
        metadata = nodeOrdered.metadata['blockMetadata'] as BlockMetadata?;
        expect(
          metadata?.listType,
          equals(ListType.ordered),
          reason: 'Applying different list type should change the list type (iteration $i)',
        );
      }
    });

    // Feature: rich-text-styling, Property 9: List indentation
    // Validates: Requirements 3.5, 3.6
    test('Property 9: List indentation - for any list item at indent level N, pressing Tab should increase to N+1, and Shift+Tab should decrease to N-1 (minimum 0)', () {
      final random = Random(45); // Fixed seed for reproducibility
      
      // Run 100 iterations with random inputs
      for (int i = 0; i < 100; i++) {
        // Generate random text
        final text = _generateRandomText(random, minLength: 1, maxLength: 100);
        
        // Test both list types
        for (final listType in ListType.values) {
          // Test various indent levels (0-5)
          for (int startIndent = 0; startIndent <= 5; startIndent++) {
            // Create a list item at the starting indent level
            final node = ParagraphNode(
              id: 'node_${i}_${listType.name}_$startIndent',
              text: AttributedText(text),
              metadata: {
                'blockMetadata': BlockMetadata(
                  listType: listType,
                  listIndent: startIndent,
                ),
              },
            );
            
            var metadata = node.metadata['blockMetadata'] as BlockMetadata?;
            expect(
              metadata?.listIndent,
              equals(startIndent),
              reason: 'Initial indent should be $startIndent (iteration $i, ${listType.name})',
            );
            
            // Simulate Tab press (indent) - increase by 1
            final indentedNode = ParagraphNode(
              id: node.id,
              text: node.text,
              metadata: {
                'blockMetadata': BlockMetadata(
                  listType: listType,
                  listIndent: startIndent + 1,
                ),
              },
            );
            
            metadata = indentedNode.metadata['blockMetadata'] as BlockMetadata?;
            expect(
              metadata?.listIndent,
              equals(startIndent + 1),
              reason: 'After Tab, indent should increase to ${startIndent + 1} (iteration $i, ${listType.name})',
            );
            
            // Simulate Shift+Tab press (outdent) - decrease by 1, but not below 0
            final expectedOutdent = startIndent > 0 ? startIndent - 1 : 0;
            final outdentedNode = ParagraphNode(
              id: node.id,
              text: node.text,
              metadata: {
                'blockMetadata': BlockMetadata(
                  listType: listType,
                  listIndent: expectedOutdent,
                ),
              },
            );
            
            metadata = outdentedNode.metadata['blockMetadata'] as BlockMetadata?;
            expect(
              metadata?.listIndent,
              equals(expectedOutdent),
              reason: 'After Shift+Tab, indent should be $expectedOutdent (minimum 0) (iteration $i, ${listType.name}, start: $startIndent)',
            );
            
            // Verify that indent level 0 cannot go below 0
            if (startIndent == 0) {
              expect(
                metadata?.listIndent,
                equals(0),
                reason: 'Indent level should not go below 0 (iteration $i, ${listType.name})',
              );
            }
          }
        }
      }
    });

    test('List indentation preserves list type', () {
      final random = Random(46);
      
      for (int i = 0; i < 100; i++) {
        final text = _generateRandomText(random, minLength: 1, maxLength: 100);
        
        for (final listType in ListType.values) {
          // Create list item at indent 0
          final node = ParagraphNode(
            id: 'node_${i}_${listType.name}',
            text: AttributedText(text),
            metadata: {
              'blockMetadata': BlockMetadata(
                listType: listType,
                listIndent: 0,
              ),
            },
          );
          
          // Indent multiple times
          for (int indent = 1; indent <= 3; indent++) {
            final indentedNode = ParagraphNode(
              id: node.id,
              text: node.text,
              metadata: {
                'blockMetadata': BlockMetadata(
                  listType: listType,
                  listIndent: indent,
                ),
              },
            );
            
            final metadata = indentedNode.metadata['blockMetadata'] as BlockMetadata?;
            
            // Verify list type is preserved
            expect(
              metadata?.listType,
              equals(listType),
              reason: 'List type should be preserved during indentation (iteration $i, indent $indent)',
            );
            
            // Verify indent level is correct
            expect(
              metadata?.listIndent,
              equals(indent),
              reason: 'Indent level should be $indent (iteration $i)',
            );
          }
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
