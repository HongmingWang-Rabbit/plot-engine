/// Property-based test for clipboard formatting preservation
/// Feature: rich-text-styling, Property 28: Clipboard preserves formatting
/// Validates: Requirements 13.5
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart';
import 'package:plot_engine/services/clipboard_service.dart';
import 'package:plot_engine/services/formatted_content_serializer.dart';
import 'package:plot_engine/services/block_metadata.dart';
import 'dart:math';
import 'dart:convert';

// Mock clipboard data storage
String? _mockClipboardData;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Property 28: Clipboard preserves formatting', () {
    test('copying and pasting formatted text preserves all formatting', () async {
      // Mock clipboard for testing
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          // Store clipboard data in memory
          final text = methodCall.arguments['text'] as String;
          _mockClipboardData = text;
          return null;
        } else if (methodCall.method == 'Clipboard.getData') {
          // Return stored clipboard data
          return <String, dynamic>{'text': _mockClipboardData};
        }
        return null;
      });
      final random = Random(42); // Fixed seed for reproducibility
      
      // Run 100 iterations with random formatted content
      for (int i = 0; i < 100; i++) {
        // Generate random formatted document
        final originalNodes = _generateRandomFormattedNodes(random);
        
        // Create a document with these nodes
        final document = MutableDocument(nodes: originalNodes);
        
        // Select all content
        final firstNode = originalNodes.first;
        final lastNode = originalNodes.last;
        
        final selection = DocumentSelection(
          base: DocumentPosition(
            nodeId: firstNode.id,
            nodePosition: firstNode is TextNode
                ? const TextNodePosition(offset: 0)
                : firstNode.beginningPosition,
          ),
          extent: DocumentPosition(
            nodeId: lastNode.id,
            nodePosition: lastNode is TextNode
                ? TextNodePosition(offset: lastNode.text.length)
                : lastNode.endPosition,
          ),
        );
        
        // Copy with formatting
        await ClipboardService.copyWithFormatting(
          document: document,
          selection: selection,
        );
        
        // Paste with formatting
        final pastedNodes = await ClipboardService.pasteWithFormatting();
        
        // Verify pasted nodes are not null
        expect(pastedNodes, isNotNull, reason: 'Iteration $i: Pasted nodes should not be null');
        expect(pastedNodes!.length, equals(originalNodes.length),
            reason: 'Iteration $i: Should paste same number of nodes');
        
        // Verify each node's formatting is preserved
        for (int j = 0; j < originalNodes.length; j++) {
          final original = originalNodes[j];
          final pasted = pastedNodes[j];
          
          // Verify node type
          expect(pasted.runtimeType, equals(original.runtimeType),
              reason: 'Iteration $i, Node $j: Node type should be preserved');
          
          if (original is TextNode && pasted is TextNode) {
            // Verify text content
            expect(pasted.text.toPlainText(), equals(original.text.toPlainText()),
                reason: 'Iteration $i, Node $j: Text content should be preserved');
            
            // Verify inline attributions
            _verifyAttributionsMatch(original.text, pasted.text, i, j);
            
            // Verify block metadata (only for ParagraphNodes)
            if (original is ParagraphNode && pasted is ParagraphNode) {
              _verifyBlockMetadataMatch(original, pasted, i, j);
            }
          }
        }
      }
    });

    test('pasting plain text from external source creates unformatted nodes', () async {
      // This test verifies that when pasting plain text (not from our app),
      // it creates simple paragraph nodes without formatting
      
      // Note: We can't directly test external clipboard content in unit tests,
      // but we can verify the fallback behavior by testing with plain text
      
      final plainText = 'Line 1\nLine 2\nLine 3';
      final nodes = ClipboardService.createNodesFromPlainText(plainText);
      
      expect(nodes.length, equals(3));
      
      for (final node in nodes) {
        expect(node, isA<ParagraphNode>());
        final textNode = node as ParagraphNode;
        
        // Verify no formatting attributions
        final attributions = textNode.text.getAttributionSpansInRange(
          attributionFilter: (_) => true,
          range: SpanRange(0, textNode.text.length > 0 ? textNode.text.length - 1 : 0),
        );
        expect(attributions.isEmpty, isTrue,
            reason: 'Plain text should have no formatting attributions');
        
        // Verify no block metadata
        final metadata = textNode.metadata['blockMetadata'] as BlockMetadata?;
        expect(metadata == null || !metadata.hasFormatting, isTrue,
            reason: 'Plain text should have no block formatting');
      }
    });

    test('copying empty selection does nothing', () async {
      final document = MutableDocument(nodes: [
        ParagraphNode(id: 'node1', text: AttributedText('Test')),
      ]);
      
      // Collapsed selection (cursor position, no selection)
      final selection = DocumentSelection.collapsed(
        position: DocumentPosition(
          nodeId: 'node1',
          nodePosition: const TextNodePosition(offset: 2),
        ),
      );
      
      // This should not throw and should handle gracefully
      await ClipboardService.copyWithFormatting(
        document: document,
        selection: selection,
      );
      
      // No assertion needed - just verify it doesn't crash
    });
  });
}

/// Generate random formatted nodes for testing
List<DocumentNode> _generateRandomFormattedNodes(Random random) {
  final nodeCount = random.nextInt(5) + 1; // 1-5 nodes
  final nodes = <DocumentNode>[];
  
  for (int i = 0; i < nodeCount; i++) {
    // Randomly choose node type
    if (random.nextBool()) {
      // Text node with random formatting
      nodes.add(_generateRandomTextNode(random));
    } else {
      // Occasionally add a horizontal rule
      if (random.nextDouble() < 0.2) {
        nodes.add(HorizontalRuleNode(id: Editor.createNodeId()));
      } else {
        nodes.add(_generateRandomTextNode(random));
      }
    }
  }
  
  return nodes;
}

/// Generate a random text node with formatting
ParagraphNode _generateRandomTextNode(Random random) {
  final text = _generateRandomText(random);
  final attributedText = AttributedText(text);
  
  // Add random inline attributions (avoiding conflicts)
  if (text.isNotEmpty) {
    // Track which attribution types have been applied to avoid conflicts
    final appliedTypes = <Type>{};
    
    final attributionCount = random.nextInt(5); // 0-4 attributions
    for (int i = 0; i < attributionCount; i++) {
      final start = random.nextInt(text.length);
      final end = start + random.nextInt(text.length - start);
      
      if (start < end) {
        final attribution = _generateRandomAttribution(random);
        
        // Skip if we've already applied this type of attribution
        // (to avoid conflicts with ColorAttribution, FontSizeAttribution, etc.)
        if (attribution is ColorAttribution && appliedTypes.contains(ColorAttribution)) {
          continue;
        }
        if (attribution is BackgroundColorAttribution && appliedTypes.contains(BackgroundColorAttribution)) {
          continue;
        }
        if (attribution is FontSizeAttribution && appliedTypes.contains(FontSizeAttribution)) {
          continue;
        }
        
        try {
          attributedText.addAttribution(attribution, SpanRange(start, end));
          appliedTypes.add(attribution.runtimeType);
        } catch (e) {
          // Skip conflicting attributions
          continue;
        }
      }
    }
  }
  
  final node = ParagraphNode(
    id: Editor.createNodeId(),
    text: attributedText,
  );
  
  // Add random block metadata
  if (random.nextBool()) {
    node.metadata['blockMetadata'] = _generateRandomBlockMetadata(random);
  }
  
  return node;
}

/// Generate random text
String _generateRandomText(Random random) {
  final words = ['The', 'quick', 'brown', 'fox', 'jumps', 'over', 'lazy', 'dog'];
  final wordCount = random.nextInt(10) + 1; // 1-10 words
  final selectedWords = List.generate(
    wordCount,
    (_) => words[random.nextInt(words.length)],
  );
  return selectedWords.join(' ');
}

/// Generate random attribution
Attribution _generateRandomAttribution(Random random) {
  final attributionTypes = [
    boldAttribution,
    italicsAttribution,
    underlineAttribution,
    strikethroughAttribution,
    ColorAttribution(Color(0xFF000000 + random.nextInt(0xFFFFFF))),
    BackgroundColorAttribution(Color(0xFF000000 + random.nextInt(0xFFFFFF))),
    FontSizeAttribution(12.0 + random.nextInt(48).toDouble()),
  ];
  
  return attributionTypes[random.nextInt(attributionTypes.length)];
}

/// Generate random block metadata
BlockMetadata _generateRandomBlockMetadata(Random random) {
  final options = [
    BlockMetadata.empty().copyWith(headingLevel: HeadingLevel.h1),
    BlockMetadata.empty().copyWith(headingLevel: HeadingLevel.h2),
    BlockMetadata.empty().copyWith(headingLevel: HeadingLevel.h3),
    BlockMetadata.empty().copyWith(listType: ListType.unordered, listIndent: 0),
    BlockMetadata.empty().copyWith(listType: ListType.ordered, listIndent: 0),
    BlockMetadata.empty().copyWith(alignment: TextAlignment.center),
    BlockMetadata.empty().copyWith(alignment: TextAlignment.right),
    BlockMetadata.empty().copyWith(isBlockQuote: true),
  ];
  
  return options[random.nextInt(options.length)];
}

/// Verify that attributions match between original and pasted text
void _verifyAttributionsMatch(AttributedText original, AttributedText pasted, int iteration, int nodeIndex) {
  if (original.length == 0) return;
  
  // Instead of comparing span counts, verify that each character has the same attributions
  // This is more robust as it doesn't depend on how spans are represented internally
  for (int i = 0; i < original.length; i++) {
    final originalAttrs = original.getAllAttributionsAt(i);
    final pastedAttrs = pasted.getAllAttributionsAt(i);
    
    // Convert to comparable keys
    final originalKeys = originalAttrs.map(_getAttributionKey).toSet();
    final pastedKeys = pastedAttrs.map(_getAttributionKey).toSet();
    
    expect(pastedKeys, equals(originalKeys),
        reason: 'Iteration $iteration, Node $nodeIndex, Position $i: Attributions should match');
  }
}

/// Get a key for an attribution for comparison
String _getAttributionKey(Attribution attribution) {
  if (attribution == boldAttribution) return 'bold';
  if (attribution == italicsAttribution) return 'italic';
  if (attribution == underlineAttribution) return 'underline';
  if (attribution == strikethroughAttribution) return 'strikethrough';
  if (attribution is ColorAttribution) return 'color:${attribution.color.value}';
  if (attribution is BackgroundColorAttribution) return 'bg:${attribution.color.value}';
  if (attribution is FontSizeAttribution) return 'size:${attribution.fontSize}';
  return attribution.toString();
}

/// Verify block metadata matches
void _verifyBlockMetadataMatch(ParagraphNode original, ParagraphNode pasted, int iteration, int nodeIndex) {
  final originalMetadata = original.metadata['blockMetadata'] as BlockMetadata?;
  final pastedMetadata = pasted.metadata['blockMetadata'] as BlockMetadata?;
  
  if (originalMetadata == null || !originalMetadata.hasFormatting) {
    // Original has no formatting, pasted should also have none
    expect(pastedMetadata == null || !pastedMetadata.hasFormatting, isTrue,
        reason: 'Iteration $iteration, Node $nodeIndex: Both should have no block formatting');
    return;
  }
  
  // Both should have metadata
  expect(pastedMetadata, isNotNull,
      reason: 'Iteration $iteration, Node $nodeIndex: Pasted should have block metadata');
  
  // Verify each property
  expect(pastedMetadata!.headingLevel, equals(originalMetadata.headingLevel),
      reason: 'Iteration $iteration, Node $nodeIndex: Heading level should match');
  expect(pastedMetadata.listType, equals(originalMetadata.listType),
      reason: 'Iteration $iteration, Node $nodeIndex: List type should match');
  expect(pastedMetadata.listIndent, equals(originalMetadata.listIndent),
      reason: 'Iteration $iteration, Node $nodeIndex: List indent should match');
  expect(pastedMetadata.alignment, equals(originalMetadata.alignment),
      reason: 'Iteration $iteration, Node $nodeIndex: Alignment should match');
  expect(pastedMetadata.isBlockQuote, equals(originalMetadata.isBlockQuote),
      reason: 'Iteration $iteration, Node $nodeIndex: Block quote flag should match');
}
