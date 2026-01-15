import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/status_state.dart';
import '../../state/app_state.dart';
import '../../models/sync_metadata.dart';
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
          // Sync status indicator
          _buildSyncIndicator(context, ref),
          const SizedBox(width: 12),
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

  Widget _buildSyncIndicator(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authUserProvider);
    final syncStatus = ref.watch(syncStatusProvider);
    final project = ref.watch(projectProvider);

    // Don't show if not logged in
    if (authUser == null) {
      return const SizedBox.shrink();
    }

    // Don't show if no project is open
    if (project == null) {
      return const SizedBox.shrink();
    }

    return Tooltip(
      message: _getSyncTooltip(syncStatus, project.isCloudStored, ref),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSyncIcon(syncStatus, project.isCloudStored, context),
          const SizedBox(width: 4),
          Text(
            _getSyncLabel(syncStatus, project.isCloudStored, ref),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _getSyncColor(syncStatus, project.isCloudStored, context),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncIcon(SyncStatus status, bool isCloudStored, BuildContext context) {
    if (status == SyncStatus.syncing) {
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
    }

    IconData icon;
    if (isCloudStored && status == SyncStatus.synced) {
      icon = Icons.cloud_done;
    } else if (status == SyncStatus.failed) {
      icon = Icons.cloud_off;
    } else if (status == SyncStatus.pending) {
      icon = Icons.cloud_upload;
    } else {
      icon = Icons.cloud_queue;
    }

    return Icon(
      icon,
      size: 14,
      color: _getSyncColor(status, isCloudStored, context),
    );
  }

  Color _getSyncColor(SyncStatus status, bool isCloudStored, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (isCloudStored && status == SyncStatus.synced) {
      return colorScheme.tertiary; // Success color from theme
    }
    switch (status) {
      case SyncStatus.syncing:
        return colorScheme.primary;
      case SyncStatus.failed:
        return colorScheme.error;
      case SyncStatus.pending:
        return colorScheme.secondary;
      default:
        return colorScheme.onSurface.withValues(alpha: 0.6);
    }
  }

  String _getSyncLabel(SyncStatus status, bool isCloudStored, WidgetRef ref) {
    if (isCloudStored && status == SyncStatus.synced) {
      return ref.tr('sync_synced');
    }
    switch (status) {
      case SyncStatus.syncing:
        return ref.tr('sync_syncing');
      case SyncStatus.failed:
        return ref.tr('sync_failed');
      case SyncStatus.pending:
        return ref.tr('sync_pending');
      default:
        return ref.tr('sync_offline');
    }
  }

  String _getSyncTooltip(SyncStatus status, bool isCloudStored, WidgetRef ref) {
    if (isCloudStored && status == SyncStatus.synced) {
      return ref.tr('sync_tooltip_synced');
    }
    switch (status) {
      case SyncStatus.syncing:
        return ref.tr('sync_tooltip_syncing');
      case SyncStatus.failed:
        return ref.tr('sync_tooltip_failed');
      case SyncStatus.pending:
        return ref.tr('sync_tooltip_pending');
      default:
        return ref.tr('sync_tooltip_offline');
    }
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
        icon = Icons.info;
    }

    return Icon(
      icon,
      size: 14,
      color: _getStatusColor(type, context),
    );
  }

  Color _getStatusColor(StatusType type, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (type) {
      case StatusType.success:
        return colorScheme.tertiary;
      case StatusType.error:
        return colorScheme.error;
      case StatusType.loading:
        return colorScheme.primary;
      case StatusType.info:
        return colorScheme.onSurface.withValues(alpha: 0.7);
    }
  }
}
