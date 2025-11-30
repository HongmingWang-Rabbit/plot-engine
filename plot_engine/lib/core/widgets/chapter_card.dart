import 'package:flutter/material.dart';
import '../../models/chapter.dart';

/// Reusable chapter card widget
class ChapterCard extends StatefulWidget {
  final Chapter chapter;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final int? index; // For ReorderableDragStartListener
  final int suggestionCount; // Number of AI suggestions for this chapter

  const ChapterCard({
    super.key,
    required this.chapter,
    required this.isSelected,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.index,
    this.suggestionCount = 0,
  });

  @override
  State<ChapterCard> createState() => _ChapterCardState();
}

class _ChapterCardState extends State<ChapterCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        color: widget.isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
        child: InkWell(
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Drag handle (shows on hover)
                if (widget.index != null && (_isHovered || widget.isSelected))
                  ReorderableDragStartListener(
                    index: widget.index!,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.grab,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.drag_indicator,
                          size: 18,
                          color: widget.isSelected
                              ? Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                // Chapter number badge
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.chapter.order + 1}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: widget.isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.chapter.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: widget.isSelected
                                  ? Theme.of(context).colorScheme.onPrimaryContainer
                                  : null,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.chapter.content.length} characters',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: widget.isSelected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                      .withValues(alpha: 0.7)
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                ),
                // AI suggestion count badge
                if (widget.suggestionCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 14,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.suggestionCount}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                        ),
                      ],
                    ),
                  ),
                // Edit button (shows on hover)
                if (widget.onEdit != null && (_isHovered || widget.isSelected))
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: widget.isSelected
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    onPressed: widget.onEdit,
                    tooltip: 'Edit chapter name',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                if (widget.onEdit != null && widget.onDelete != null && (_isHovered || widget.isSelected))
                  const SizedBox(width: 4),
                // Delete button (shows on hover)
                if (widget.onDelete != null && (_isHovered || widget.isSelected))
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: widget.isSelected
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.error,
                    ),
                    onPressed: widget.onDelete,
                    tooltip: 'Delete chapter',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
