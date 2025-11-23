import 'package:flutter/material.dart';
import '../../models/chapter.dart';

/// Reusable chapter card widget
class ChapterCard extends StatelessWidget {
  final Chapter chapter;
  final bool isSelected;
  final VoidCallback onTap;

  const ChapterCard({
    super.key,
    required this.chapter,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chapter.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : null,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${chapter.content.length} characters',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected
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
      ),
    );
  }
}
