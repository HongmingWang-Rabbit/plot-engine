/// ColorPickerButton widget for formatting toolbar
/// 
/// This widget provides a button with a color picker dropdown for
/// applying text color or highlight color to selected text.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart';

/// Button with color picker for text or highlight color
class ColorPickerButton extends StatefulWidget {
  /// The editor to execute commands on
  final Editor editor;

  /// The composer to get selection state from
  final DocumentComposer composer;

  /// The current color (null if no color or mixed colors)
  final Color? currentColor;

  /// Whether this is for text color (true) or highlight color (false)
  final bool isTextColor;

  /// Tooltip text
  final String tooltip;

  /// Icon to display
  final IconData icon;

  const ColorPickerButton({
    super.key,
    required this.editor,
    required this.composer,
    this.currentColor,
    required this.isTextColor,
    required this.tooltip,
    required this.icon,
  });

  @override
  State<ColorPickerButton> createState() => _ColorPickerButtonState();
}

class _ColorPickerButtonState extends State<ColorPickerButton> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasColor = widget.currentColor != null;
    
    final colorType = widget.isTextColor ? 'text color' : 'highlight color';
    final colorDescription = hasColor 
        ? 'Current $colorType is applied' 
        : 'No $colorType applied';

    return CompositedTransformTarget(
      link: _layerLink,
      child: Semantics(
        button: true,
        label: '${widget.tooltip}. $colorDescription',
        hint: 'Select to choose a $colorType',
        enabled: true,
        child: Tooltip(
          message: widget.tooltip,
          waitDuration: const Duration(milliseconds: 500),
          child: Focus(
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.enter ||
                    event.logicalKey == LogicalKeyboardKey.space) {
                  _showColorPicker();
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: Builder(
              builder: (context) {
                final isFocused = Focus.of(context).hasFocus;
                return Material(
                  color: hasColor 
                      ? colorScheme.primaryContainer.withOpacity(0.3)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  child: InkWell(
                    onTap: _showColorPicker,
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: isFocused
                          ? BoxDecoration(
                              border: Border.all(
                                color: colorScheme.primary,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            )
                          : null,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            widget.icon,
                            size: 20,
                            color: hasColor 
                                ? colorScheme.onPrimaryContainer 
                                : colorScheme.onSurface,
                          ),
                          // Color preview bar at bottom
                          if (hasColor)
                            Positioned(
                              bottom: 4,
                              child: Container(
                                width: 20,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: widget.currentColor,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showColorPicker() {
    if (_overlayEntry != null) {
      _removeOverlay();
      return;
    }

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _removeOverlay,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            CompositedTransformFollower(
              link: _layerLink,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: Offset(0, size.height + 4),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                child: _ColorPickerPanel(
                  currentColor: widget.currentColor,
                  isTextColor: widget.isTextColor,
                  onColorSelected: (color) {
                    _applyColor(color);
                    _removeOverlay();
                  },
                  onClear: widget.isTextColor ? null : () {
                    _clearColor();
                    _removeOverlay();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyColor(Color color) {
    final selection = widget.composer.selection;
    if (selection == null || selection.isCollapsed) {
      return;
    }

    final document = widget.editor.document as MutableDocument;
    final selectedNodes = document.getNodesInside(
      selection.base,
      selection.extent,
    );

    if (selectedNodes.isEmpty) {
      return;
    }

    // Create the appropriate attribution
    final attribution = widget.isTextColor
        ? ColorAttribution(color)
        : BackgroundColorAttribution(color);

    // Apply to all selected text nodes
    for (final node in selectedNodes) {
      if (node is! TextNode) {
        continue;
      }

      final nodeSelection = _getNodeSelection(node, selection, document);
      if (nodeSelection == null) {
        continue;
      }

      // Remove any existing color attribution of this type first
      final existingAttributions = node.text.getAttributionSpansInRange(
        attributionFilter: (attr) => 
            widget.isTextColor 
                ? attr is ColorAttribution 
                : attr is BackgroundColorAttribution,
        range: nodeSelection,
      );

      for (final span in existingAttributions) {
        node.text.removeAttribution(
          span.attribution,
          SpanRange(nodeSelection.start, nodeSelection.end),
        );
      }

      // Add the new color attribution
      node.text.addAttribution(
        attribution,
        nodeSelection,
      );
    }

    // Trigger rebuild
    widget.editor.execute([const DoNothingCommand()]);
  }

  void _clearColor() {
    final selection = widget.composer.selection;
    if (selection == null || selection.isCollapsed) {
      return;
    }

    final document = widget.editor.document as MutableDocument;
    final selectedNodes = document.getNodesInside(
      selection.base,
      selection.extent,
    );

    if (selectedNodes.isEmpty) {
      return;
    }

    // Remove color attributions from all selected text nodes
    for (final node in selectedNodes) {
      if (node is! TextNode) {
        continue;
      }

      final nodeSelection = _getNodeSelection(node, selection, document);
      if (nodeSelection == null) {
        continue;
      }

      // Remove color attributions
      final attributions = node.text.getAttributionSpansInRange(
        attributionFilter: (attr) => attr is BackgroundColorAttribution,
        range: nodeSelection,
      );

      for (final span in attributions) {
        node.text.removeAttribution(
          span.attribution,
          SpanRange(nodeSelection.start, nodeSelection.end),
        );
      }
    }

    // Trigger rebuild
    widget.editor.execute([const DoNothingCommand()]);
  }

  SpanRange? _getNodeSelection(
    TextNode node,
    DocumentSelection selection,
    MutableDocument document,
  ) {
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

    if (startOffset == endOffset) {
      return null;
    }

    return SpanRange(startOffset, endOffset - 1);
  }
}

/// Color picker panel with common colors and custom color option
class _ColorPickerPanel extends StatelessWidget {
  final Color? currentColor;
  final bool isTextColor;
  final Function(Color) onColorSelected;
  final VoidCallback? onClear;

  const _ColorPickerPanel({
    required this.currentColor,
    required this.isTextColor,
    required this.onColorSelected,
    this.onClear,
  });

  // Common colors palette
  static const List<Color> _commonColors = [
    Colors.black,
    Color(0xFF424242), // Dark grey
    Color(0xFF757575), // Medium grey
    Color(0xFFBDBDBD), // Light grey
    Colors.white,
    Color(0xFFD32F2F), // Red
    Color(0xFFF57C00), // Orange
    Color(0xFFFBC02D), // Yellow
    Color(0xFF388E3C), // Green
    Color(0xFF1976D2), // Blue
    Color(0xFF7B1FA2), // Purple
    Color(0xFFE91E63), // Pink
    Color(0xFF00796B), // Teal
    Color(0xFF5D4037), // Brown
    Color(0xFFFF5722), // Deep Orange
  ];

  static const List<Color> _highlightColors = [
    Color(0xFFFFEB3B), // Yellow
    Color(0xFFFFCDD2), // Light Red
    Color(0xFFFFF9C4), // Light Yellow
    Color(0xFFC8E6C9), // Light Green
    Color(0xFFBBDEFB), // Light Blue
    Color(0xFFE1BEE7), // Light Purple
    Color(0xFFF8BBD0), // Light Pink
    Color(0xFFB2DFDB), // Light Teal
    Color(0xFFD7CCC8), // Light Brown
    Color(0xFFFFCCBC), // Light Orange
  ];

  @override
  Widget build(BuildContext context) {
    final colors = isTextColor ? _commonColors : _highlightColors;
    
    return Container(
      width: 240,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isTextColor ? 'Text Color' : 'Highlight Color',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          // Color grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colors.map((color) {
              final isSelected = currentColor == color;
              return GestureDetector(
                onTap: () => onColorSelected(color),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: _getContrastColor(color),
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
          if (onClear != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('No Highlight'),
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 36),
                alignment: Alignment.centerLeft,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getContrastColor(Color background) {
    // Calculate relative luminance
    final luminance = (0.299 * background.red + 
                      0.587 * background.green + 
                      0.114 * background.blue) / 255;
    
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

/// A no-op command that triggers document change notifications
class DoNothingCommand implements EditRequest {
  const DoNothingCommand();

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;
}
