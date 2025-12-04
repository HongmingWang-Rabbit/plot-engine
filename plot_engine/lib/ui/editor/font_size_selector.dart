/// FontSizeSelector widget for changing text font size
/// 
/// This widget provides a dropdown with common font sizes and custom input,
/// plus increase/decrease buttons for relative adjustments.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart';
import '../../services/formatting_commands.dart';

/// Common font sizes available in the dropdown
const List<double> commonFontSizes = [
  8, 10, 12, 14, 16, 18, 20, 24, 28, 32, 36, 48, 72
];

/// Minimum allowed font size
const double minFontSize = 6.0;

/// Maximum allowed font size
const double maxFontSize = 200.0;

/// FontSizeSelector widget
class FontSizeSelector extends StatefulWidget {
  final Editor editor;
  final DocumentComposer composer;
  final double? currentFontSize;

  const FontSizeSelector({
    super.key,
    required this.editor,
    required this.composer,
    this.currentFontSize,
  });

  @override
  State<FontSizeSelector> createState() => _FontSizeSelectorState();
}

class _FontSizeSelectorState extends State<FontSizeSelector> {
  final TextEditingController _customSizeController = TextEditingController();
  bool _showCustomInput = false;

  @override
  void dispose() {
    _customSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentSizeText = widget.currentFontSize != null 
        ? '${widget.currentFontSize!.toInt()} pt' 
        : 'Default size';
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Decrease font size button
        Semantics(
          button: true,
          label: 'Decrease Font Size',
          hint: 'Decrease font size by 2 points. $currentSizeText',
          enabled: true,
          child: Tooltip(
            message: 'Decrease Font Size',
            waitDuration: const Duration(milliseconds: 500),
            child: Focus(
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.space) {
                    _adjustFontSize(-2);
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: Builder(
                builder: (context) {
                  final isFocused = Focus.of(context).hasFocus;
                  return Container(
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
                      icon: const Icon(Icons.remove, size: 16),
                      onPressed: () => _adjustFontSize(-2),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      iconSize: 16,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 4),
        
        // Font size dropdown
        Semantics(
          button: true,
          label: 'Font size selector',
          hint: '$currentSizeText. Select to change font size.',
          enabled: true,
          child: Tooltip(
            message: 'Change font size ($currentSizeText)',
            waitDuration: const Duration(milliseconds: 500),
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<double>(
                  value: _getNormalizedFontSize(),
                  isDense: true,
                  items: [
                    ...commonFontSizes.map((size) => DropdownMenuItem(
                      value: size,
                      child: Text(
                        size.toInt().toString(),
                        style: const TextStyle(fontSize: 13),
                      ),
                    )),
                    const DropdownMenuItem(
                      value: -1, // Special value for custom
                      child: Text(
                        'Custom...',
                        style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    
                    if (value == -1) {
                      // Show custom input dialog
                      _showCustomSizeDialog();
                    } else {
                      _applyFontSize(value);
                    }
                  },
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 4),
        
        // Increase font size button
        Semantics(
          button: true,
          label: 'Increase Font Size',
          hint: 'Increase font size by 2 points. $currentSizeText',
          enabled: true,
          child: Tooltip(
            message: 'Increase Font Size',
            waitDuration: const Duration(milliseconds: 500),
            child: Focus(
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.space) {
                    _adjustFontSize(2);
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: Builder(
                builder: (context) {
                  final isFocused = Focus.of(context).hasFocus;
                  return Container(
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
                      icon: const Icon(Icons.add, size: 16),
                      onPressed: () => _adjustFontSize(2),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      iconSize: 16,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Get the current font size, normalized to a common size if close enough
  double? _getNormalizedFontSize() {
    if (widget.currentFontSize == null) {
      return null;
    }
    
    // Check if current size matches a common size
    for (final size in commonFontSizes) {
      if ((widget.currentFontSize! - size).abs() < 0.1) {
        return size;
      }
    }
    
    // Return the actual size if it doesn't match a common size
    return widget.currentFontSize;
  }

  /// Apply a specific font size
  void _applyFontSize(double size) {
    if (size < minFontSize || size > maxFontSize) {
      _showErrorMessage('Font size must be between $minFontSize and $maxFontSize');
      return;
    }

    final selection = widget.composer.selection;
    if (selection == null) {
      return;
    }

    // Create font size attribution
    final attribution = FontSizeAttribution(size);

    // Execute toggle command to apply the font size
    widget.editor.execute([
      ToggleInlineStyleRequest(attribution: attribution),
    ]);
  }

  /// Adjust font size by a relative amount
  void _adjustFontSize(double delta) {
    // Get current font size or use default (14)
    final currentSize = widget.currentFontSize ?? 14.0;
    
    // Calculate new size
    final newSize = (currentSize + delta).clamp(minFontSize, maxFontSize);
    
    _applyFontSize(newSize);
  }

  /// Show custom size input dialog
  void _showCustomSizeDialog() {
    _customSizeController.text = widget.currentFontSize?.toInt().toString() ?? '14';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Font Size'),
        content: TextField(
          controller: _customSizeController,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            labelText: 'Font Size',
            hintText: 'Enter size (6-200)',
            suffixText: 'pt',
            border: const OutlineInputBorder(),
            errorText: _validateCustomSize(_customSizeController.text),
          ),
          onSubmitted: (value) {
            if (_validateCustomSize(value) == null) {
              Navigator.of(context).pop();
              _applyFontSize(double.parse(value));
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = _customSizeController.text;
              if (_validateCustomSize(value) == null) {
                Navigator.of(context).pop();
                _applyFontSize(double.parse(value));
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  /// Validate custom size input
  String? _validateCustomSize(String value) {
    if (value.isEmpty) {
      return 'Please enter a font size';
    }
    
    final size = double.tryParse(value);
    if (size == null) {
      return 'Please enter a valid number';
    }
    
    if (size < minFontSize || size > maxFontSize) {
      return 'Size must be between $minFontSize and $maxFontSize';
    }
    
    return null;
  }

  /// Show error message
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
