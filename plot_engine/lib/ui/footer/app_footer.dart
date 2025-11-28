import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/status_state.dart';
import '../../l10n/app_localizations.dart';

class AppFooter extends ConsumerWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(statusProvider);

    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          // Status message
          if (status != null) ...[
            _buildStatusIcon(status.type, context),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                status.message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getStatusColor(status.type, context),
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else ...[
            Text(
              ref.tr('ready'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
            const Spacer(),
          ],
          const SizedBox(width: 16),
          // Additional info (optional)
          Text(
            'PlotEngine',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
                ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(StatusType type, BuildContext context) {
    IconData icon;
    switch (type) {
      case StatusType.success:
        icon = Icons.check_circle;
        break;
      case StatusType.error:
        icon = Icons.error;
        break;
      case StatusType.loading:
        return SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      case StatusType.info:
      default:
        icon = Icons.info;
    }

    return Icon(
      icon,
      size: 14,
      color: _getStatusColor(type, context),
    );
  }

  Color _getStatusColor(StatusType type, BuildContext context) {
    switch (type) {
      case StatusType.success:
        return Colors.green;
      case StatusType.error:
        return Colors.red;
      case StatusType.loading:
        return Theme.of(context).colorScheme.primary;
      case StatusType.info:
      default:
        return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
    }
  }
}
