/// ListButtonGroup widget for formatting toolbar
/// 
/// This widget provides buttons for toggling list formatting:
/// bullet lists and numbered lists.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:super_editor/super_editor.dart';
import '../../services/block_metadata.dart';
import '../../services/formatting_commands.dart';

/// Button group for list formatting (bullet and numbered lists)
class ListButtonGroup extends StatelessWidget {
  /// The editor to execute commands on
  final Editor editor;

  /// The composer to get selection state from
  final DocumentComposer composer;

  /// The current list type (null if not a list)
  final ListType? currentListType;

  const ListButtonGroup({
    super.key,
    required this.editor,
    required this.composer,
    this.currentListType,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildListButton(
          context: context,
          icon: Icons.format_list_bulleted,
          tooltip: _getTooltip('Bullet List', 'Shift+8'),
          isActive: currentListType == ListType.unordered,
          onPressed: () => _toggleList(ListType.unordered),
        ),
        const SizedBox(width: 4),
        _buildListButton(
          context: context,
          icon: Icons.format_list_numbered,
          tooltip: _getTooltip('Numbered List', 'Shift+7'),
          isActive: currentListType == ListType.ordered,
          onPressed: () => _toggleList(ListType.ordered),
        ),
      ],
    );
  }

  /// Build a single list toggle button
  Widget _buildListButton({
    required BuildContext context,
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

  /// Toggle list formatting
  void _toggleList(ListType listType) {
    editor.execute([
      ToggleListRequest(listType: listType),
    ]);
  }
}
