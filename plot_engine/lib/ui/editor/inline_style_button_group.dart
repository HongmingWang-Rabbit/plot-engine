/// InlineStyleButtonGroup widget for formatting toolbar
/// 
/// This widget provides buttons for toggling inline text styles:
/// bold, italic, underline, and strikethrough.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_editor/super_editor.dart';
import '../../services/formatting_commands.dart';

/// Button group for inline text styling (bold, italic, underline, strikethrough)
class InlineStyleButtonGroup extends ConsumerWidget {
  /// The editor to execute commands on
  final Editor editor;

  /// The composer to get selection state from
  final DocumentComposer composer;

  /// Whether bold is active in the current selection
  final bool isBold;

  /// Whether italic is active in the current selection
  final bool isItalic;

  /// Whether underline is active in the current selection
  final bool isUnderline;

  /// Whether strikethrough is active in the current selection
  final bool isStrikethrough;

  /// Whether the current selection has mixed formatting (indeterminate state)
  final bool hasMixedFormatting;

  const InlineStyleButtonGroup({
    super.key,
    required this.editor,
    required this.composer,
    required this.isBold,
    required this.isItalic,
    required this.isUnderline,
    required this.isStrikethrough,
    this.hasMixedFormatting = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStyleButton(
          context: context,
          ref: ref,
          icon: Icons.format_bold,
          tooltip: _getTooltip('Bold', 'B'),
          isActive: isBold,
          onPressed: () => _toggleStyle(ref, boldAttribution),
        ),
        const SizedBox(width: 4),
        _buildStyleButton(
          context: context,
          ref: ref,
          icon: Icons.format_italic,
          tooltip: _getTooltip('Italic', 'I'),
          isActive: isItalic,
          onPressed: () => _toggleStyle(ref, italicsAttribution),
        ),
        const SizedBox(width: 4),
        _buildStyleButton(
          context: context,
          ref: ref,
          icon: Icons.format_underlined,
          tooltip: _getTooltip('Underline', 'U'),
          isActive: isUnderline,
          onPressed: () => _toggleStyle(ref, underlineAttribution),
        ),
        const SizedBox(width: 4),
        _buildStyleButton(
          context: context,
          ref: ref,
          icon: Icons.format_strikethrough,
          tooltip: 'Strikethrough',
          isActive: isStrikethrough,
          onPressed: () => _toggleStyle(ref, strikethroughAttribution),
        ),
      ],
    );
  }

  /// Build a single style toggle button
  Widget _buildStyleButton({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required String tooltip,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
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
                onPressed();
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
                  onTap: onPressed,
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

  /// Toggle an inline style attribution
  void _toggleStyle(WidgetRef ref, Attribution attribution) {
    final selection = composer.selection;

    // If selection is collapsed, toggle pending style instead of executing command
    if (selection != null && selection.isCollapsed) {
      final pendingStyles = ref.read(pendingStylesProvider);
      if (pendingStyles.contains(attribution)) {
        ref.read(pendingStylesProvider.notifier).state =
          Set.from(pendingStyles)..remove(attribution);
      } else {
        ref.read(pendingStylesProvider.notifier).state =
          Set.from(pendingStyles)..add(attribution);
      }
      return;
    }

    // For non-collapsed selection, execute the command
    editor.execute([
      ToggleInlineStyleRequest(attribution: attribution),
    ]);
  }

}
