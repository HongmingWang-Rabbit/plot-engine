import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'dart:math';

import 'package:plot_engine/services/formatted_content_serializer.dart';
import 'package:plot_engine/services/block_metadata.dart';

// Feature: rich-text-styling, Property 20: Graceful deserialization
// **Validates: Requirements 10.4**

void main() {
  group('Property 20: Graceful deserialization', () {
    test('deserialization handles missing version gracefully', () {
      final random = Random(49);
      
      for (int i = 0; i < 100; i++) {
        // Create JSON without version field
        final json = _generateJsonWithoutVersion(random);
        
        // Should not throw
        final nodes = FormattedContentSerializer.deserializeDocument(json);
        
        expect(nodes, isNotEmpty, reason: 'Should return at least one node');
        expect(nodes.first, isA<ParagraphNode>());
      }
    });

    test('deserialization handles unknown version gracefully', () {
      final random = Random(50);
      
      for (int i = 0; i < 100; i++) {
        // Create JSON with unknown version
        final json = _generateJsonWithUnknownVersion(random);
        
        // Should not throw
        final nodes = FormattedContentSerializer.deserializeDocument(json);
        
        expect(nodes, isNotEmpty, reason: 'Should return at least one node');
      }
    });

    test('deserialization handles missing nodes field gracefully', () {
      for (int i = 0; i < 100; i++) {
        // Create JSON without nodes field
        final json = {'version': '1.0'};
        
        // Should not throw
        final nodes = FormattedContentSerializer.deserializeDocument(json);
        
        expect(nodes, isNotEmpty, reason: 'Should return default paragraph');
        expect(nodes.first, isA<ParagraphNode>());
      }
    });

    test('deserialization handles empty nodes array gracefully', () {
      for (int i = 0; i < 100; i++) {
        // Create JSON with empty nodes array
        final json = {
          'version': '1.0',
          'nodes': [],
        };
        
        // Should not throw
        final nodes = FormattedContentSerializer.deserializeDocument(json);
        
        expect(nodes, isNotEmpty, reason: 'Should return default paragraph');
        expect(nodes.first, isA<ParagraphNode>());
      }
    });

    test('deserialization handles missing node id gracefully', () {
      final random = Random(51);
      
      for (int i = 0; i < 100; i++) {
        // Create JSON with node missing id
        final json = {
          'version': '1.0',
          'nodes': [
            {
              'type': 'paragraph',
              'text': _generateRandomText(random),
            }
          ],
        };
        
        // Should not throw, but should skip invalid node
        final nodes = FormattedContentSerializer.deserializeDocument(json);
        
        // Should return default paragraph since the node was invalid
        expect(nodes, isNotEmpty);
      }
    });

    test('deserialization handles missing node type gracefully', () {
      final random = Random(52);
      
      for (int i = 0; i < 100; i++) {
        // Create JSON with node missing type
        final json = {
          'version': '1.0',
          'nodes': [
            {
              'id': 'node_1',
              'text': _generateRandomText(random),
            }
          ],
        };
        
        // Should not throw, but should skip invalid node
        final nodes = FormattedContentSerializer.deserializeDocument(json);
        
        expect(nodes, isNotEmpty);
      }
    });

    test('deserialization handles unknown node type gracefully', () {
      final random = Random(53);
      
      for (int i = 0; i < 100; i++) {
        // Create JSON with unknown node type
        final json = {
          'version': '1.0',
          'nodes': [
            {
              'id': 'node_1',
              'type': 'unknownType',
              'text': _generateRandomText(random),
            }
          ],
        };
        
        // Should not throw, should treat as paragraph
        final nodes = FormattedContentSerializer.deserializeDocument(json);
        
        expect(nodes, isNotEmpty);
        expect(nodes.first, isA<ParagraphNode>());
      }
    });

    test('deserialization handles missing attribution fields gracefully', () {
      final random = Random(54);
      
      for (int i = 0; i < 100; i++) {
        // Create JSON with incomplete attribution
        final json = {
          'version': '1.0',
          'nodes': [
            {
              'id': 'node_1',
              'type': 'paragraph',
              'text': _generateRandomText(random),
              'attributions': [
                {
                  'start': 0,
                  // Missing 'end' and 'type'
                }
              ],
            }
          ],
        };
        
        // Should not throw, should skip invalid attribution
        final nodes = FormattedContentSerializer.deserializeDocument(json);
        
        expect(nodes, isNotEmpty);
        expect(nodes.first, isA<ParagraphNode>());
      }
    });

    test('deserialization handles invalid attribution range gracefully', () {
      final random = Random(55);
      
      for (int i = 0; i < 100; i++) {
        final text = _generateRandomText(random);
        
        // Create JSON with out-of-bounds attribution
        final json = {
          'version': '1.0',
          'nodes': [
            {
              'id': 'node_1',
              'type': 'paragraph',
              'text': text,
              'attributions': [
                {
                  'start': 0,
                  'end': text.length + 100, // Out of bounds
                  'type': 'bold',
                }
              ],
            }
          ],
        };
        
        // Should not throw, should skip invalid attribution
        final nodes = FormattedContentSerializer.deserializeDocument(json);
        
        expect(nodes, isNotEmpty);
        expect(nodes.first, isA<ParagraphNode>());
      }
    });

    test('deserialization handles unknown attribution type gracefully', () {
      final random = Random(56);
      
      for (int i = 0; i < 100; i++) {
        final text = _generateRandomText(random);
        
        // Create JSON with unknown attribution type
        final json = {
          'version': '1.0',
          'nodes': [
            {
              'id': 'node_1',
              'type': 'paragraph',
              'text': text,
              'attributions': [
                {
                  'start': 0,
                  'end': text.length - 1,
                  'type': 'unknownAttributionType',
                }
              ],
            }
          ],
        };
        
        // Should not throw, should skip unknown attribution
        final nodes = FormattedContentSerializer.deserializeDocument(json);
        
        expect(nodes, isNotEmpty);
        expect(nodes.first, isA<ParagraphNode>());
      }
    });

    test('deserialization handles missing color value gracefully', () {
      final random = Random(57);
      
      for (int i = 0; i < 100; i++) {
        final text = _generateRandomText(random);
        
        // Create JSON with color attribution missing color value
        final json = {
          'version': '1.0',
          'nodes': [
            {
              'id': 'node_1',
              'type': 'paragraph',
              'text': text,
              'attributions': [
                {
                  'start': 0,
                  'end': text.length - 1,
                  'type': 'textColor',
                  // Missing 'color' field
                }
              ],
            }
          ],
        };
        
        // Should not throw, should skip attribution with missing data
        final nodes = FormattedContentSerializer.deserializeDocument(json);
        
        expect(nodes, isNotEmpty);
        expect(nodes.first, isA<ParagraphNode>());
      }
    });

    test('deserialization handles missing font size value gracefully', () {
      final random = Random(58);
      
      for (int i = 0; i < 100; i++) {
        final text = _generateRandomText(random);
        
        // Create JSON with font size attribution missing size value
        final json = {
          'version': '1.0',
          'nodes': [
            {
              'id': 'node_1',
              'type': 'paragraph',
              'text': text,
              'attributions': [
                {
                  'start': 0,
                  'end': text.length - 1,
                  'type': 'fontSize',
                  // Missing 'size' field
                }
              ],
            }
          ],
        };
        
        // Should not throw, should skip attribution with missing data
        final nodes = FormattedContentSerializer.deserializeDocument(json);
        
        expect(nodes, isNotEmpty);
        expect(nodes.first, isA<ParagraphNode>());
      }
    });

    test('deserialization handles malformed metadata gracefully', () {
      final random = Random(59);
      
      for (int i = 0; i < 100; i++) {
        final text = _generateRandomText(random);
        
        // Create JSON with malformed metadata
        final json = {
          'version': '1.0',
          'nodes': [
            {
              'id': 'node_1',
              'type': 'paragraph',
              'text': text,
              'metadata': {
                'headingLevel': 'invalidValue', // Should be h1, h2, or h3
                'listType': 123, // Should be string
              },
            }
          ],
        };
        
        // Should not throw, should use default metadata
        final nodes = FormattedContentSerializer.deserializeDocument(json);
        
        expect(nodes, isNotEmpty);
        expect(nodes.first, isA<ParagraphNode>());
      }
    });

    test('deserialization handles completely malformed JSON gracefully', () {
      for (int i = 0; i < 100; i++) {
        // Create completely invalid JSON structure
        final json = {
          'randomField': 'randomValue',
          'anotherField': 123,
        };
        
        // Should not throw, should return default paragraph
        final nodes = FormattedContentSerializer.deserializeDocument(json);
        
        expect(nodes, isNotEmpty);
        expect(nodes.first, isA<ParagraphNode>());
      }
    });

    test('deserialization handles mixed valid and invalid nodes gracefully', () {
      final random = Random(60);
      
      for (int i = 0; i < 100; i++) {
        // Create JSON with mix of valid and invalid nodes
        final json = {
          'version': '1.0',
          'nodes': [
            {
              'id': 'node_1',
              'type': 'paragraph',
              'text': _generateRandomText(random),
            },
            {
              // Invalid node - missing id
              'type': 'paragraph',
              'text': _generateRandomText(random),
            },
            {
              'id': 'node_3',
              'type': 'horizontalRule',
            },
            {
              // Invalid node - missing type
              'id': 'node_4',
              'text': _generateRandomText(random),
            },
          ],
        };
        
        // Should not throw, should include valid nodes and skip invalid ones
        final nodes = FormattedContentSerializer.deserializeDocument(json);
        
        expect(nodes, isNotEmpty);
        // Should have at least the valid nodes
        expect(nodes.length, greaterThanOrEqualTo(2));
      }
    });
  });
}

/// Generate JSON without version field
Map<String, dynamic> _generateJsonWithoutVersion(Random random) {
  return {
    'nodes': [
      {
        'id': 'node_1',
        'type': 'paragraph',
        'text': _generateRandomText(random),
      }
    ],
  };
}

/// Generate JSON with unknown version
Map<String, dynamic> _generateJsonWithUnknownVersion(Random random) {
  return {
    'version': '${random.nextInt(10)}.${random.nextInt(10)}',
    'nodes': [
      {
        'id': 'node_1',
        'type': 'paragraph',
        'text': _generateRandomText(random),
      }
    ],
  };
}

/// Generate random text
String _generateRandomText(Random random) {
  final length = random.nextInt(50) + 1; // 1-50 characters
  final chars = 'abcdefghijklmnopqrstuvwxyz ';
  return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
}
