import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/ai_models.dart';
import '../../models/entity_update_suggestion.dart';
import '../../state/app_state.dart';
import '../../state/settings_state.dart';
import '../../services/ai_suggestion_service.dart';
import '../../services/entity_update_service.dart';
import '../../l10n/app_localizations.dart';

// ===== Shared UI helpers for AI suggestions =====

Color _getSuggestionTypeColor(AISuggestionType type) {
  switch (type) {
    case AISuggestionType.consistency:
      return Colors.orange;
    case AISuggestionType.foreshadowing:
      return Colors.purple;
    case AISuggestionType.characterDevelopment:
      return Colors.blue;
    case AISuggestionType.plotHole:
      return Colors.red;
    case AISuggestionType.pacing:
      return Colors.teal;
    case AISuggestionType.dialogue:
      return Colors.green;
    case AISuggestionType.entityUpdate:
      return Colors.indigo;
    case AISuggestionType.general:
      return Colors.grey;
  }
}

IconData _getSuggestionTypeIcon(AISuggestionType type) {
  switch (type) {
    case AISuggestionType.consistency:
      return Icons.warning_amber;
    case AISuggestionType.foreshadowing:
      return Icons.lightbulb_outline;
    case AISuggestionType.characterDevelopment:
      return Icons.person;
    case AISuggestionType.plotHole:
      return Icons.error_outline;
    case AISuggestionType.pacing:
      return Icons.speed;
    case AISuggestionType.dialogue:
      return Icons.chat_bubble_outline;
    case AISuggestionType.entityUpdate:
      return Icons.sync;
    case AISuggestionType.general:
      return Icons.auto_awesome;
  }
}

Color _getSuggestionPriorityColor(AISuggestionPriority priority) {
  switch (priority) {
    case AISuggestionPriority.high:
      return Colors.red;
    case AISuggestionPriority.medium:
      return Colors.orange;
    case AISuggestionPriority.low:
      return Colors.green;
  }
}

/// Get localized label for suggestion type
String _getSuggestionTypeLabel(AISuggestionType type, WidgetRef ref) {
  switch (type) {
    case AISuggestionType.consistency:
      return ref.tr('suggestion_type_consistency');
    case AISuggestionType.foreshadowing:
      return ref.tr('suggestion_type_foreshadowing');
    case AISuggestionType.characterDevelopment:
      return ref.tr('suggestion_type_character');
    case AISuggestionType.plotHole:
      return ref.tr('suggestion_type_plot_hole');
    case AISuggestionType.pacing:
      return ref.tr('suggestion_type_pacing');
    case AISuggestionType.dialogue:
      return ref.tr('suggestion_type_dialogue');
    case AISuggestionType.entityUpdate:
      return ref.tr('suggestion_type_entity_update');
    case AISuggestionType.general:
      return ref.tr('suggestion_type_general');
  }
}

/// Get localized label for suggestion priority
String _getSuggestionPriorityLabel(AISuggestionPriority priority, WidgetRef ref) {
  switch (priority) {
    case AISuggestionPriority.high:
      return ref.tr('priority_high');
    case AISuggestionPriority.medium:
      return ref.tr('priority_medium');
    case AISuggestionPriority.low:
      return ref.tr('priority_low');
  }
}

class SidebarComments extends ConsumerWidget {
  const SidebarComments({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedEntity = ref.watch(selectedEntityProvider);
    final project = ref.watch(projectProvider);
    final currentChapter = ref.watch(currentChapterProvider);
    final suggestionState = ref.watch(aiSuggestionProvider);
    final selectedSuggestion = ref.watch(selectedSuggestionProvider);

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Header
          _buildHeader(context, ref, selectedEntity, suggestionState),
          // Content
          Expanded(
            child: selectedEntity != null
                ? _buildEntityDetails(context, ref, selectedEntity)
                : selectedSuggestion != null
                    ? _buildSuggestionDetail(context, ref, selectedSuggestion)
                    : _buildMessageQueue(
                        context,
                        ref,
                        project,
                        currentChapter,
                        suggestionState,
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    dynamic selectedEntity,
    AISuggestionQueueState suggestionState,
  ) {
    final selectedSuggestion = ref.watch(selectedSuggestionProvider);
    final aiAnalysisEnabled = ref.watch(aiBackgroundAnalysisProvider);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Icon(
            selectedEntity != null
                ? Icons.info_outline
                : selectedSuggestion != null
                    ? Icons.lightbulb
                    : Icons.auto_awesome,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              selectedEntity != null
                  ? ref.tr('entity_details')
                  : selectedSuggestion != null
                      ? _getSuggestionTypeLabel(selectedSuggestion.type, ref)
                      : ref.tr('ai_assistant'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          // Analyzing indicator
          if (suggestionState.isAnalyzing && selectedEntity == null && selectedSuggestion == null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          // Unread badge
          if (suggestionState.unreadCount > 0 && selectedEntity == null && selectedSuggestion == null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${suggestionState.unreadCount}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          // AI analysis toggle (only show when not viewing entity/suggestion)
          if (selectedEntity == null && selectedSuggestion == null)
            Tooltip(
              message: aiAnalysisEnabled ? 'Disable AI analysis' : 'Enable AI analysis',
              child: IconButton(
                icon: Icon(
                  aiAnalysisEnabled ? Icons.psychology : Icons.psychology_outlined,
                  size: 20,
                  color: aiAnalysisEnabled
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  final wasDisabled = !aiAnalysisEnabled;
                  ref.read(aiBackgroundAnalysisProvider.notifier).toggle();
                  // If turning ON, immediately start analysis
                  if (wasDisabled) {
                    ref.read(aiSuggestionProvider.notifier).analyzeNow();
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ),
          // Close button for entity/suggestion view
          if (selectedEntity != null || selectedSuggestion != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () {
                if (selectedEntity != null) {
                  ref.read(selectedEntityProvider.notifier).clearSelection();
                }
                if (selectedSuggestion != null) {
                  ref.read(selectedSuggestionProvider.notifier).state = null;
                }
              },
              tooltip: ref.tr('close'),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          // Collapse button
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: () => ref.read(aiSidebarVisibleProvider.notifier).toggle(),
            tooltip: 'Collapse panel',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageQueue(
    BuildContext context,
    WidgetRef ref,
    dynamic project,
    dynamic currentChapter,
    AISuggestionQueueState suggestionState,
  ) {
    if (project == null) {
      return _buildEmptyState(
        context,
        L10n.get(ref.read(localeProvider), 'open_project_ai'),
        Icons.auto_awesome,
      );
    }

    if (currentChapter == null) {
      return _buildEmptyState(
        context,
        L10n.get(ref.read(localeProvider), 'select_chapter_analyze'),
        Icons.article,
      );
    }

    final activeSuggestions = suggestionState.activeSuggestions
        .where((s) => s.chapterId == currentChapter.id)
        .toList();

    if (activeSuggestions.isEmpty) {
      return _buildEmptyState(
        context,
        suggestionState.isAnalyzing
            ? 'Analyzing your writing...'
            : 'AI will suggest improvements\nas you write',
        Icons.psychology,
      );
    }

    return Column(
      children: [
        // Clear all button
        if (activeSuggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => ref.read(aiSuggestionProvider.notifier).clearAll(),
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear all'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ],
            ),
          ),
        // Message list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: activeSuggestions.length,
            itemBuilder: (context, index) {
              final suggestion = activeSuggestions[index];
              return _SuggestionCard(
                suggestion: suggestion,
                onTap: () {
                  ref.read(aiSuggestionProvider.notifier).markAsRead(suggestion.id);
                  ref.read(selectedSuggestionProvider.notifier).state = suggestion;
                },
                onDismiss: () {
                  ref.read(aiSuggestionProvider.notifier).dismiss(suggestion.id);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionDetail(
    BuildContext context,
    WidgetRef ref,
    AISuggestion suggestion,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type and priority badges
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getSuggestionTypeColor(suggestion.type).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getSuggestionTypeIcon(suggestion.type),
                      size: 14,
                      color: _getSuggestionTypeColor(suggestion.type),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getSuggestionTypeLabel(suggestion.type, ref),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _getSuggestionTypeColor(suggestion.type),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getSuggestionPriorityColor(suggestion.priority).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getSuggestionPriorityLabel(suggestion.priority, ref),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _getSuggestionPriorityColor(suggestion.priority),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            suggestion.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Summary/Description
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              suggestion.summary,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),

          // Details (if available)
          if (suggestion.details != null && suggestion.details!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Details',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              suggestion.details!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],

          // Suggestion (if available)
          if (suggestion.suggestion != null && suggestion.suggestion!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Suggestion',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    suggestion.suggestion!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Location (if available)
          if (suggestion.location != null && suggestion.location!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    suggestion.location!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // Actions
          _buildSuggestionActions(context, ref, suggestion),
        ],
      ),
    );
  }

  Widget _buildSuggestionActions(
    BuildContext context,
    WidgetRef ref,
    AISuggestion suggestion,
  ) {
    // For entity updates, show Accept button
    if (suggestion.type == AISuggestionType.entityUpdate) {
      return _EntityUpdateActions(suggestion: suggestion);
    }

    // Default: just show Dismiss button
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              ref.read(aiSuggestionProvider.notifier).dismiss(suggestion.id);
              ref.read(selectedSuggestionProvider.notifier).state = null;
            },
            icon: const Icon(Icons.close, size: 18),
            label: Text(ref.tr('dismiss')),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntityDetails(BuildContext context, WidgetRef ref, metadata) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metadata.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Chip(
            label: Text(metadata.type.displayName),
            backgroundColor: _getEntityTypeColor(metadata.type.toJson()),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          const SizedBox(height: 24),
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
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

/// Card widget for displaying a suggestion in the queue
class _SuggestionCard extends StatelessWidget {
  final AISuggestion suggestion;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _SuggestionCard({
    required this.suggestion,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUnread = !suggestion.isRead;

    return Dismissible(
      key: Key(suggestion.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.delete_outline,
          color: colorScheme.onErrorContainer,
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: isUnread ? 2 : 0,
        color: isUnread
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isUnread
              ? BorderSide(color: colorScheme.primary.withValues(alpha: 0.5))
              : BorderSide.none,
        ),
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
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _getSuggestionTypeColor(suggestion.type).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getSuggestionTypeIcon(suggestion.type),
                        size: 16,
                        color: _getSuggestionTypeColor(suggestion.type),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            suggestion.title,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            suggestion.summary,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget for entity update suggestion actions (Accept/Dismiss)
class _EntityUpdateActions extends ConsumerStatefulWidget {
  final AISuggestion suggestion;

  const _EntityUpdateActions({required this.suggestion});

  @override
  ConsumerState<_EntityUpdateActions> createState() => _EntityUpdateActionsState();
}

class _EntityUpdateActionsState extends ConsumerState<_EntityUpdateActions> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Dismiss button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _handleDismiss,
            icon: const Icon(Icons.close, size: 18),
            label: Text(ref.tr('dismiss')),
          ),
        ),
        const SizedBox(width: 12),
        // Accept button
        Expanded(
          child: FilledButton.icon(
            onPressed: _isLoading ? null : _handleAccept,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check, size: 18),
            label: Text(ref.tr('accept')),
          ),
        ),
      ],
    );
  }

  void _handleDismiss() {
    ref.read(aiSuggestionProvider.notifier).dismiss(widget.suggestion.id);
    ref.read(selectedSuggestionProvider.notifier).state = null;
  }

  Future<void> _handleAccept() async {
    setState(() => _isLoading = true);

    try {
      // Find the matching EntityUpdateSuggestion from the provider
      final entityUpdateState = ref.read(entityUpdateProvider);
      final matchingSuggestion = _findMatchingSuggestion(entityUpdateState.suggestions);

      if (matchingSuggestion == null) {
        throw Exception('Could not find entity update details');
      }

      // Accept the suggestion using the service
      final service = ref.read(entityUpdateServiceProvider);
      await service.acceptSuggestion(suggestion: matchingSuggestion);

      // Remove from both providers
      ref.read(aiSuggestionProvider.notifier).dismiss(widget.suggestion.id);
      ref.read(entityUpdateProvider.notifier).removeSuggestion(matchingSuggestion.entityId);
      ref.read(selectedSuggestionProvider.notifier).state = null;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${matchingSuggestion.entityName} ${ref.tr('entity_updated')}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update entity: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Find the EntityUpdateSuggestion that matches this AISuggestion
  EntityUpdateSuggestion? _findMatchingSuggestion(List<EntityUpdateSuggestion> suggestions) {
    // Match by summary (newInformation) which should be unique
    for (final s in suggestions) {
      if (s.newInformation == widget.suggestion.summary) {
        return s;
      }
    }
    // Fallback: match by entity name in title
    final title = widget.suggestion.title;
    for (final s in suggestions) {
      if (title.contains(s.entityName)) {
        return s;
      }
    }
    return null;
  }
}
