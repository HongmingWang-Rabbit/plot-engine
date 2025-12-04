/// ClearFormattingButton widget for removing all formatting
/// 
/// This widget provides a button to clear all formatting from selected text
/// while preserving entity attributions and document structure.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart';
import '../../services/formatting_commands.dart';

/// Button to clear all formatting from selected text
class ClearFormattingButton extends StatelessWidget {
  final Editor editor;
  final DocumentComposer composer;

  const ClearFormattingButton({
    super.key,
    required this.editor,
    required this.composer,
  });

  @override
  Widget build(BuildContext context) {
    final selection = composer.selection;
    final isEnabled = selection != null;
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'Clear Formatting (Cmd+\\)',
      hint: isEnabled 
          ? 'Remove all formatting from selected text while preserving entities' 
          : 'Select text to clear formatting',
      enabled: isEnabled,
      child: Tooltip(
        message: 'Clear Formatting (Cmd+\\)',
        waitDuration: const Duration(milliseconds: 500),
        child: Focus(
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent && isEnabled) {
              if (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.space) {
                _clearFormatting();
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: Builder(
            builder: (context) {
              final isFocused = Focus.of(context).hasFocus;
              return Container(
                width: 32,
                height: 32,
                decoration: isFocused
                    ? BoxDecoration(
                        border: Border.all(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      )
                    : null,
                child: IconButton(
                  icon: const Icon(Icons.format_clear, size: 20),
                  onPressed: isEnabled ? _clearFormatting : null,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _clearFormatting() {
    // Execute the clear formatting command
    // Preserve entity attributions by specifying their type
    editor.execute([
      const ClearFormattingRequest(
        preserveAttributionTypes: {
          'entity', // Preserve entity attributions
        },
      ),
    ]);
  }
}
