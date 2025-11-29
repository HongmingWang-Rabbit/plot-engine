import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';
import '../../services/entity_attribution_service.dart';

/// Configuration constants for the editor
class EditorConfig {
  EditorConfig._();

  // Document padding
  static const documentPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 8);

  // Text styling
  static const double fontSize = 16.0;
  static const double lineHeight = 1.6;

  // Entity highlight styling
  static const double entityUnderlineThickness = 2.0;
  static const double entityUnderlineHoverThickness = 3.0;

  // Caret styling
  static const double caretWidth = 2.0;
  static const Color caretColorLight = Color(0xFFFF6B00); // Bright orange
  static const Color caretColorDark = Color(0xFF00D4FF); // Bright cyan

  // Timer intervals
  static const Duration autoSaveInterval = Duration(seconds: 1);
  static const Duration attributionUpdateInterval = Duration(seconds: 2);
}

/// Factory for creating editor stylesheets
class EditorStylesheetFactory {
  /// Creates a minimal stylesheet for the chapter editor
  static Stylesheet createChapterStylesheet({
    required BuildContext context,
    required bool highlightsEnabled,
    String? hoveredEntityName,
  }) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Stylesheet(
      documentPadding: EditorConfig.documentPadding,
      rules: [
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
      ],
      inlineTextStyler: (attributions, existingStyle) {
        return _applyEntityStyling(
          attributions: attributions,
          existingStyle: existingStyle,
          highlightsEnabled: highlightsEnabled,
          hoveredEntityName: hoveredEntityName,
        );
      },
    );
  }

  /// Applies entity styling to inline text
  static TextStyle _applyEntityStyling({
    required Set<Attribution> attributions,
    required TextStyle existingStyle,
    required bool highlightsEnabled,
    String? hoveredEntityName,
  }) {
    if (!highlightsEnabled) {
      return existingStyle;
    }

    TextStyle style = existingStyle;
    for (final attribution in attributions) {
      if (attribution is EntityAttribution) {
        final entity = attribution.entity;
        final isHovered = hoveredEntityName == entity.name;
        final thickness = isHovered
            ? EditorConfig.entityUnderlineHoverThickness
            : EditorConfig.entityUnderlineThickness;

        final color = entity.recognized
            ? Colors.green.shade600
            : Colors.orange.shade600;

        style = style.copyWith(
          decoration: TextDecoration.underline,
          decorationColor: color,
          decorationThickness: thickness,
        );
      }
    }
    return style;
  }

  /// Creates selection styles for the editor
  static SelectionStyles createSelectionStyles(BuildContext context) {
    return SelectionStyles(
      selectionColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
    );
  }

  /// Creates the caret style based on current theme brightness
  static CaretStyle createCaretStyle(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return CaretStyle(
      width: EditorConfig.caretWidth,
      color: isLight ? EditorConfig.caretColorLight : EditorConfig.caretColorDark,
    );
  }
}
