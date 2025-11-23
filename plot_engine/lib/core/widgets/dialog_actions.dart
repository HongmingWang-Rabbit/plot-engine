import 'package:flutter/material.dart';

/// Standardized dialog action buttons (Cancel + Confirm)
class DialogActions extends StatelessWidget {
  final VoidCallback? onCancel;
  final VoidCallback onConfirm;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final bool confirmEnabled;

  const DialogActions({
    super.key,
    this.onCancel,
    required this.onConfirm,
    required this.confirmLabel,
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    this.confirmEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: onCancel ?? () => Navigator.of(context).pop(),
          child: Text(cancelLabel),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: confirmEnabled ? onConfirm : null,
          style: isDestructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                )
              : null,
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
