import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'dart:math';

import 'package:plot_engine/services/formatted_content_serializer.dart';
import 'package:plot_engine/services/block_metadata.dart';
import 'package:plot_engine/services/entity_attribution_service.dart';

// Feature: rich-text-styling, Property 18: Formatting serialization completeness
// **Validates: Requirements 10.1, 10.3**

void main() {
  group('Property 18: Formatting serialization completeness', () {
    test('serialization preserves all inline attributions', () {
      final random = Random(42);
      
      for (int i = 0; i < 100; i++) {
        // Generate random document with various inline attributions
        final document = _generateRandomFormattedDocument(random);
        
        // Serialize the document
        final json = FormattedContentSerializer.serializeDocument(document);
        
        // Verify all inline attributions are present in JSON
        for (int nodeIndex = 0; nodeIndex < document.nodeCount; nodeIndex++) {
          final node = document.getNodeAt(nodeIndex);
          if (node is! ParagraphNode) continue;
          
          final nodeJson = json['nodes'][nodeIndex] as Map<String, dynamic>;
          final attributionsJson = nodeJson['attributions'] as List?;
          
          // Get all attributions from the original node
          final originalAttributions = node.text.getAttributionSpansInRange(
            attributionFilter: (_) => true,
            range: SpanRange(0, node.text.length - 1),
          );
          
          // Count serializable attributions (excluding unknown types)
          final serializableCount = originalAttributions.where((span) {
            final attr = span.attribution;
            return attr == boldAttribution ||
                attr == italicsAttribution ||
                attr == underlineAttribution ||
                attr == strikethroughAttribution ||
                attr is ColorAttribution ||
                attr is BackgroundColorAttribution ||
                attr is FontSizeAttribution ||
                attr is EntityAttribution;
          }).length;
          
          // Verify all serializable attributions are in JSON
          expect(
            attributionsJson?.length ?? 0,
            equals(serializableCount),
            reason: 'All inline attributions should be serialized',
          );
        }
      }
    });

    test('serialization preserves all block metadata', () {
      final random = Random(43);
      
      for (int i = 0; i < 100; i++) {
        // Generate random document with various block metadata
        final document = _generateRandomFormattedDocument(random);
        
        // Serialize the document
        final json = FormattedContentSerializer.serializeDocument(document);
        
        // Verify all block metadata is present in JSON
        for (int nodeIndex = 0; nodeIndex < document.nodeCount; nodeIndex++) {
          final node = document.getNodeAt(nodeIndex);
          if (node is! ParagraphNode) continue;
          
          final originalMetadata = node.metadata['blockMetadata'] as BlockMetadata?;
          final nodeJson = json['nodes'][nodeIndex] as Map<String, dynamic>;
          final metadataJson = nodeJson['metadata'] as Map<String, dynamic>?;
          
          if (originalMetadata != null && originalMetadata.hasFormatting) {
            expect(
              metadataJson,
              isNotNull,
              reason: 'Block metadata should be serialized when present',
            );
            
            // Verify specific metadata fields
            if (originalMetadata.headingLevel != null) {
              expect(metadataJson!['headingLevel'], isNotNull);
            }
            if (originalMetadata.listType != null) {
              expect(metadataJson!['listType'], isNotNull);
            }
            if (originalMetadata.listIndent != null) {
              expect(metadataJson!['listIndent'], isNotNull);
            }
            if (originalMetadata.alignment != null) {
              expect(metadataJson!['alignment'], isNotNull);
            }
            if (originalMetadata.isBlockQuote) {
              expect(metadataJson!['isBlockQuote'], isTrue);
            }
          }
        }
      }
    });

    test('serialization preserves horizontal rule nodes', () {
      final random = Random(44);
      
      for (int i = 0; i < 100; i++) {
        // Generate document with horizontal rules
        final document = _generateDocumentWithHorizontalRules(random);
        
        // Serialize the document
        final json = FormattedContentSerializer.serializeDocument(document);
        
        // Count horizontal rules in original
        int originalHrCount = 0;
        for (int nodeIndex = 0; nodeIndex < document.nodeCount; nodeIndex++) {
          if (document.getNodeAt(nodeIndex) is HorizontalRuleNode) {
            originalHrCount++;
          }
        }
        
        // Count horizontal rules in JSON
        final nodes = json['nodes'] as List;
        int serializedHrCount = 0;
        for (final nodeJson in nodes) {
          final nodeMap = nodeJson as Map<String, dynamic>;
          if (nodeMap['type'] == 'horizontalRule') {
            serializedHrCount++;
          }
        }
        
        expect(
          serializedHrCount,
          equals(originalHrCount),
          reason: 'All horizontal rules should be serialized',
        );
      }
    });
  });
}

/// Generate a random formatted document with various attributions and metadata
MutableDocument _generateRandomFormattedDocument(Random random) {
  final nodeCount = random.nextInt(5) + 1; // 1-5 nodes
  final nodes = <DocumentNode>[];
  
  for (int i = 0; i < nodeCount; i++) {
    final text = _generateRandomText(random);
    final attributedText = AttributedText(text);
    
    // Add random inline attributions (non-overlapping for same type)
    if (text.isNotEmpty) {
      // Track which ranges have which attribution types to avoid conflicts
      final usedRanges = <String, List<SpanRange>>{};
      
      final attributionCount = random.nextInt(4); // 0-3 attributions
      for (int j = 0; j < attributionCount; j++) {
        final start = random.nextInt(text.length);
        final end = start + random.nextInt(text.length - start);
        if (start < end) {
          final attribution = _generateRandomAttribution(random);
          final attributionType = _getAttributionType(attribution);
          
          // Check if this range conflicts with existing attributions of same type
          final existingRanges = usedRanges[attributionType] ?? [];
          bool hasConflict = false;
          for (final existingRange in existingRanges) {
            if (_rangesOverlap(start, end, existingRange.start, existingRange.end)) {
              hasConflict = true;
              break;
            }
          }
          
          if (!hasConflict) {
            attributedText.addAttribution(attribution, SpanRange(start, end));
            usedRanges[attributionType] = [...existingRanges, SpanRange(start, end)];
          }
        }
      }
    }
    
    final node = ParagraphNode(
      id: 'node_$i',
      text: attributedText,
    );
    
    // Add random block metadata
    if (random.nextBool()) {
      node.metadata['blockMetadata'] = _generateRandomBlockMetadata(random);
    }
    
    nodes.add(node);
  }
  
  return MutableDocument(nodes: nodes);
}

/// Check if two ranges overlap
bool _rangesOverlap(int start1, int end1, int start2, int end2) {
  return start1 <= end2 && start2 <= end1;
}

/// Get attribution type identifier for conflict detection
String _getAttributionType(Attribution attribution) {
  if (attribution == boldAttribution) return 'bold';
  if (attribution == italicsAttribution) return 'italic';
  if (attribution == underlineAttribution) return 'underline';
  if (attribution == strikethroughAttribution) return 'strikethrough';
  if (attribution is ColorAttribution) return 'textColor';
  if (attribution is BackgroundColorAttribution) return 'highlightColor';
  if (attribution is FontSizeAttribution) return 'fontSize';
  return 'unknown';
}

/// Generate a document with horizontal rules
MutableDocument _generateDocumentWithHorizontalRules(Random random) {
  final nodeCount = random.nextInt(5) + 2; // 2-6 nodes
  final nodes = <DocumentNode>[];
  
  for (int i = 0; i < nodeCount; i++) {
    if (random.nextBool() && i > 0) {
      // Add horizontal rule
      nodes.add(HorizontalRuleNode(id: 'hr_$i'));
    } else {
      // Add paragraph
      final text = _generateRandomText(random);
      nodes.add(ParagraphNode(
        id: 'node_$i',
        text: AttributedText(text),
      ));
    }
  }
  
  return MutableDocument(nodes: nodes);
}

/// Generate random text
String _generateRandomText(Random random) {
  final length = random.nextInt(50) + 1; // 1-50 characters
  final chars = 'abcdefghijklmnopqrstuvwxyz ';
  return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
}

/// Generate a random attribution
Attribution _generateRandomAttribution(Random random) {
  final types = [
    boldAttribution,
    italicsAttribution,
    underlineAttribution,
    strikethroughAttribution,
  ];
  
  final typeIndex = random.nextInt(types.length + 3); // Include color and font size
  
  if (typeIndex < types.length) {
    return types[typeIndex];
  } else if (typeIndex == types.length) {
    // Text color
    return ColorAttribution(Color(random.nextInt(0xFFFFFFFF)));
  } else if (typeIndex == types.length + 1) {
    // Highlight color
    return BackgroundColorAttribution(Color(random.nextInt(0xFFFFFFFF)));
  } else {
    // Font size
    return FontSizeAttribution(random.nextDouble() * 40 + 10); // 10-50
  }
}

/// Generate random block metadata
BlockMetadata _generateRandomBlockMetadata(Random random) {
  final hasHeading = random.nextBool();
  final hasList = !hasHeading && random.nextBool();
  final hasAlignment = random.nextBool();
  final isBlockQuote = !hasHeading && !hasList && random.nextBool();
  
  return BlockMetadata(
    headingLevel: hasHeading
        ? HeadingLevel.values[random.nextInt(HeadingLevel.values.length)]
        : null,
    listType: hasList
        ? ListType.values[random.nextInt(ListType.values.length)]
        : null,
    listIndent: hasList ? random.nextInt(3) : null,
    alignment: hasAlignment
        ? TextAlignment.values[random.nextInt(TextAlignment.values.length)]
        : null,
    isBlockQuote: isBlockQuote,
  );
}
