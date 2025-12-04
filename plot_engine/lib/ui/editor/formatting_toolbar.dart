// FormattingToolbar widget for rich text editing
// 
// This widget displays formatting controls above the editor and reacts to
// selection changes to update button states.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_editor/super_editor.dart';
import '../../services/block_metadata.dart';
import '../../services/formatting_commands.dart';
import '../../utils/responsive.dart';
import 'inline_style_button_group.dart';
import 'block_style_dropdown.dart';
import 'list_button_group.dart';
import 'alignment_button_group.dart';
import 'color_picker_button.dart';
import 'font_size_selector.dart' show FontSizeSelector, commonFontSizes;
import 'clear_formatting_button.dart';

/// State model representing the current formatting of the selection
class FormattingState {
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final bool isStrikethrough;
  final Color? textColor;
  final Color? highlightColor;
  final double? fontSize;
  final HeadingLevel? headingLevel;
  final ListType? listType;
  final TextAlignment alignment;
  final bool hasSelection;

  const FormattingState({
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.isStrikethrough = false,
    this.textColor,
    this.highlightColor,
    this.fontSize,
    this.headingLevel,
    this.listType,
    this.alignment = TextAlignment.left,
    this.hasSelection = false,
  });

  /// Extract formatting state from current selection
  factory FormattingState.fromSelection(
    Document document,
    DocumentSelection? selection,
    Set<Attribution> pendingStyles,
  ) {
    if (selection == null) {
      return const FormattingState();
    }

    // Get the node at the selection
    final node = document.getNodeById(selection.extent.nodeId);
    if (node is! TextNode) {
      return FormattingState(hasSelection: !selection.isCollapsed);
    }

    // Extract block-level formatting
    BlockMetadata? blockMetadata;
    if (node is ParagraphNode) {
      blockMetadata = node.metadata['blockMetadata'] as BlockMetadata?;
    }

    // For collapsed selection, check formatting at cursor position and pending styles
    if (selection.isCollapsed) {
      final textPosition = selection.extent.nodePosition as TextNodePosition;
      final offset = textPosition.offset;
      
      // Check for inline styles at cursor position
      final attributions = node.text.getAllAttributionsAt(offset > 0 ? offset - 1 : 0);
      
      bool isBold = false;
      bool isItalic = false;
      bool isUnderline = false;
      bool isStrikethrough = false;
      Color? textColor;
      Color? highlightColor;
      double? fontSize;

      for (final attribution in attributions) {
        if (attribution == boldAttribution) {
          isBold = true;
        } else if (attribution == italicsAttribution) {
          isItalic = true;
        } else if (attribution == underlineAttribution) {
          isUnderline = true;
        } else if (attribution == strikethroughAttribution) {
          isStrikethrough = true;
        } else if (attribution is ColorAttribution) {
          textColor = attribution.color;
        } else if (attribution is BackgroundColorAttribution) {
          highlightColor = attribution.color;
        } else if (attribution is FontSizeAttribution) {
          fontSize = attribution.fontSize;
        }
      }
      
      // Override with pending styles
      for (final pendingStyle in pendingStyles) {
        if (pendingStyle == boldAttribution) {
          isBold = true;
        } else if (pendingStyle == italicsAttribution) {
          isItalic = true;
        } else if (pendingStyle == underlineAttribution) {
          isUnderline = true;
        } else if (pendingStyle == strikethroughAttribution) {
          isStrikethrough = true;
        } else if (pendingStyle is ColorAttribution) {
          textColor = pendingStyle.color;
        } else if (pendingStyle is BackgroundColorAttribution) {
          highlightColor = pendingStyle.color;
        } else if (pendingStyle is FontSizeAttribution) {
          fontSize = pendingStyle.fontSize;
        }
      }
      
      return FormattingState(
        isBold: isBold,
        isItalic: isItalic,
        isUnderline: isUnderline,
        isStrikethrough: isStrikethrough,
        textColor: textColor,
        highlightColor: highlightColor,
        fontSize: fontSize,
        headingLevel: blockMetadata?.headingLevel,
        listType: blockMetadata?.listType,
        alignment: blockMetadata?.alignment ?? TextAlignment.left,
        hasSelection: false,
      );
    }

    // Extract inline formatting from selection
    // Get the start and end positions
    final basePosition = selection.base.nodePosition as TextNodePosition;
    final extentPosition = selection.extent.nodePosition as TextNodePosition;
    
    final startOffset = basePosition.offset < extentPosition.offset 
        ? basePosition.offset 
        : extentPosition.offset;
    final endOffset = basePosition.offset > extentPosition.offset 
        ? basePosition.offset 
        : extentPosition.offset;

    // Check if attributions are present across the entire selection
    bool isBold = _hasAttributionInRange(node.text, boldAttribution, startOffset, endOffset);
    bool isItalic = _hasAttributionInRange(node.text, italicsAttribution, startOffset, endOffset);
    bool isUnderline = _hasAttributionInRange(node.text, underlineAttribution, startOffset, endOffset);
    bool isStrikethrough = _hasAttributionInRange(node.text, strikethroughAttribution, startOffset, endOffset);
    
    // For color and font size, just check at the start of selection
    final attributions = node.text.getAllAttributionsAt(startOffset);
    Color? textColor;
    Color? highlightColor;
    double? fontSize;

    for (final attribution in attributions) {
      if (attribution is ColorAttribution) {
        textColor = attribution.color;
      } else if (attribution is BackgroundColorAttribution) {
        highlightColor = attribution.color;
      } else if (attribution is FontSizeAttribution) {
        fontSize = attribution.fontSize;
      }
    }

    return FormattingState(
      isBold: isBold,
      isItalic: isItalic,
      isUnderline: isUnderline,
      isStrikethrough: isStrikethrough,
      textColor: textColor,
      highlightColor: highlightColor,
      fontSize: fontSize,
      headingLevel: blockMetadata?.headingLevel,
      listType: blockMetadata?.listType,
      alignment: blockMetadata?.alignment ?? TextAlignment.left,
      hasSelection: true,
    );
  }

  /// Check if an attribution is present across the entire range
  static bool _hasAttributionInRange(
    AttributedText text,
    Attribution attribution,
    int startOffset,
    int endOffset,
  ) {
    if (startOffset >= endOffset) {
      return false;
    }
    
    // Check if the attribution is present at every position in the range
    for (int i = startOffset; i < endOffset; i++) {
      final attributions = text.getAllAttributionsAt(i);
      if (!attributions.contains(attribution)) {
        return false;
      }
    }
    
    return true;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FormattingState &&
        other.isBold == isBold &&
        other.isItalic == isItalic &&
        other.isUnderline == isUnderline &&
        other.isStrikethrough == isStrikethrough &&
        other.textColor == textColor &&
        other.highlightColor == highlightColor &&
        other.fontSize == fontSize &&
        other.headingLevel == headingLevel &&
        other.listType == listType &&
        other.alignment == alignment &&
        other.hasSelection == hasSelection;
  }

  @override
  int get hashCode {
    return Object.hash(
      isBold,
      isItalic,
      isUnderline,
      isStrikethrough,
      textColor,
      highlightColor,
      fontSize,
      headingLevel,
      listType,
      alignment,
      hasSelection,
    );
  }
}

/// FormattingToolbar widget that displays formatting controls
class FormattingToolbar extends ConsumerStatefulWidget {
  final Editor editor;
  final DocumentComposer composer;

  const FormattingToolbar({
    super.key,
    required this.editor,
    required this.composer,
  });

  @override
  ConsumerState<FormattingToolbar> createState() => _FormattingToolbarState();
}

class _FormattingToolbarState extends ConsumerState<FormattingToolbar> {
  FormattingState _formattingState = const FormattingState();
  DocumentSelection? _lastSelection;

  @override
  void initState() {
    super.initState();
    // Listen to composer selection changes
    widget.composer.selectionNotifier.addListener(_onSelectionChanged);
    // Listen to document changes
    widget.editor.document.addListener(_onDocumentChanged);
    // Initialize state
    _updateFormattingState();
  }

  @override
  void dispose() {
    widget.composer.selectionNotifier.removeListener(_onSelectionChanged);
    widget.editor.document.removeListener(_onDocumentChanged);
    super.dispose();
  }

  void _onSelectionChanged() {
    final currentSelection = widget.composer.selection;
    
    // Clear pending styles if cursor moved to a different position
    if (_lastSelection != null && currentSelection != null) {
      if (_lastSelection!.extent != currentSelection.extent) {
        ref.read(pendingStylesProvider.notifier).state = {};
      }
    }
    
    _lastSelection = currentSelection;
    _updateFormattingState();
  }

  void _onDocumentChanged(DocumentChangeLog changeLog) {
    _updateFormattingState();
  }

  void _updateFormattingState() {
    final pendingStyles = ref.read(pendingStylesProvider);
    final newState = FormattingState.fromSelection(
      widget.editor.document,
      widget.composer.selection,
      pendingStyles,
    );

    if (newState != _formattingState) {
      setState(() {
        _formattingState = newState;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ResponsiveBuilder(
      builder: (context, viewport) {
        // Use overflow menu for mobile and tablet
        if (viewport == ViewportSize.mobile || viewport == ViewportSize.tablet) {
          return _buildCompactToolbar(context, colorScheme, viewport);
        }
        
        // Full toolbar for desktop
        return _buildFullToolbar(context, colorScheme);
      },
    );
  }

  /// Build full toolbar for desktop viewports
  Widget _buildFullToolbar(BuildContext context, ColorScheme colorScheme) {
    return Semantics(
      container: true,
      label: 'Formatting toolbar',
      hint: 'Contains text formatting controls including bold, italic, colors, alignment, and more',
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Inline style buttons
              InlineStyleButtonGroup(
                editor: widget.editor,
                composer: widget.composer,
                isBold: _formattingState.isBold,
                isItalic: _formattingState.isItalic,
                isUnderline: _formattingState.isUnderline,
                isStrikethrough: _formattingState.isStrikethrough,
              ),

              _buildDivider(context),

              // Color picker buttons
              ColorPickerButton(
                editor: widget.editor,
                composer: widget.composer,
                currentColor: _formattingState.textColor,
                isTextColor: true,
                tooltip: 'Text Color',
                icon: Icons.format_color_text,
              ),
              const SizedBox(width: 4),
              ColorPickerButton(
                editor: widget.editor,
                composer: widget.composer,
                currentColor: _formattingState.highlightColor,
                isTextColor: false,
                tooltip: 'Highlight Color',
                icon: Icons.format_color_fill,
              ),

              _buildDivider(context),

              // Font size selector
              FontSizeSelector(
                editor: widget.editor,
                composer: widget.composer,
                currentFontSize: _formattingState.fontSize,
              ),

              _buildDivider(context),

              // Block style dropdown
              BlockStyleDropdown(
                editor: widget.editor,
                composer: widget.composer,
                currentStyle: BlockStyle.fromMetadata(_formattingState.headingLevel != null || _formattingState.hasSelection
                    ? BlockMetadata(
                        headingLevel: _formattingState.headingLevel,
                        isBlockQuote: false,
                      )
                    : null),
              ),

              _buildDivider(context),

              // List buttons
              ListButtonGroup(
                editor: widget.editor,
                composer: widget.composer,
                currentListType: _formattingState.listType,
              ),

              _buildDivider(context),

              // Alignment buttons
              AlignmentButtonGroup(
                editor: widget.editor,
                composer: widget.composer,
                currentAlignment: _formattingState.alignment,
              ),

              _buildDivider(context),

              // Clear formatting button
              ClearFormattingButton(
                editor: widget.editor,
                composer: widget.composer,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build compact toolbar with overflow menu for mobile/tablet
  Widget _buildCompactToolbar(BuildContext context, ColorScheme colorScheme, ViewportSize viewport) {
    final isMobile = viewport == ViewportSize.mobile;

    return Semantics(
      container: true,
      label: 'Formatting toolbar',
      hint: 'Contains essential text formatting controls. Use the more options menu for additional formatting.',
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          children: [
            // Scrollable toolbar content
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12),
                child: Row(
                  children: [
                    // Essential inline style buttons (always visible)
                    InlineStyleButtonGroup(
                      editor: widget.editor,
                      composer: widget.composer,
                      isBold: _formattingState.isBold,
                      isItalic: _formattingState.isItalic,
                      isUnderline: _formattingState.isUnderline,
                      isStrikethrough: _formattingState.isStrikethrough,
                    ),

                    if (!isMobile) ...[
                      _buildDivider(context),

                      // Block style dropdown (tablet only)
                      BlockStyleDropdown(
                        editor: widget.editor,
                        composer: widget.composer,
                        currentStyle: BlockStyle.fromMetadata(_formattingState.headingLevel != null || _formattingState.hasSelection
                            ? BlockMetadata(
                                headingLevel: _formattingState.headingLevel,
                                isBlockQuote: false,
                              )
                            : null),
                      ),

                      _buildDivider(context),

                      // List buttons (tablet only)
                      ListButtonGroup(
                        editor: widget.editor,
                        composer: widget.composer,
                        currentListType: _formattingState.listType,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Overflow menu button (always visible, not scrolled)
            Padding(
              padding: EdgeInsets.only(right: isMobile ? 8 : 12),
              child: _buildOverflowMenu(context, colorScheme, isMobile),
            ),
          ],
        ),
      ),
    );
  }

  /// Build divider between toolbar sections
  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: 1,
        height: 24,
        color: Theme.of(context).dividerColor,
      ),
    );
  }

  /// Build overflow menu with additional formatting options
  Widget _buildOverflowMenu(BuildContext context, ColorScheme colorScheme, bool isMobile) {
    return Semantics(
      button: true,
      label: 'More formatting options',
      hint: 'Open menu with additional formatting controls',
      enabled: true,
      child: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert,
          size: 20,
          color: colorScheme.onSurface,
        ),
        tooltip: 'More formatting options',
        itemBuilder: (context) => [
        if (isMobile) ...[
          // Block styles (mobile only)
          PopupMenuItem<String>(
            enabled: false,
            child: Text(
              'Block Style',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          ...BlockStyle.values.map((style) => PopupMenuItem<String>(
            value: 'block_${style.name}',
            child: Row(
              children: [
                if (_formattingState.headingLevel == style.headingLevel)
                  Icon(Icons.check, size: 16, color: colorScheme.primary)
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 8),
                Text(style.label),
              ],
            ),
            onTap: () => _applyBlockStyle(style),
          )),
          const PopupMenuDivider(),
          
          // List options (mobile only)
          PopupMenuItem<String>(
            enabled: false,
            child: Text(
              'Lists',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          PopupMenuItem<String>(
            value: 'list_bullet',
            child: Row(
              children: [
                if (_formattingState.listType == ListType.unordered)
                  Icon(Icons.check, size: 16, color: colorScheme.primary)
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 8),
                const Icon(Icons.format_list_bulleted, size: 20),
                const SizedBox(width: 8),
                const Text('Bullet List'),
              ],
            ),
            onTap: () => widget.editor.execute([ToggleListRequest(listType: ListType.unordered)]),
          ),
          PopupMenuItem<String>(
            value: 'list_numbered',
            child: Row(
              children: [
                if (_formattingState.listType == ListType.ordered)
                  Icon(Icons.check, size: 16, color: colorScheme.primary)
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 8),
                const Icon(Icons.format_list_numbered, size: 20),
                const SizedBox(width: 8),
                const Text('Numbered List'),
              ],
            ),
            onTap: () => widget.editor.execute([ToggleListRequest(listType: ListType.ordered)]),
          ),
          const PopupMenuDivider(),
        ],
        
        // Alignment options
        PopupMenuItem<String>(
          enabled: false,
          child: Text(
            'Alignment',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'align_left',
          child: Row(
            children: [
              if (_formattingState.alignment == TextAlignment.left)
                Icon(Icons.check, size: 16, color: colorScheme.primary)
              else
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              const Icon(Icons.format_align_left, size: 20),
              const SizedBox(width: 8),
              const Text('Align Left'),
            ],
          ),
          onTap: () => widget.editor.execute([SetTextAlignmentRequest(alignment: TextAlignment.left)]),
        ),
        PopupMenuItem<String>(
          value: 'align_center',
          child: Row(
            children: [
              if (_formattingState.alignment == TextAlignment.center)
                Icon(Icons.check, size: 16, color: colorScheme.primary)
              else
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              const Icon(Icons.format_align_center, size: 20),
              const SizedBox(width: 8),
              const Text('Align Center'),
            ],
          ),
          onTap: () => widget.editor.execute([SetTextAlignmentRequest(alignment: TextAlignment.center)]),
        ),
        PopupMenuItem<String>(
          value: 'align_right',
          child: Row(
            children: [
              if (_formattingState.alignment == TextAlignment.right)
                Icon(Icons.check, size: 16, color: colorScheme.primary)
              else
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              const Icon(Icons.format_align_right, size: 20),
              const SizedBox(width: 8),
              const Text('Align Right'),
            ],
          ),
          onTap: () => widget.editor.execute([SetTextAlignmentRequest(alignment: TextAlignment.right)]),
        ),
        PopupMenuItem<String>(
          value: 'align_justify',
          child: Row(
            children: [
              if (_formattingState.alignment == TextAlignment.justify)
                Icon(Icons.check, size: 16, color: colorScheme.primary)
              else
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              const Icon(Icons.format_align_justify, size: 20),
              const SizedBox(width: 8),
              const Text('Justify'),
            ],
          ),
          onTap: () => widget.editor.execute([SetTextAlignmentRequest(alignment: TextAlignment.justify)]),
        ),
        const PopupMenuDivider(),
        
        // Color options
        PopupMenuItem<String>(
          value: 'text_color',
          child: const Row(
            children: [
              SizedBox(width: 24),
              Icon(Icons.format_color_text, size: 20),
              SizedBox(width: 8),
              Text('Text Color...'),
            ],
          ),
          onTap: () {
            // Trigger color picker (will be handled by the button itself)
            // This is just a placeholder - actual implementation would need
            // to show a color picker dialog
          },
        ),
        PopupMenuItem<String>(
          value: 'highlight_color',
          child: const Row(
            children: [
              SizedBox(width: 24),
              Icon(Icons.format_color_fill, size: 20),
              SizedBox(width: 8),
              Text('Highlight Color...'),
            ],
          ),
          onTap: () {
            // Trigger color picker
          },
        ),
        const PopupMenuDivider(),
        
        // Font size
        PopupMenuItem<String>(
          value: 'font_size',
          child: const Row(
            children: [
              SizedBox(width: 24),
              Icon(Icons.format_size, size: 20),
              SizedBox(width: 8),
              Text('Font Size...'),
            ],
          ),
          onTap: () {
            // Show font size dialog
            _showFontSizeDialog(context);
          },
        ),
        const PopupMenuDivider(),
        
        // Clear formatting
        PopupMenuItem<String>(
          value: 'clear_formatting',
          child: const Row(
            children: [
              SizedBox(width: 24),
              Icon(Icons.format_clear, size: 20),
              SizedBox(width: 8),
              Text('Clear Formatting'),
            ],
          ),
          onTap: () => widget.editor.execute([
            const ClearFormattingRequest(
              preserveAttributionTypes: {'entity'},
            ),
          ]),
        ),
      ],
    ),
    );
  }

  /// Apply block style from overflow menu
  void _applyBlockStyle(BlockStyle style) {
    final selection = widget.composer.selection;
    if (selection == null) {
      return;
    }

    final nodeId = selection.extent.nodeId;
    final command = ChangeBlockTypeRequest(
      nodeId: nodeId,
      headingLevel: style.headingLevel,
      isBlockQuote: style.isBlockQuote,
    );

    widget.editor.execute([command]);
  }

  /// Show font size selection dialog
  void _showFontSizeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Font Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: commonFontSizes.map((size) {
            return ListTile(
              title: Text('${size.toInt()} pt'),
              selected: _formattingState.fontSize == size,
              onTap: () {
                Navigator.of(context).pop();
                widget.editor.execute([
                  ToggleInlineStyleRequest(
                    attribution: FontSizeAttribution(size),
                  ),
                ]);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
