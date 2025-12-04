/// Service for handling clipboard operations with formatting preservation
library;

import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart';
import 'formatted_content_serializer.dart';

/// Service for clipboard operations that preserve formatting
class ClipboardService {
  /// Custom MIME type for formatted content
  static const String _formattedContentMimeType = 'application/x-plotengine-formatted';
  
  /// Copy selected text with formatting to clipboard
  static Future<void> copyWithFormatting({
    required Document document,
    required DocumentSelection selection,
  }) async {
    if (selection.isCollapsed) {
      return; // Nothing to copy
    }

    // Get selected nodes
    final selectedNodes = document.getNodesInside(selection.base, selection.extent);
    if (selectedNodes.isEmpty) {
      return;
    }

    // Extract text and formatting from selection
    final extractedNodes = <DocumentNode>[];
    
    for (final node in selectedNodes) {
      if (node is TextNode) {
        // Determine the range within this node
        final nodeSelection = _getNodeSelection(node, selection, document);
        if (nodeSelection == null) continue;
        
        // Extract the text content
        final plainText = node.text.toPlainText().substring(
          nodeSelection.start,
          nodeSelection.end + 1,
        );
        
        // Create new attributed text with the extracted content
        final extractedText = AttributedText(plainText);
        
        // Copy attributions that fall within the selection range
        final attributions = node.text.getAttributionSpansInRange(
          attributionFilter: (_) => true,
          range: nodeSelection,
        );
        
        for (final span in attributions) {
          // Adjust span positions relative to the extracted text
          final newStart = max(0, span.start - nodeSelection.start);
          final newEnd = min(plainText.length - 1, span.end - nodeSelection.start);
          
          // Only add if the range is valid
          if (newStart <= newEnd && newEnd < plainText.length) {
            extractedText.addAttribution(
              span.attribution,
              SpanRange(newStart, newEnd),
            );
          }
        }
        
        // Create a new node with the extracted content
        final newNode = ParagraphNode(
          id: node.id,
          text: extractedText,
          metadata: Map.from(node.metadata),
        );
        
        extractedNodes.add(newNode);
      } else {
        // For non-text nodes (like horizontal rules), copy the whole node
        extractedNodes.add(node);
      }
    }

    // Serialize to JSON for formatted content
    final formattedJson = FormattedContentSerializer.serializeNodes(extractedNodes);
    final formattedString = jsonEncode(formattedJson);

    // Get plain text version
    final plainText = _extractPlainText(extractedNodes);

    // Copy both formats to clipboard
    await Clipboard.setData(ClipboardData(text: plainText));
    
    // Note: Flutter's Clipboard API doesn't support multiple MIME types directly
    // We'll store formatted content in a special format that we can detect on paste
    // Format: PLOTENGINE_FORMATTED:{json}
    final combinedData = 'PLOTENGINE_FORMATTED:$formattedString';
    await Clipboard.setData(ClipboardData(text: combinedData));
  }

  /// Paste content from clipboard, restoring formatting if available
  static Future<List<DocumentNode>?> pasteWithFormatting() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData == null || clipboardData.text == null) {
      return null;
    }

    final text = clipboardData.text!;

    // Check if this is our formatted content
    if (text.startsWith('PLOTENGINE_FORMATTED:')) {
      try {
        final jsonString = text.substring('PLOTENGINE_FORMATTED:'.length);
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return FormattedContentSerializer.deserializeNodes(json);
      } catch (e) {
        print('[ClipboardService] Failed to parse formatted content: $e');
        // Fall through to plain text handling
      }
    }

    // Plain text - create simple paragraph nodes
    return createNodesFromPlainText(text);
  }

  /// Extract plain text from nodes
  static String _extractPlainText(List<DocumentNode> nodes) {
    final buffer = StringBuffer();
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      if (node is TextNode) {
        buffer.write(node.text.toPlainText());
      } else if (node is HorizontalRuleNode) {
        buffer.write('---');
      }
      if (i < nodes.length - 1) {
        buffer.write('\n');
      }
    }
    return buffer.toString();
  }

  /// Create document nodes from plain text
  static List<DocumentNode> createNodesFromPlainText(String text) {
    final lines = text.split('\n');
    return lines.map((line) {
      return ParagraphNode(
        id: Editor.createNodeId(),
        text: AttributedText(line),
      );
    }).toList();
  }

  /// Get the selection range within a specific node
  static SpanRange? _getNodeSelection(
    TextNode node,
    DocumentSelection selection,
    Document document,
  ) {
    int startOffset = 0;
    int endOffset = node.text.length;

    if (selection.base.nodeId == node.id) {
      startOffset = (selection.base.nodePosition as TextNodePosition).offset;
    }
    if (selection.extent.nodeId == node.id) {
      endOffset = (selection.extent.nodePosition as TextNodePosition).offset;
    }

    // Normalize the range
    if (startOffset > endOffset) {
      final temp = startOffset;
      startOffset = endOffset;
      endOffset = temp;
    }

    if (startOffset == endOffset) return null;
    return SpanRange(startOffset, endOffset - 1);
  }
}
