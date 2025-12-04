import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart' hide IndentListItemRequest, UnIndentListItemRequest;
import '../../services/entity_attribution_service.dart';
import '../../services/block_metadata.dart';
import '../../services/formatting_commands.dart';
import '../../services/clipboard_service.dart';

/// Configuration constants for the editor
class EditorConfig {
  EditorConfig._();

  // Document padding
  static const documentPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 8,
  );

  // Text styling
  static const double fontSize = 16.0;
  static const double lineHeight = 1.6;

  // Heading sizes
  static const double h1FontSize = 32.0;
  static const double h2FontSize = 24.0;
  static const double h3FontSize = 20.0;

  // List styling
  static const double listIndentPerLevel = 24.0;
  static const double listItemSpacing = 8.0;

  // Block quote styling
  static const double blockQuoteBorderWidth = 4.0;
  static const double blockQuotePaddingLeft = 16.0;
  static const double blockQuotePaddingVertical = 8.0;

  // Entity highlight styling
  static const double entityUnderlineThickness = 2.0;
  static const double entityUnderlineHoverThickness = 3.0;

  // Caret styling
  static const double caretWidth = 2.0;
  static const Color caretColorLight = Color(0xFFFF6B00); // Bright orange
  static const Color caretColorDark = Color(0xFF00D4FF); // Bright cyan

  // Timer intervals
  static const Duration autoSaveInterval = Duration(seconds: 5);
  static const Duration attributionUpdateInterval = Duration(seconds: 10);
}

/// Factory for creating editor stylesheets
class EditorStylesheetFactory {
  /// Creates an enhanced stylesheet for the chapter editor with formatting support
  static Stylesheet createChapterStylesheet({
    required BuildContext context,
    required bool highlightsEnabled,
    String? hoveredEntityName,
  }) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Stylesheet(
      documentPadding: EditorConfig.documentPadding,
      rules: [
        // Default paragraph style
        StyleRule(BlockSelector.all, (doc, docNode) {
          return {
            Styles.maxWidth: double.infinity,
            Styles.padding: const CascadingPadding.all(0),
            Styles.textStyle: TextStyle(
              fontSize: EditorConfig.fontSize,
              height: EditorConfig.lineHeight,
              color: textColor,
            ),
          };
        }),

        // Heading styles
        ..._createHeadingRules(context),

        // List styles
        ..._createListRules(context),

        // Block quote styles
        ..._createBlockQuoteRules(context),

        // Alignment styles
        ..._createAlignmentRules(context),
      ],
      inlineTextStyler: (attributions, existingStyle) {
        return _applyInlineFormatting(
          attributions: attributions,
          existingStyle: existingStyle,
          highlightsEnabled: highlightsEnabled,
          hoveredEntityName: hoveredEntityName,
        );
      },
    );
  }

  /// Create heading style rules (H1, H2, H3)
  /// Note: Uses BlockSelector.all with conditional styling since BlockSelector
  /// only supports String-based blockType matching, not custom metadata predicates.
  static List<StyleRule> _createHeadingRules(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return [
      // Combined heading rule - applies styles based on BlockMetadata
      StyleRule(
        BlockSelector.all,
        (doc, docNode) {
          final metadata = _getBlockMetadata(docNode);
          if (metadata == null) return {};

          switch (metadata.headingLevel) {
            case HeadingLevel.h1:
              return {
                Styles.textStyle: TextStyle(
                  fontSize: EditorConfig.h1FontSize,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                  color: textColor,
                ),
                Styles.padding: const CascadingPadding.only(top: 16, bottom: 8),
              };
            case HeadingLevel.h2:
              return {
                Styles.textStyle: TextStyle(
                  fontSize: EditorConfig.h2FontSize,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                  color: textColor,
                ),
                Styles.padding: const CascadingPadding.only(top: 12, bottom: 6),
              };
            case HeadingLevel.h3:
              return {
                Styles.textStyle: TextStyle(
                  fontSize: EditorConfig.h3FontSize,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                  color: textColor,
                ),
                Styles.padding: const CascadingPadding.only(top: 8, bottom: 4),
              };
            case null:
              return {};
          }
        },
      ),
    ];
  }

  /// Create list style rules (bullet and numbered)
  /// Note: Uses BlockSelector.all with conditional styling since BlockSelector
  /// only supports String-based blockType matching, not custom metadata predicates.
  static List<StyleRule> _createListRules(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return [
      // Combined list rule - applies styles based on BlockMetadata
      StyleRule(
        BlockSelector.all,
        (doc, docNode) {
          final metadata = _getBlockMetadata(docNode);
          if (metadata == null || metadata.listType == null) return {};

          final indent =
              (metadata.listIndent ?? 0) * EditorConfig.listIndentPerLevel;

          // Different indent for ordered vs unordered lists
          final baseIndent =
              metadata.listType == ListType.ordered ? 32.0 : 24.0;

          return {
            Styles.textStyle: TextStyle(
              fontSize: EditorConfig.fontSize,
              height: EditorConfig.lineHeight,
              color: textColor,
            ),
            Styles.padding: CascadingPadding.only(
              left: indent + baseIndent,
              top: EditorConfig.listItemSpacing / 2,
              bottom: EditorConfig.listItemSpacing / 2,
            ),
          };
        },
      ),
    ];
  }

  /// Create block quote style rules
  /// Note: Uses BlockSelector.all with conditional styling since BlockSelector
  /// only supports String-based blockType matching, not custom metadata predicates.
  static List<StyleRule> _createBlockQuoteRules(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return [
      StyleRule(
        BlockSelector.all,
        (doc, docNode) {
          final metadata = _getBlockMetadata(docNode);
          if (metadata?.isBlockQuote != true) return {};

          return {
            Styles.textStyle: TextStyle(
              fontSize: EditorConfig.fontSize,
              height: EditorConfig.lineHeight,
              color: textColor,
              fontStyle: FontStyle.italic,
            ),
            Styles.padding: CascadingPadding.only(
              left: EditorConfig.blockQuotePaddingLeft,
              top: EditorConfig.blockQuotePaddingVertical,
              bottom: EditorConfig.blockQuotePaddingVertical,
              right: 8,
            ),
          };
        },
      ),
    ];
  }

  /// Create alignment style rules
  /// Note: Uses BlockSelector.all with conditional styling since BlockSelector
  /// only supports String-based blockType matching, not custom metadata predicates.
  static List<StyleRule> _createAlignmentRules(BuildContext context) {
    return [
      // Combined alignment rule - applies styles based on BlockMetadata
      StyleRule(
        BlockSelector.all,
        (doc, docNode) {
          final metadata = _getBlockMetadata(docNode);
          if (metadata == null) return {};

          switch (metadata.alignment) {
            case TextAlignment.left:
              return {Styles.textAlign: TextAlign.left};
            case TextAlignment.center:
              return {Styles.textAlign: TextAlign.center};
            case TextAlignment.right:
              return {Styles.textAlign: TextAlign.right};
            case TextAlignment.justify:
              return {Styles.textAlign: TextAlign.justify};
            case null:
              return {};
          }
        },
      ),
    ];
  }

  /// Get block metadata from a document node
  static BlockMetadata? _getBlockMetadata(DocumentNode node) {
    final metadata = node.metadata['blockMetadata'];
    if (metadata is BlockMetadata) {
      return metadata;
    }
    return null;
  }

  /// Applies inline formatting including entity styling
  static TextStyle _applyInlineFormatting({
    required Set<Attribution> attributions,
    required TextStyle existingStyle,
    required bool highlightsEnabled,
    String? hoveredEntityName,
  }) {
    TextStyle style = existingStyle;

    // Track decorations separately to combine them
    Set<TextDecoration> decorations = {};
    Color? decorationColor;
    double? decorationThickness;

    // Apply formatting attributions
    for (final attribution in attributions) {
      // Bold
      if (attribution == boldAttribution) {
        style = style.copyWith(fontWeight: FontWeight.bold);
      }
      // Italic
      else if (attribution == italicsAttribution) {
        style = style.copyWith(fontStyle: FontStyle.italic);
      }
      // Underline
      else if (attribution == underlineAttribution) {
        decorations.add(TextDecoration.underline);
      }
      // Strikethrough
      else if (attribution == strikethroughAttribution) {
        decorations.add(TextDecoration.lineThrough);
      }
      // Text color
      else if (attribution is ColorAttribution) {
        style = style.copyWith(color: attribution.color);
      }
      // Highlight color (background)
      else if (attribution is BackgroundColorAttribution) {
        style = style.copyWith(backgroundColor: attribution.color);
      }
      // Font size
      else if (attribution is FontSizeAttribution) {
        style = style.copyWith(fontSize: attribution.fontSize);
      }
      // Entity highlighting
      else if (attribution is EntityAttribution && highlightsEnabled) {
        final entity = attribution.entity;
        final isHovered = hoveredEntityName == entity.name;

        decorations.add(TextDecoration.underline);
        decorationColor = entity.recognized
            ? Colors.green.shade600
            : Colors.orange.shade600;
        decorationThickness = isHovered
            ? EditorConfig.entityUnderlineHoverThickness
            : EditorConfig.entityUnderlineThickness;
      }
    }

    // Apply combined decorations
    if (decorations.isNotEmpty) {
      style = style.copyWith(
        decoration: TextDecoration.combine(decorations.toList()),
        decorationColor: decorationColor,
        decorationThickness: decorationThickness,
      );
    }

    return style;
  }

  /// Creates selection styles for the editor
  static SelectionStyles createSelectionStyles(BuildContext context) {
    return SelectionStyles(
      selectionColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.3),
    );
  }

  /// Creates the caret style based on current theme brightness
  static CaretStyle createCaretStyle(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return CaretStyle(
      width: EditorConfig.caretWidth,
      color: isLight
          ? EditorConfig.caretColorLight
          : EditorConfig.caretColorDark,
    );
  }

  /// Creates keyboard actions including list indentation handlers and formatting shortcuts
  static List<DocumentKeyboardAction> createKeyboardActions() {
    return [
      // Autoformat detection for horizontal rule
      _horizontalRuleAutoformatAction,

      // Horizontal rule deletion
      _deleteHorizontalRuleBackspaceAction,
      _deleteHorizontalRuleDeleteAction,

      // Clipboard operations with formatting preservation
      _copyWithFormattingKeyboardAction,
      _pasteWithFormattingKeyboardAction,

      // Formatting keyboard shortcuts
      _boldKeyboardAction,
      _italicKeyboardAction,
      _underlineKeyboardAction,
      _heading1KeyboardAction,
      _heading2KeyboardAction,
      _heading3KeyboardAction,
      _bulletListKeyboardAction,
      _numberedListKeyboardAction,
      _alignLeftKeyboardAction,
      _alignCenterKeyboardAction,
      _alignRightKeyboardAction,
      _alignJustifyKeyboardAction,
      _clearFormattingKeyboardAction,

      // Tab key - indent list item
      _indentListItemKeyboardAction,

      // Shift+Tab key - outdent list item
      _outdentListItemKeyboardAction,

      // Note: Enter key behaviors for special blocks (headings, lists, block quotes) are deferred
      // due to super_editor API limitations. The default Enter behavior is used instead.

      // Include all default keyboard actions
      ...defaultKeyboardActions,
    ];
  }
}

/// Keyboard action for autoformat detection of horizontal rule (--- + Enter)
ExecutionInstruction _horizontalRuleAutoformatAction({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent) {
    return ExecutionInstruction.continueExecution;
  }

  // Check if Enter key is pressed
  if (keyEvent.logicalKey != LogicalKeyboardKey.enter) {
    return ExecutionInstruction.continueExecution;
  }

  final selection = editContext.composer.selection;
  if (selection == null || !selection.isCollapsed) {
    return ExecutionInstruction.continueExecution;
  }

  // Get the current node
  final node = editContext.document.getNodeById(selection.extent.nodeId);
  if (node is! TextNode) {
    return ExecutionInstruction.continueExecution;
  }

  // Check if the text is exactly "---"
  final text = node.text.toPlainText();
  if (text != '---') {
    return ExecutionInstruction.continueExecution;
  }

  // Delete the "---" text and insert horizontal rule
  editContext.editor.execute([
    DeleteNodeRequest(nodeId: node.id),
  ]);

  // Insert horizontal rule
  editContext.commonOps.insertHorizontalRule();

  return ExecutionInstruction.haltExecution;
}

/// Keyboard action for indenting list items with Tab key
ExecutionInstruction _indentListItemKeyboardAction({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent) {
    return ExecutionInstruction.continueExecution;
  }

  // Check if Tab key is pressed (without Shift)
  if (keyEvent.logicalKey != LogicalKeyboardKey.tab ||
      HardwareKeyboard.instance.isShiftPressed) {
    return ExecutionInstruction.continueExecution;
  }

  final selection = editContext.composer.selection;
  if (selection == null) {
    return ExecutionInstruction.continueExecution;
  }

  // Get the node at the selection
  final node = editContext.document.getNodeById(selection.extent.nodeId);
  if (node is! ParagraphNode) {
    return ExecutionInstruction.continueExecution;
  }

  // Check if this is a list item
  final metadata = node.metadata['blockMetadata'] as BlockMetadata?;
  if (metadata?.listType == null) {
    return ExecutionInstruction.continueExecution;
  }

  // Execute indent command using custom IndentListItemRequest from formatting_commands
  // Note: We use our custom list indent system based on BlockMetadata, not super_editor's ListItemNode
  editContext.editor.execute([const IndentListItemRequest()]);

  return ExecutionInstruction.haltExecution;
}

/// Keyboard action for outdenting list items with Shift+Tab key
ExecutionInstruction _outdentListItemKeyboardAction({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent) {
    return ExecutionInstruction.continueExecution;
  }

  // Check if Shift+Tab is pressed
  if (keyEvent.logicalKey != LogicalKeyboardKey.tab ||
      !HardwareKeyboard.instance.isShiftPressed) {
    return ExecutionInstruction.continueExecution;
  }

  final selection = editContext.composer.selection;
  if (selection == null) {
    return ExecutionInstruction.continueExecution;
  }

  // Get the node at the selection
  final node = editContext.document.getNodeById(selection.extent.nodeId);
  if (node is! ParagraphNode) {
    return ExecutionInstruction.continueExecution;
  }

  // Check if this is a list item
  final metadata = node.metadata['blockMetadata'] as BlockMetadata?;
  if (metadata?.listType == null) {
    return ExecutionInstruction.continueExecution;
  }

  // Execute outdent command
  editContext.editor.execute([const OutdentListItemRequest()]);

  return ExecutionInstruction.haltExecution;
}

/// Keyboard action for bold formatting (Cmd+B / Ctrl+B)
ExecutionInstruction _boldKeyboardAction({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent) {
    return ExecutionInstruction.continueExecution;
  }

  // Check for Cmd+B (Mac) or Ctrl+B (Windows/Linux)
  final isModifierPressed =
      HardwareKeyboard.instance.isMetaPressed ||
      HardwareKeyboard.instance.isControlPressed;
  if (keyEvent.logicalKey != LogicalKeyboardKey.keyB || !isModifierPressed) {
    return ExecutionInstruction.continueExecution;
  }

  // Execute toggle bold command
  editContext.editor.execute([
    const ToggleInlineStyleRequest(attribution: boldAttribution),
  ]);

  return ExecutionInstruction.haltExecution;
}

/// Keyboard action for italic formatting (Cmd+I / Ctrl+I)
ExecutionInstruction _italicKeyboardAction({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent) {
    return ExecutionInstruction.continueExecution;
  }

  // Check for Cmd+I (Mac) or Ctrl+I (Windows/Linux)
  final isModifierPressed =
      HardwareKeyboard.instance.isMetaPressed ||
      HardwareKeyboard.instance.isControlPressed;
  if (keyEvent.logicalKey != LogicalKeyboardKey.keyI || !isModifierPressed) {
    return ExecutionInstruction.continueExecution;
  }

  // Execute toggle italic command
  editContext.editor.execute([
    const ToggleInlineStyleRequest(attribution: italicsAttribution),
  ]);

  return ExecutionInstruction.haltExecution;
}

/// Keyboard action for underline formatting (Cmd+U / Ctrl+U)
ExecutionInstruction _underlineKeyboardAction({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent) {
    return ExecutionInstruction.continueExecution;
  }

  // Check for Cmd+U (Mac) or Ctrl+U (Windows/Linux)
  final isModifierPressed =
      HardwareKeyboard.instance.isMetaPressed ||
      HardwareKeyboard.instance.isControlPressed;
  if (keyEvent.logicalKey != LogicalKeyboardKey.keyU || !isModifierPressed) {
    return ExecutionInstruction.continueExecution;
  }

  // Execute toggle underline command
  editContext.editor.execute([
    const ToggleInlineStyleRequest(attribution: underlineAttribution),
  ]);

  return ExecutionInstruction.haltExecution;
}

/// Keyboard action for Heading 1 (Cmd+Alt+1 / Ctrl+Alt+1)
ExecutionInstruction _heading1KeyboardAction({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent) {
    return ExecutionInstruction.continueExecution;
  }

  // Check for Cmd+Alt+1 (Mac) or Ctrl+Alt+1 (Windows/Linux)
  final isModifierPressed =
      HardwareKeyboard.instance.isMetaPressed ||
      HardwareKeyboard.instance.isControlPressed;
  if (keyEvent.logicalKey != LogicalKeyboardKey.digit1 ||
      !isModifierPressed ||
      !HardwareKeyboard.instance.isAltPressed) {
    return ExecutionInstruction.continueExecution;
  }

  final selection = editContext.composer.selection;
  if (selection == null) {
    return ExecutionInstruction.continueExecution;
  }

  // Execute change block type command
  editContext.editor.execute([
    ChangeBlockTypeRequest(
      nodeId: selection.extent.nodeId,
      headingLevel: HeadingLevel.h1,
    ),
  ]);

  return ExecutionInstruction.haltExecution;
}

/// Keyboard action for Heading 2 (Cmd+Alt+2 / Ctrl+Alt+2)
ExecutionInstruction _heading2KeyboardAction({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent) {
    return ExecutionInstruction.continueExecution;
  }

  // Check for Cmd+Alt+2 (Mac) or Ctrl+Alt+2 (Windows/Linux)
  final isModifierPressed =
      HardwareKeyboard.instance.isMetaPressed ||
      HardwareKeyboard.instance.isControlPressed;
  if (keyEvent.logicalKey != LogicalKeyboardKey.digit2 ||
      !isModifierPressed ||
      !HardwareKeyboard.instance.isAltPressed) {
    return ExecutionInstruction.continueExecution;
  }

  final selection = editContext.composer.selection;
  if (selection == null) {
    return ExecutionInstruction.continueExecution;
  }

  // Execute change block type command
  editContext.editor.execute([
    ChangeBlockTypeRequest(
      nodeId: selection.extent.nodeId,
      headingLevel: HeadingLevel.h2,
    ),
  ]);

  return ExecutionInstruction.haltExecution;
}

/// Keyboard action for Heading 3 (Cmd+Alt+3 / Ctrl+Alt+3)
ExecutionInstruction _heading3KeyboardAction({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent) {
    return ExecutionInstruction.continueExecution;
  }

  // Check for Cmd+Alt+3 (Mac) or Ctrl+Alt+3 (Windows/Linux)
  final isModifierPressed =
      HardwareKeyboard.instance.isMetaPressed ||
      HardwareKeyboard.instance.isControlPressed;
  if (keyEvent.logicalKey != LogicalKeyboardKey.digit3 ||
      !isModifierPressed ||
      !HardwareKeyboard.instance.isAltPressed) {
    return ExecutionInstruction.continueExecution;
  }

  final selection = editContext.composer.selection;
  if (selection == null) {
    return ExecutionInstruction.continueExecution;
  }

  // Execute change block type command
  editContext.editor.execute([
    ChangeBlockTypeRequest(
      nodeId: selection.extent.nodeId,
      headingLevel: HeadingLevel.h3,
    ),
  ]);

  return ExecutionInstruction.haltExecution;
}

/// Keyboard action for bullet list (Cmd+Shift+8 / Ctrl+Shift+8)
ExecutionInstruction _bulletListKeyboardAction({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent) {
    return ExecutionInstruction.continueExecution;
  }

  // Check for Cmd+Shift+8 (Mac) or Ctrl+Shift+8 (Windows/Linux)
  final isModifierPressed =
      HardwareKeyboard.instance.isMetaPressed ||
      HardwareKeyboard.instance.isControlPressed;
  if (keyEvent.logicalKey != LogicalKeyboardKey.digit8 ||
      !isModifierPressed ||
      !HardwareKeyboard.instance.isShiftPressed) {
    return ExecutionInstruction.continueExecution;
  }

  // Execute toggle list command
  editContext.editor.execute([
    const ToggleListRequest(listType: ListType.unordered),
  ]);

  return ExecutionInstruction.haltExecution;
}

/// Keyboard action for numbered list (Cmd+Shift+7 / Ctrl+Shift+7)
ExecutionInstruction _numberedListKeyboardAction({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent) {
    return ExecutionInstruction.continueExecution;
  }

  // Check for Cmd+Shift+7 (Mac) or Ctrl+Shift+7 (Windows/Linux)
  final isModifierPressed =
      HardwareKeyboard.instance.isMetaPressed ||
      HardwareKeyboard.instance.isControlPressed;
  if (keyEvent.logicalKey != LogicalKeyboardKey.digit7 ||
      !isModifierPressed ||
      !HardwareKeyboard.instance.isShiftPressed) {
    return ExecutionInstruction.continueExecution;
  }

  // Execute toggle list command
  editContext.editor.execute([
    const ToggleListRequest(listType: ListType.ordered),
  ]);

  return ExecutionInstruction.haltExecution;
}

/// Keyboard action for left alignment (Cmd+Shift+L / Ctrl+Shift+L)
ExecutionInstruction _alignLeftKeyboardAction({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent) {
    return ExecutionInstruction.continueExecution;
  }

  // Check for Cmd+Shift+L (Mac) or Ctrl+Shift+L (Windows/Linux)
  final isModifierPressed =
      HardwareKeyboard.instance.isMetaPressed ||
      HardwareKeyboard.instance.isControlPressed;
  if (keyEvent.logicalKey != LogicalKeyboardKey.keyL ||
      !isModifierPressed ||
      !HardwareKeyboard.instance.isShiftPressed) {
    return ExecutionInstruction.continueExecution;
  }

  // Execute set alignment command
  editContext.editor.execute([
    const SetTextAlignmentRequest(alignment: TextAlignment.left),
  ]);

  return ExecutionInstruction.haltExecution;
}

/// Keyboard action for center alignment (Cmd+Shift+E / Ctrl+Shift+E)
ExecutionInstruction _alignCenterKeyboardAction({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent) {
    return ExecutionInstruction.continueExecution;
  }

  // Check for Cmd+Shift+E (Mac) or Ctrl+Shift+E (Windows/Linux)
  final isModifierPressed =
      HardwareKeyboard.instance.isMetaPressed ||
      HardwareKeyboard.instance.isControlPressed;
  if (keyEvent.logicalKey != LogicalKeyboardKey.keyE ||
      !isModifierPressed ||
      !HardwareKeyboard.instance.isShiftPressed) {
    return ExecutionInstruction.continueExecution;
  }

  // Execute set alignment command
  editContext.editor.execute([
    const SetTextAlignmentRequest(alignment: TextAlignment.center),
  ]);

  return ExecutionInstruction.haltExecution;
}

/// Keyboard action for right alignment (Cmd+Shift+R / Ctrl+Shift+R)
ExecutionInstruction _alignRightKeyboardAction({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent) {
    return ExecutionInstruction.continueExecution;
  }

  // Check for Cmd+Shift+R (Mac) or Ctrl+Shift+R (Windows/Linux)
  final isModifierPressed =
      HardwareKeyboard.instance.isMetaPressed ||
      HardwareKeyboard.instance.isControlPressed;
  if (keyEvent.logicalKey != LogicalKeyboardKey.keyR ||
      !isModifierPressed ||
      !HardwareKeyboard.instance.isShiftPressed) {
    return ExecutionInstruction.continueExecution;
  }

  // Execute set alignment command
  editContext.editor.execute([
    const SetTextAlignmentRequest(alignment: TextAlignment.right),
  ]);

  return ExecutionInstruction.haltExecution;
}

/// Keyboard action for justify alignment (Cmd+Shift+J / Ctrl+Shift+J)
ExecutionInstruction _alignJustifyKeyboardAction({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent) {
    return ExecutionInstruction.continueExecution;
  }

  // Check for Cmd+Shift+J (Mac) or Ctrl+Shift+J (Windows/Linux)
  final isModifierPressed =
      HardwareKeyboard.instance.isMetaPressed ||
      HardwareKeyboard.instance.isControlPressed;
  if (keyEvent.logicalKey != LogicalKeyboardKey.keyJ ||
      !isModifierPressed ||
      !HardwareKeyboard.instance.isShiftPressed) {
    return ExecutionInstruction.continueExecution;
  }

  // Execute set alignment command
  editContext.editor.execute([
    const SetTextAlignmentRequest(alignment: TextAlignment.justify),
  ]);

  return ExecutionInstruction.haltExecution;
}

/// Keyboard action for clear formatting (Cmd+\ / Ctrl+\)
ExecutionInstruction _clearFormattingKeyboardAction({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent) {
    return ExecutionInstruction.continueExecution;
  }

  // Check for Cmd+\ (Mac) or Ctrl+\ (Windows/Linux)
  final isModifierPressed =
      HardwareKeyboard.instance.isMetaPressed ||
      HardwareKeyboard.instance.isControlPressed;
  if (keyEvent.logicalKey != LogicalKeyboardKey.backslash ||
      !isModifierPressed) {
    return ExecutionInstruction.continueExecution;
  }

  // Execute clear formatting command, preserving entity attributions
  editContext.editor.execute([
    const ClearFormattingRequest(preserveAttributionTypes: {'entity'}),
  ]);

  return ExecutionInstruction.haltExecution;
}

/// Keyboard action for deleting horizontal rule with Backspace
ExecutionInstruction _deleteHorizontalRuleBackspaceAction({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent) {
    return ExecutionInstruction.continueExecution;
  }

  // Check if Backspace key is pressed
  if (keyEvent.logicalKey != LogicalKeyboardKey.backspace) {
    return ExecutionInstruction.continueExecution;
  }

  final selection = editContext.composer.selection;
  if (selection == null || !selection.isCollapsed) {
    return ExecutionInstruction.continueExecution;
  }

  // Check if we're at the start of a text node
  final node = editContext.document.getNodeById(selection.extent.nodeId);
  if (node is TextNode) {
    final position = selection.extent.nodePosition as TextNodePosition;
    if (position.offset == 0) {
      // Check if the previous node is a horizontal rule
      final nodeIndex = editContext.document.getNodeIndexById(node.id);
      if (nodeIndex > 0) {
        final previousNode = editContext.document.getNodeAt(nodeIndex - 1);
        if (previousNode is HorizontalRuleNode) {
          // Delete the horizontal rule
          editContext.editor.execute([DeleteNodeRequest(nodeId: previousNode.id)]);
          return ExecutionInstruction.haltExecution;
        }
      }
    }
  }

  // Check if we're on a horizontal rule node
  if (node is HorizontalRuleNode) {
    editContext.editor.execute([DeleteNodeRequest(nodeId: node.id)]);
    return ExecutionInstruction.haltExecution;
  }

  return ExecutionInstruction.continueExecution;
}

/// Keyboard action for deleting horizontal rule with Delete key
ExecutionInstruction _deleteHorizontalRuleDeleteAction({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent) {
    return ExecutionInstruction.continueExecution;
  }

  // Check if Delete key is pressed
  if (keyEvent.logicalKey != LogicalKeyboardKey.delete) {
    return ExecutionInstruction.continueExecution;
  }

  final selection = editContext.composer.selection;
  if (selection == null || !selection.isCollapsed) {
    return ExecutionInstruction.continueExecution;
  }

  // Check if we're at the end of a text node
  final node = editContext.document.getNodeById(selection.extent.nodeId);
  if (node is TextNode) {
    final position = selection.extent.nodePosition as TextNodePosition;
    if (position.offset == node.text.length) {
      // Check if the next node is a horizontal rule
      final nodeIndex = editContext.document.getNodeIndexById(node.id);
      if (nodeIndex < editContext.document.nodeCount - 1) {
        final nextNode = editContext.document.getNodeAt(nodeIndex + 1);
        if (nextNode is HorizontalRuleNode) {
          // Delete the horizontal rule
          editContext.editor.execute([DeleteNodeRequest(nodeId: nextNode.id)]);
          return ExecutionInstruction.haltExecution;
        }
      }
    }
  }

  // Check if we're on a horizontal rule node
  if (node is HorizontalRuleNode) {
    editContext.editor.execute([DeleteNodeRequest(nodeId: node.id)]);
    return ExecutionInstruction.haltExecution;
  }

  return ExecutionInstruction.continueExecution;
}



/// Keyboard action for copy with formatting (Cmd+C / Ctrl+C)
ExecutionInstruction _copyWithFormattingKeyboardAction({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent) {
    return ExecutionInstruction.continueExecution;
  }

  // Check for Cmd+C (Mac) or Ctrl+C (Windows/Linux)
  final isModifierPressed =
      HardwareKeyboard.instance.isMetaPressed ||
      HardwareKeyboard.instance.isControlPressed;
  if (keyEvent.logicalKey != LogicalKeyboardKey.keyC || !isModifierPressed) {
    return ExecutionInstruction.continueExecution;
  }

  final selection = editContext.composer.selection;
  if (selection == null || selection.isCollapsed) {
    return ExecutionInstruction.continueExecution;
  }

  // Copy with formatting
  ClipboardService.copyWithFormatting(
    document: editContext.document,
    selection: selection,
  );

  return ExecutionInstruction.haltExecution;
}

/// Keyboard action for paste with formatting (Cmd+V / Ctrl+V)
ExecutionInstruction _pasteWithFormattingKeyboardAction({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent) {
    return ExecutionInstruction.continueExecution;
  }

  // Check for Cmd+V (Mac) or Ctrl+V (Windows/Linux)
  final isModifierPressed =
      HardwareKeyboard.instance.isMetaPressed ||
      HardwareKeyboard.instance.isControlPressed;
  if (keyEvent.logicalKey != LogicalKeyboardKey.keyV || !isModifierPressed) {
    return ExecutionInstruction.continueExecution;
  }

  final selection = editContext.composer.selection;
  if (selection == null) {
    return ExecutionInstruction.continueExecution;
  }

  // Paste with formatting (async operation)
  _handlePasteWithFormatting(editContext);

  return ExecutionInstruction.haltExecution;
}

/// Handle paste operation asynchronously
void _handlePasteWithFormatting(SuperEditorContext editContext) async {
  final nodes = await ClipboardService.pasteWithFormatting();
  if (nodes == null || nodes.isEmpty) {
    return;
  }

  final selection = editContext.composer.selection;
  if (selection == null) {
    return;
  }

  // Delete selected content if any
  if (!selection.isCollapsed) {
    editContext.commonOps.deleteSelection(TextAffinity.downstream);
  }

  // Get updated selection after potential deletion
  final currentSelection = editContext.composer.selection;
  if (currentSelection == null) {
    return;
  }

  final currentNode = editContext.document.getNodeById(currentSelection.extent.nodeId);
  if (currentNode == null) {
    return;
  }

  final insertIndex = editContext.document.getNodeIndexById(currentNode.id);

  // Insert all pasted nodes using editor commands
  final requests = <EditRequest>[];
  for (var i = 0; i < nodes.length; i++) {
    requests.add(InsertNodeAtIndexRequest(
      nodeIndex: insertIndex + 1 + i,
      newNode: nodes[i],
    ));
  }
  editContext.editor.execute(requests);

  // Move cursor to end of pasted content
  final lastPastedNode = nodes.last;
  if (lastPastedNode is TextNode) {
    editContext.editor.execute([
      ChangeSelectionRequest(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: lastPastedNode.id,
            nodePosition: TextNodePosition(offset: lastPastedNode.text.length),
          ),
        ),
        SelectionChangeType.placeCaret,
        SelectionReason.userInteraction,
      ),
    ]);
  }
}
