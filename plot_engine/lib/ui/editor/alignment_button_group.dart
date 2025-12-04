/// AlignmentButtonGroup widget for formatting toolbar
/// 
/// This widget provides buttons for setting text alignment:
/// left, center, right, and justify.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:super_editor/super_editor.dart';
import '../../services/block_metadata.dart';
import '../../services/formatting_commands.dart';

/// Button group for text alignment (left, center, right, justify)
class AlignmentButtonGroup extends StatelessWidget {
  /// The editor to execute commands on
  final Editor editor;

  /// The composer to get selection state from
  final DocumentComposer composer;

  /// The current text alignment
  final TextAlignment currentAlignment;

  const AlignmentButtonGroup({
    super.key,
    required this.editor,
    required this.composer,
    required this.currentAlignment,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAlignmentButton(
          context: context,
          icon: Icons.format_align_left,
          tooltip: _getTooltip('Align Left', 'Shift+L'),
          alignment: TextAlignment.left,
        ),
        const SizedBox(width: 4),
        _buildAlignmentButton(
          context: context,
          icon: Icons.format_align_center,
          tooltip: _getTooltip('Align Center', 'Shift+E'),
          alignment: TextAlignment.center,
        ),
        const SizedBox(width: 4),
        _buildAlignmentButton(
          context: context,
          icon: Icons.format_align_right,
          tooltip: _getTooltip('Align Right', 'Shift+R'),
          alignment: TextAlignment.right,
        ),
        const SizedBox(width: 4),
        _buildAlignmentButton(
          context: context,
          icon: Icons.format_align_justify,
          tooltip: _getTooltip('Justify', 'Shift+J'),
          alignment: TextAlignment.justify,
        ),
      ],
    );
  }

  /// Build a single alignment button
  Widget _buildAlignmentButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required TextAlignment alignment,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = currentAlignment == alignment;
    
    // Extract label from tooltip (before the parenthesis)
    final label = tooltip.split('(').first.trim();
    
    return Semantics(
      button: true,
      label: tooltip,
      hint: isActive ? '$label is currently applied' : 'Apply $label',
      enabled: true,
      toggled: isActive,
      child: Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 500),
        child: Focus(
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.space) {
                _setAlignment(alignment);
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: Builder(
            builder: (context) {
              final isFocused = Focus.of(context).hasFocus;
              return Material(
                color: isActive 
                    ? colorScheme.primaryContainer 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                child: InkWell(
                  onTap: () => _setAlignment(alignment),
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
                    child: Icon(
                      icon,
                      size: 20,
                      color: isActive 
                          ? colorScheme.onPrimaryContainer 
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Get tooltip text with keyboard shortcut
  String _getTooltip(String label, String key) {
    final isMac = defaultTargetPlatform == TargetPlatform.macOS;
    final modifier = isMac ? '⌘' : 'Ctrl';
    return '$label ($modifier+$key)';
  }

  /// Set text alignment
  void _setAlignment(TextAlignment alignment) {
    editor.execute([
      SetTextAlignmentRequest(alignment: alignment),
    ]);
  }
}
