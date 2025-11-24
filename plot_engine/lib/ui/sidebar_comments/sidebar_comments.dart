import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/ai_comment.dart';
import '../../state/app_state.dart';

class SidebarComments extends ConsumerWidget {
  const SidebarComments({super.key});

  // Mock data for demonstration
  List<AIComment> get _mockComments => [
        AIComment(
          id: '1',
          type: 'character',
          message: 'Character introduction detected. Consider adding more physical description.',
          position: 0,
          timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        ),
        AIComment(
          id: '2',
          type: 'plot',
          message: 'Potential plot hole: the timeline doesn\'t match with the previous chapter.',
          position: 100,
          timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
        AIComment(
          id: '3',
          type: 'foreshadowing',
          message: 'Good opportunity for foreshadowing here. Consider hinting at the upcoming conflict.',
          position: 250,
          timestamp: DateTime.now(),
        ),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedEntity = ref.watch(selectedEntityProvider);

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Header
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selectedEntity != null ? Icons.info_outline : Icons.comment,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  selectedEntity != null ? 'Entity Details' : 'AI Comments',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (selectedEntity != null) ...[
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      ref.read(selectedEntityProvider.notifier).clearSelection();
                    },
                    tooltip: 'Close',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
          ),
          // Content
          Expanded(
            child: selectedEntity != null
                ? _buildEntityDetails(context, ref, selectedEntity)
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _mockComments.length,
                    itemBuilder: (context, index) {
                      return _CommentCard(comment: _mockComments[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntityDetails(BuildContext context, WidgetRef ref, metadata) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          Text(
            metadata.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          // Type chip
          Chip(
            label: Text(metadata.type.displayName),
            backgroundColor: _getEntityTypeColor(metadata.type.toJson()),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          const SizedBox(height: 24),
          // Summary section
          if (metadata.summary.isNotEmpty) ...[
            Text(
              'Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                metadata.summary,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
          ],
          // Description section
          if (metadata.description.isNotEmpty) ...[
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                metadata.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
          const SizedBox(height: 24),
          // Edit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Open edit dialog or navigate to Knowledge Panel
                ref.read(selectedEntityProvider.notifier).clearSelection();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Find "${metadata.name}" in the Knowledge Panel to edit'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit in Knowledge Panel'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getEntityTypeColor(String typeName) {
    switch (typeName) {
      case 'character':
        return Colors.blue.shade100;
      case 'location':
        return Colors.green.shade100;
      case 'object':
        return Colors.orange.shade100;
      case 'event':
        return Colors.purple.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
}

class _CommentCard extends StatelessWidget {
  final AIComment comment;

  const _CommentCard({required this.comment});

  Color _getTypeColor(BuildContext context) {
    switch (comment.type) {
      case 'character':
        return Colors.blue;
      case 'plot':
        return Colors.orange;
      case 'foreshadowing':
        return Colors.purple;
      case 'consistency':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon() {
    switch (comment.type) {
      case 'character':
        return Icons.person;
      case 'plot':
        return Icons.timeline;
      case 'foreshadowing':
        return Icons.lightbulb_outline;
      case 'consistency':
        return Icons.warning_amber;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getTypeIcon(),
                  size: 16,
                  color: _getTypeColor(context),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    comment.type.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _getTypeColor(context),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              comment.message,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              _formatTimestamp(comment.timestamp),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
