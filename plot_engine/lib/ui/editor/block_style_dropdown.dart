/// BlockStyleDropdown widget for selecting block-level formatting
/// 
/// This widget provides a dropdown menu for changing paragraph types
/// (Normal, Heading 1, Heading 2, Heading 3, Block Quote).

import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';
import '../../services/block_metadata.dart';
import '../../services/formatting_commands.dart';

/// Block style options available in the dropdown
enum BlockStyle {
  normal,
  heading1,
  heading2,
  heading3,
  blockQuote;

  /// Get display label for the block style
  String get label {
    switch (this) {
      case BlockStyle.normal:
        return 'Normal';
      case BlockStyle.heading1:
        return 'Heading 1';
      case BlockStyle.heading2:
        return 'Heading 2';
      case BlockStyle.heading3:
        return 'Heading 3';
      case BlockStyle.blockQuote:
        return 'Block Quote';
    }
  }

  /// Get keyboard shortcut hint for the block style
  String? get shortcutHint {
    switch (this) {
      case BlockStyle.heading1:
        return 'Cmd+Alt+1';
      case BlockStyle.heading2:
        return 'Cmd+Alt+2';
      case BlockStyle.heading3:
        return 'Cmd+Alt+3';
      default:
        return null;
    }
  }

  /// Convert from BlockMetadata to BlockStyle
  static BlockStyle fromMetadata(BlockMetadata? metadata) {
    if (metadata == null || !metadata.hasFormatting) {
      return BlockStyle.normal;
    }

    if (metadata.isBlockQuote) {
      return BlockStyle.blockQuote;
    }

    switch (metadata.headingLevel) {
      case HeadingLevel.h1:
        return BlockStyle.heading1;
      case HeadingLevel.h2:
        return BlockStyle.heading2;
      case HeadingLevel.h3:
        return BlockStyle.heading3;
      default:
        return BlockStyle.normal;
    }
  }

  /// Convert BlockStyle to HeadingLevel
  HeadingLevel? get headingLevel {
    switch (this) {
      case BlockStyle.heading1:
        return HeadingLevel.h1;
      case BlockStyle.heading2:
        return HeadingLevel.h2;
      case BlockStyle.heading3:
        return HeadingLevel.h3;
      default:
        return null;
    }
  }

  /// Check if this style is a block quote
  bool get isBlockQuote => this == BlockStyle.blockQuote;
}

/// Dropdown widget for selecting block styles
class BlockStyleDropdown extends StatelessWidget {
  final Editor editor;
  final DocumentComposer composer;
  final BlockStyle currentStyle;

  const BlockStyleDropdown({
    super.key,
    required this.editor,
    required this.composer,
    required this.currentStyle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'Block style selector',
      hint: 'Current style: ${currentStyle.label}. Select to change paragraph formatting.',
      enabled: true,
      child: Tooltip(
        message: 'Change paragraph style (${currentStyle.label})',
        waitDuration: const Duration(milliseconds: 500),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(4),
            color: colorScheme.surface,
          ),
          child: DropdownButton<BlockStyle>(
            value: currentStyle,
            underline: const SizedBox.shrink(),
            isDense: true,
            items: BlockStyle.values.map((style) {
              return DropdownMenuItem<BlockStyle>(
                value: style,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      style.label,
                      style: _getStyleForBlockType(context, style),
                    ),
                    if (style.shortcutHint != null) ...[
                      const SizedBox(width: 16),
                      Text(
                        style.shortcutHint!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
            onChanged: (BlockStyle? newStyle) {
              if (newStyle == null || newStyle == currentStyle) {
                return;
              }
              _applyBlockStyle(newStyle);
            },
          ),
        ),
      ),
    );
  }

  /// Get text style for displaying block type in dropdown
  TextStyle _getStyleForBlockType(BuildContext context, BlockStyle style) {
    final baseStyle = Theme.of(context).textTheme.bodyMedium!;
    
    switch (style) {
      case BlockStyle.heading1:
        return baseStyle.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        );
      case BlockStyle.heading2:
        return baseStyle.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        );
      case BlockStyle.heading3:
        return baseStyle.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        );
      case BlockStyle.blockQuote:
        return baseStyle.copyWith(
          fontStyle: FontStyle.italic,
        );
      case BlockStyle.normal:
        return baseStyle;
    }
  }

  /// Apply the selected block style to the current node
  void _applyBlockStyle(BlockStyle style) {
    final selection = composer.selection;
    if (selection == null) {
      return;
    }

    // Get the node at the selection
    final nodeId = selection.extent.nodeId;

    // Create and execute the command
    final command = ChangeBlockTypeRequest(
      nodeId: nodeId,
      headingLevel: style.headingLevel,
      isBlockQuote: style.isBlockQuote,
    );

    editor.execute([command]);
  }
}
