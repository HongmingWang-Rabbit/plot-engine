import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'dart:math';

import 'package:plot_engine/services/formatted_content_serializer.dart';
import 'package:plot_engine/services/block_metadata.dart';
import 'package:plot_engine/services/entity_attribution_service.dart';
import 'package:plot_engine/models/entity.dart';
import 'package:plot_engine/models/entity_type.dart';

// Feature: rich-text-styling, Property 19: Formatting round-trip preservation
// **Validates: Requirements 10.2**

void main() {
  group('Property 19: Formatting round-trip preservation', () {
    test('serialize then deserialize preserves all formatting', () {
      final random = Random(45);
      
      for (int i = 0; i < 100; i++) {
        // Generate random formatted document
        final originalDocument = _generateRandomFormattedDocument(random);
        
        // Serialize
        final json = FormattedContentSerializer.serializeDocument(originalDocument);
        
        // Deserialize
        final restoredNodes = FormattedContentSerializer.deserializeDocument(json);
        final restoredDocument = MutableDocument(nodes: restoredNodes);
        
        // Verify documents are equivalent
        expect(
          restoredDocument.nodeCount,
          equals(originalDocument.nodeCount),
          reason: 'Node count should be preserved',
        );
        
        // Check each node
        for (int nodeIndex = 0; nodeIndex < originalDocument.nodeCount; nodeIndex++) {
          final originalNode = originalDocument.getNodeAt(nodeIndex);
          final restoredNode = restoredDocument.getNodeAt(nodeIndex);
          
          expect(
            restoredNode.runtimeType,
            equals(originalNode.runtimeType),
            reason: 'Node type should be preserved',
          );
          
          if (originalNode is ParagraphNode && restoredNode is ParagraphNode) {
            _verifyParagraphNodesEqual(originalNode, restoredNode);
          } else if (originalNode is HorizontalRuleNode && restoredNode is HorizontalRuleNode) {
            // Horizontal rules are always equivalent
            expect(true, isTrue);
          }
        }
      }
    });

    test('round-trip preserves text content exactly', () {
      final random = Random(46);
      
      for (int i = 0; i < 100; i++) {
        final originalDocument = _generateRandomFormattedDocument(random);
        
        // Serialize and deserialize
        final json = FormattedContentSerializer.serializeDocument(originalDocument);
        final restoredNodes = FormattedContentSerializer.deserializeDocument(json);
        final restoredDocument = MutableDocument(nodes: restoredNodes);
        
        // Extract text from both documents
        final originalText = _extractDocumentText(originalDocument);
        final restoredText = _extractDocumentText(restoredDocument);
        
        expect(
          restoredText,
          equals(originalText),
          reason: 'Text content should be preserved exactly',
        );
      }
    });

    test('round-trip preserves inline attributions', () {
      final random = Random(47);
      
      for (int i = 0; i < 100; i++) {
        final originalDocument = _generateRandomFormattedDocument(random);
        
        // Serialize and deserialize
        final json = FormattedContentSerializer.serializeDocument(originalDocument);
        final restoredNodes = FormattedContentSerializer.deserializeDocument(json);
        final restoredDocument = MutableDocument(nodes: restoredNodes);
        
        // Check inline attributions for each paragraph
        for (int nodeIndex = 0; nodeIndex < originalDocument.nodeCount; nodeIndex++) {
          final originalNode = originalDocument.getNodeAt(nodeIndex);
          final restoredNode = restoredDocument.getNodeAt(nodeIndex);
          
          if (originalNode is ParagraphNode && restoredNode is ParagraphNode) {
            _verifyInlineAttributionsEqual(originalNode, restoredNode);
          }
        }
      }
    });

    test('round-trip preserves block metadata', () {
      final random = Random(48);
      
      for (int i = 0; i < 100; i++) {
        final originalDocument = _generateRandomFormattedDocument(random);
        
        // Serialize and deserialize
        final json = FormattedContentSerializer.serializeDocument(originalDocument);
        final restoredNodes = FormattedContentSerializer.deserializeDocument(json);
        final restoredDocument = MutableDocument(nodes: restoredNodes);
        
        // Check block metadata for each paragraph
        for (int nodeIndex = 0; nodeIndex < originalDocument.nodeCount; nodeIndex++) {
          final originalNode = originalDocument.getNodeAt(nodeIndex);
          final restoredNode = restoredDocument.getNodeAt(nodeIndex);
          
          if (originalNode is ParagraphNode && restoredNode is ParagraphNode) {
            _verifyBlockMetadataEqual(originalNode, restoredNode);
          }
        }
      }
    });
  });
}

/// Verify two paragraph nodes are equal
void _verifyParagraphNodesEqual(ParagraphNode original, ParagraphNode restored) {
  // Check text content
  expect(
    restored.text.toPlainText(),
    equals(original.text.toPlainText()),
    reason: 'Text content should match',
  );
  
  // Check inline attributions
  _verifyInlineAttributionsEqual(original, restored);
  
  // Check block metadata
  _verifyBlockMetadataEqual(original, restored);
}

/// Verify inline attributions are equal
void _verifyInlineAttributionsEqual(ParagraphNode original, ParagraphNode restored) {
  final originalText = original.text.toPlainText();
  final restoredText = restored.text.toPlainText();
  
  if (originalText.isEmpty || restoredText.isEmpty) return;
  
  // Instead of comparing spans directly, check that each character has the same attributions
  for (int i = 0; i < originalText.length; i++) {
    final originalAttrs = original.text.getAllAttributionsAt(i);
    final restoredAttrs = restored.text.getAllAttributionsAt(i);
    
    // Filter out entity attributions
    final originalNonEntity = originalAttrs.where((a) => a is! EntityAttribution).toSet();
    final restoredNonEntity = restoredAttrs.where((a) => a is! EntityAttribution).toSet();
    
    expect(
      restoredNonEntity.length,
      equals(originalNonEntity.length),
      reason: 'Number of attributions at position $i should match',
    );
    
    // Check each attribution type is present
    for (final originalAttr in originalNonEntity) {
      bool found = false;
      for (final restoredAttr in restoredNonEntity) {
        if (_attributionsMatch(originalAttr, restoredAttr)) {
          found = true;
          break;
        }
      }
      expect(found, isTrue, reason: 'Attribution ${originalAttr.runtimeType} should be present at position $i');
    }
  }
}

/// Check if two attributions match
bool _attributionsMatch(Attribution a, Attribution b) {
  if (a == boldAttribution && b == boldAttribution) return true;
  if (a == italicsAttribution && b == italicsAttribution) return true;
  if (a == underlineAttribution && b == underlineAttribution) return true;
  if (a == strikethroughAttribution && b == strikethroughAttribution) return true;
  if (a is ColorAttribution && b is ColorAttribution) {
    return a.color.value == b.color.value;
  }
  if (a is BackgroundColorAttribution && b is BackgroundColorAttribution) {
    return a.color.value == b.color.value;
  }
  if (a is FontSizeAttribution && b is FontSizeAttribution) {
    return a.fontSize == b.fontSize;
  }
  return false;
}

/// Verify two attributions are equal
void _verifyAttributionsEqual(Attribution original, Attribution restored) {
  if (original == boldAttribution) {
    expect(restored, equals(boldAttribution));
  } else if (original == italicsAttribution) {
    expect(restored, equals(italicsAttribution));
  } else if (original == underlineAttribution) {
    expect(restored, equals(underlineAttribution));
  } else if (original == strikethroughAttribution) {
    expect(restored, equals(strikethroughAttribution));
  } else if (original is ColorAttribution && restored is ColorAttribution) {
    expect(restored.color.value, equals(original.color.value));
  } else if (original is BackgroundColorAttribution && restored is BackgroundColorAttribution) {
    expect(restored.color.value, equals(original.color.value));
  } else if (original is FontSizeAttribution && restored is FontSizeAttribution) {
    expect(restored.fontSize, equals(original.fontSize));
  }
}

/// Verify block metadata is equal
void _verifyBlockMetadataEqual(ParagraphNode original, ParagraphNode restored) {
  final originalMetadata = original.metadata['blockMetadata'] as BlockMetadata?;
  final restoredMetadata = restored.metadata['blockMetadata'] as BlockMetadata?;
  
  if (originalMetadata == null || !originalMetadata.hasFormatting) {
    // If original has no metadata, restored should also have none or empty
    if (restoredMetadata != null) {
      expect(restoredMetadata.hasFormatting, isFalse);
    }
    return;
  }
  
  expect(restoredMetadata, isNotNull, reason: 'Metadata should be preserved');
  expect(restoredMetadata!.headingLevel, equals(originalMetadata.headingLevel));
  expect(restoredMetadata.listType, equals(originalMetadata.listType));
  expect(restoredMetadata.listIndent, equals(originalMetadata.listIndent));
  expect(restoredMetadata.alignment, equals(originalMetadata.alignment));
  expect(restoredMetadata.isBlockQuote, equals(originalMetadata.isBlockQuote));
}

/// Extract all text from a document
String _extractDocumentText(Document document) {
  final buffer = StringBuffer();
  
  for (int i = 0; i < document.nodeCount; i++) {
    final node = document.getNodeAt(i);
    if (node is ParagraphNode) {
      buffer.write(node.text.toPlainText());
      if (i < document.nodeCount - 1) {
        buffer.write('\n');
      }
    } else if (node is HorizontalRuleNode) {
      buffer.write('[HR]');
      if (i < document.nodeCount - 1) {
        buffer.write('\n');
      }
    }
  }
  
  return buffer.toString();
}

/// Generate a random formatted document with various attributions and metadata
MutableDocument _generateRandomFormattedDocument(Random random) {
  final nodeCount = random.nextInt(5) + 1; // 1-5 nodes
  final nodes = <DocumentNode>[];
  
  for (int i = 0; i < nodeCount; i++) {
    // Randomly add horizontal rule or paragraph
    if (random.nextInt(10) == 0 && i > 0) {
      nodes.add(HorizontalRuleNode(id: 'hr_$i'));
      continue;
    }
    
    final text = _generateRandomText(random);
    final attributedText = AttributedText(text);
    
    // Add random inline attributions (non-overlapping for same type)
    if (text.isNotEmpty) {
      final usedRanges = <String, List<SpanRange>>{};
      
      final attributionCount = random.nextInt(4); // 0-3 attributions
      for (int j = 0; j < attributionCount; j++) {
        final start = random.nextInt(text.length);
        final end = start + random.nextInt(text.length - start);
        if (start < end) {
          final attribution = _generateRandomAttribution(random);
          final attributionType = _getAttributionType(attribution);
          
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
  
  final typeIndex = random.nextInt(types.length + 3);
  
  if (typeIndex < types.length) {
    return types[typeIndex];
  } else if (typeIndex == types.length) {
    return ColorAttribution(Color(random.nextInt(0xFFFFFFFF)));
  } else if (typeIndex == types.length + 1) {
    return BackgroundColorAttribution(Color(random.nextInt(0xFFFFFFFF)));
  } else {
    return FontSizeAttribution(random.nextDouble() * 40 + 10);
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
