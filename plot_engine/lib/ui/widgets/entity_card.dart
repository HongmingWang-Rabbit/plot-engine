import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/entity_metadata.dart';
import '../../models/entity_type.dart';

/// Card widget for displaying EntityMetadata in the Knowledge Panel
class EntityCard extends ConsumerWidget {
  final EntityMetadata entity;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const EntityCard({
    super.key,
    required this.entity,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Entity type chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTypeColor(context, entity.type),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      entity.type.displayName,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16),
                    onPressed: onEdit,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Edit',
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 16),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Delete',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Entity name
              Text(
                entity.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              // Entity summary
              if (entity.summary.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  entity.summary,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(BuildContext context, EntityType type) {
    switch (type) {
      case EntityType.character:
        return Colors.blue;
      case EntityType.location:
        return Colors.green;
      case EntityType.object:
        return Colors.orange;
      case EntityType.event:
        return Colors.purple;
      case EntityType.setting:
        return Colors.teal;
      case EntityType.timeline:
        return Colors.amber;
      case EntityType.custom:
        return Colors.indigo;
      case EntityType.unknown:
        return Colors.grey;
    }
  }
}
