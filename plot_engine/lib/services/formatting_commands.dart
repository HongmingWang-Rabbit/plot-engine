/// Formatting commands for rich text editing
library;

import 'package:super_editor/super_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'block_metadata.dart';

/// Provider for pending inline styles (styles to be applied to next typed character)
final pendingStylesProvider = StateProvider<Set<Attribution>>((ref) => {});

// ============================================================================
// Toggle Inline Style
// ============================================================================

/// Request to toggle inline text styles
class ToggleInlineStyleRequest implements EditRequest {
  final Attribution attribution;

  const ToggleInlineStyleRequest({
    required this.attribution,
  });
}

/// Command to toggle inline text styles
class ToggleInlineStyleCommand extends EditCommand {
  final Attribution attribution;

  const ToggleInlineStyleCommand({
    required this.attribution,
  });

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final selection = context.composer.selection;
    if (selection == null) return;

    // If selection is collapsed (no text selected), we can't toggle inline style
    // The pending styles are handled separately in the UI
    if (selection.isCollapsed) {
      return;
    }

    final selectedNodes = context.document.getNodesInside(selection.base, selection.extent);
    if (selectedNodes.isEmpty) return;

    final hasAttribution = _selectionHasAttribution(context.document, selection, attribution);

    for (final node in selectedNodes) {
      if (node is! TextNode) continue;
      final nodeSelection = _getNodeSelection(node, selection, context.document);
      if (nodeSelection == null) continue;

      if (hasAttribution) {
        node.text.removeAttribution(attribution, nodeSelection);
      } else {
        node.text.addAttribution(attribution, nodeSelection);
      }
    }

    executor.logChanges([
      DocumentEdit(
        NodeChangeEvent(selection.extent.nodeId),
      ),
    ]);
  }

  bool _selectionHasAttribution(Document document, DocumentSelection selection, Attribution attribution) {
    final selectedNodes = document.getNodesInside(selection.base, selection.extent);
    for (final node in selectedNodes) {
      if (node is! TextNode) continue;
      final nodeSelection = _getNodeSelection(node, selection, document);
      if (nodeSelection == null) continue;

      final attributions = node.text.getAttributionSpansInRange(
        attributionFilter: (attr) => attr == attribution,
        range: nodeSelection,
      );

      if (attributions.isEmpty) return false;
      final fullyCovered = attributions.any((span) => span.start <= nodeSelection.start && span.end >= nodeSelection.end);
      if (!fullyCovered) return false;
    }
    return true;
  }

  SpanRange? _getNodeSelection(TextNode node, DocumentSelection selection, Document document) {
    int startOffset = 0;
    int endOffset = node.text.length;

    if (selection.base.nodeId == node.id) {
      startOffset = (selection.base.nodePosition as TextNodePosition).offset;
    }
    if (selection.extent.nodeId == node.id) {
      endOffset = (selection.extent.nodePosition as TextNodePosition).offset;
    }

    if (startOffset > endOffset) {
      final temp = startOffset;
      startOffset = endOffset;
      endOffset = temp;
    }

    if (startOffset == endOffset) return null;
    return SpanRange(startOffset, endOffset - 1);
  }
}

// ============================================================================
// Change Block Type
// ============================================================================

/// Request to change block type
class ChangeBlockTypeRequest implements EditRequest {
  final String nodeId;
  final HeadingLevel? headingLevel;
  final bool isBlockQuote;

  const ChangeBlockTypeRequest({required this.nodeId, this.headingLevel, this.isBlockQuote = false});
}

/// Command to change block type
class ChangeBlockTypeCommand extends EditCommand {
  final String nodeId;
  final HeadingLevel? headingLevel;
  final bool isBlockQuote;

  const ChangeBlockTypeCommand({required this.nodeId, this.headingLevel, this.isBlockQuote = false});

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final node = context.document.getNodeById(nodeId);
    if (node is! ParagraphNode) return;

    final existingMetadata = node.metadata['blockMetadata'] as BlockMetadata?;
    final newMetadata = (existingMetadata ?? const BlockMetadata.empty()).copyWith(
      headingLevel: headingLevel,
      isBlockQuote: isBlockQuote,
      listType: null,
      listIndent: null,
    );
    node.metadata['blockMetadata'] = newMetadata;

    executor.logChanges([
      DocumentEdit(NodeChangeEvent(nodeId)),
    ]);
  }
}

// ============================================================================
// Toggle List
// ============================================================================

/// Request to toggle list formatting
class ToggleListRequest implements EditRequest {
  final ListType listType;
  const ToggleListRequest({required this.listType});
}

/// Command to toggle list formatting
class ToggleListCommand extends EditCommand {
  final ListType listType;
  const ToggleListCommand({required this.listType});

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final selection = context.composer.selection;
    if (selection == null) return;

    final node = context.document.getNodeById(selection.extent.nodeId);
    if (node is! ParagraphNode) return;

    final existingMetadata = node.metadata['blockMetadata'] as BlockMetadata?;
    final currentListType = existingMetadata?.listType;

    BlockMetadata newMetadata;
    if (currentListType == listType) {
      newMetadata = (existingMetadata ?? const BlockMetadata.empty()).copyWith(listType: null, listIndent: null);
    } else {
      newMetadata = (existingMetadata ?? const BlockMetadata.empty()).copyWith(
        listType: listType,
        listIndent: 0,
        headingLevel: null,
        isBlockQuote: false,
      );
    }
    node.metadata['blockMetadata'] = newMetadata;

    executor.logChanges([
      DocumentEdit(NodeChangeEvent(node.id)),
    ]);
  }
}

// ============================================================================
// Set Text Alignment
// ============================================================================

/// Request to set text alignment
class SetTextAlignmentRequest implements EditRequest {
  final TextAlignment alignment;
  const SetTextAlignmentRequest({required this.alignment});
}

/// Command to set text alignment
class SetTextAlignmentCommand extends EditCommand {
  final TextAlignment alignment;
  const SetTextAlignmentCommand({required this.alignment});

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final selection = context.composer.selection;
    if (selection == null) return;

    final selectedNodes = context.document.getNodesInside(selection.base, selection.extent);
    for (final node in selectedNodes) {
      if (node is! ParagraphNode) continue;
      final existingMetadata = node.metadata['blockMetadata'] as BlockMetadata?;
      final newMetadata = (existingMetadata ?? const BlockMetadata.empty()).copyWith(alignment: alignment);
      node.metadata['blockMetadata'] = newMetadata;
    }

    executor.logChanges([
      DocumentEdit(NodeChangeEvent(selection.extent.nodeId)),
    ]);
  }
}

// ============================================================================
// Indent/Outdent List Item
// ============================================================================

/// Request to indent a list item
class IndentListItemRequest implements EditRequest {
  const IndentListItemRequest();
}

/// Command to indent a list item
class IndentListItemCommand extends EditCommand {
  const IndentListItemCommand();

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final selection = context.composer.selection;
    if (selection == null) return;

    final node = context.document.getNodeById(selection.extent.nodeId);
    if (node is! ParagraphNode) return;

    final existingMetadata = node.metadata['blockMetadata'] as BlockMetadata?;
    if (existingMetadata?.listType == null) return;

    final currentIndent = existingMetadata?.listIndent ?? 0;
    final newMetadata = existingMetadata!.copyWith(listIndent: currentIndent + 1);
    node.metadata['blockMetadata'] = newMetadata;

    executor.logChanges([
      DocumentEdit(NodeChangeEvent(node.id)),
    ]);
  }
}

/// Request to outdent a list item
class OutdentListItemRequest implements EditRequest {
  const OutdentListItemRequest();
}

/// Command to outdent a list item
class OutdentListItemCommand extends EditCommand {
  const OutdentListItemCommand();

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final selection = context.composer.selection;
    if (selection == null) return;

    final node = context.document.getNodeById(selection.extent.nodeId);
    if (node is! ParagraphNode) return;

    final existingMetadata = node.metadata['blockMetadata'] as BlockMetadata?;
    if (existingMetadata?.listType == null) return;

    final currentIndent = existingMetadata?.listIndent ?? 0;
    if (currentIndent > 0) {
      final newMetadata = existingMetadata!.copyWith(listIndent: currentIndent - 1);
      node.metadata['blockMetadata'] = newMetadata;

      executor.logChanges([
        DocumentEdit(NodeChangeEvent(node.id)),
      ]);
    }
  }
}

// ============================================================================
// Clear Formatting
// ============================================================================

/// Request to clear all formatting from selected text
class ClearFormattingRequest implements EditRequest {
  final Set<String> preserveAttributionTypes;
  const ClearFormattingRequest({this.preserveAttributionTypes = const {}});
}

/// Command to clear all formatting from selected text
class ClearFormattingCommand extends EditCommand {
  final Set<String> preserveAttributionTypes;
  const ClearFormattingCommand({this.preserveAttributionTypes = const {}});

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final selection = context.composer.selection;
    if (selection == null) return;

    if (selection.isCollapsed) {
      _clearBlockFormatting(context, selection.extent.nodeId);
      executor.logChanges([
        DocumentEdit(NodeChangeEvent(selection.extent.nodeId)),
      ]);
      return;
    }

    final selectedNodes = context.document.getNodesInside(selection.base, selection.extent);
    for (final node in selectedNodes) {
      _clearBlockFormatting(context, node.id);
      if (node is TextNode) {
        _clearInlineFormatting(node, selection, context.document);
      }
    }

    executor.logChanges([
      DocumentEdit(NodeChangeEvent(selection.extent.nodeId)),
    ]);
  }

  void _clearBlockFormatting(EditContext context, String nodeId) {
    final node = context.document.getNodeById(nodeId);
    if (node is! ParagraphNode) return;
    node.metadata['blockMetadata'] = const BlockMetadata.empty();
  }

  void _clearInlineFormatting(TextNode node, DocumentSelection selection, Document document) {
    final nodeSelection = _getNodeSelection(node, selection, document);
    if (nodeSelection == null) return;

    final allAttributions = node.text.getAttributionSpansInRange(
      attributionFilter: (_) => true,
      range: nodeSelection,
    );

    for (final span in allAttributions) {
      final attribution = span.attribution;
      bool shouldPreserve = false;
      for (final preserveType in preserveAttributionTypes) {
        if (attribution.toString().contains(preserveType)) {
          shouldPreserve = true;
          break;
        }
      }

      if (!shouldPreserve) {
        node.text.removeAttribution(attribution, SpanRange(nodeSelection.start, nodeSelection.end));
      }
    }
  }

  SpanRange? _getNodeSelection(TextNode node, DocumentSelection selection, Document document) {
    int startOffset = 0;
    int endOffset = node.text.length;

    if (selection.base.nodeId == node.id) {
      startOffset = (selection.base.nodePosition as TextNodePosition).offset;
    }
    if (selection.extent.nodeId == node.id) {
      endOffset = (selection.extent.nodePosition as TextNodePosition).offset;
    }

    if (startOffset > endOffset) {
      final temp = startOffset;
      startOffset = endOffset;
      endOffset = temp;
    }

    if (startOffset == endOffset) return null;
    return SpanRange(startOffset, endOffset - 1);
  }
}

// ============================================================================
// Custom Request Handlers
// ============================================================================

/// List of custom request handlers for formatting commands
final formattingRequestHandlers = <EditRequestHandler>[
  (editor, request) => request is ToggleInlineStyleRequest
      ? ToggleInlineStyleCommand(attribution: request.attribution)
      : null,
  (editor, request) => request is ChangeBlockTypeRequest
      ? ChangeBlockTypeCommand(
          nodeId: request.nodeId,
          headingLevel: request.headingLevel,
          isBlockQuote: request.isBlockQuote,
        )
      : null,
  (editor, request) => request is ToggleListRequest
      ? ToggleListCommand(listType: request.listType)
      : null,
  (editor, request) => request is SetTextAlignmentRequest
      ? SetTextAlignmentCommand(alignment: request.alignment)
      : null,
  (editor, request) => request is IndentListItemRequest
      ? const IndentListItemCommand()
      : null,
  (editor, request) => request is OutdentListItemRequest
      ? const OutdentListItemCommand()
      : null,
  (editor, request) => request is ClearFormattingRequest
      ? ClearFormattingCommand(preserveAttributionTypes: request.preserveAttributionTypes)
      : null,
];


