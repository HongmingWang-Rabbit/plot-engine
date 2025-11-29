import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entity_update_suggestion.dart';
import '../services/entity_update_service.dart';
import '../state/app_state.dart';
import '../l10n/app_localizations.dart';

/// Widget that displays entity update suggestions and allows accepting/dismissing them
class EntityUpdateSuggestions extends ConsumerWidget {
  final VoidCallback? onClose;

  const EntityUpdateSuggestions({
    super.key,
    this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(entityUpdateProvider);
    final suggestions = state.visibleSuggestions;

    if (state.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Analyzing chapter for entity updates...'),
            ],
          ),
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: onClose,
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    }

    if (suggestions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                ref.tr('no_entity_updates_found'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                ref.tr('entity_updates_description'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              if (onClose != null)
                TextButton(
                  onPressed: onClose,
                  child: const Text('Close'),
                ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${suggestions.length} ${ref.tr('entity_updates_available')}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (onClose != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                  tooltip: 'Close',
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: suggestions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _SuggestionCard(
                suggestion: suggestions[index],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SuggestionCard extends ConsumerStatefulWidget {
  final EntityUpdateSuggestion suggestion;

  const _SuggestionCard({
    required this.suggestion,
  });

  @override
  ConsumerState<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends ConsumerState<_SuggestionCard> {
  bool _isExpanded = false;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildEntityTypeIcon(widget.suggestion.entityType),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.suggestion.entityName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.suggestion.newInformation,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Suggested text
                  Text(
                    ref.tr('suggested_update'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.suggestion.suggestedAppendText,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),

                  // Relevant quotes
                  if (widget.suggestion.relevantQuotes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      ref.tr('relevant_quotes'),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.suggestion.relevantQuotes.map((quote) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.format_quote,
                            size: 16,
                            color: theme.colorScheme.primary.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              quote,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ],

          // Action buttons
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isProcessing ? null : _handleDismiss,
                  child: Text(ref.tr('dismiss')),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: _isProcessing ? null : _handleAccept,
                  child: _isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(ref.tr('accept')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntityTypeIcon(String entityType) {
    final theme = Theme.of(context);
    IconData icon;
    Color color;

    switch (entityType.toLowerCase()) {
      case 'character':
        icon = Icons.person;
        color = Colors.blue;
        break;
      case 'location':
        icon = Icons.place;
        color = Colors.green;
        break;
      case 'object':
        icon = Icons.inventory_2;
        color = Colors.orange;
        break;
      case 'event':
        icon = Icons.event;
        color = Colors.purple;
        break;
      default:
        icon = Icons.category;
        color = theme.colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Future<void> _handleAccept() async {
    setState(() => _isProcessing = true);

    try {
      final service = ref.read(entityUpdateServiceProvider);
      await service.acceptSuggestion(suggestion: widget.suggestion);

      // Remove from suggestions list
      ref.read(entityUpdateProvider.notifier).removeSuggestion(
        widget.suggestion.entityId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.suggestion.entityName} updated'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _handleDismiss() {
    ref.read(entityUpdateProvider.notifier).dismissSuggestion(
      widget.suggestion.entityId,
    );
  }
}

/// Dialog to show entity update suggestions
Future<void> showEntityUpdateSuggestionsDialog(
  BuildContext context,
  WidgetRef ref, {
  required String chapterContent,
}) async {
  // Start loading
  ref.read(entityUpdateProvider.notifier).setLoading(true);

  // Show dialog immediately
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 600,
        ),
        child: EntityUpdateSuggestions(
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    ),
  );

  // Fetch suggestions in background
  try {
    final service = ref.read(entityUpdateServiceProvider);
    final suggestions = await service.checkForUpdates(
      chapterContent: chapterContent,
    );
    ref.read(entityUpdateProvider.notifier).setSuggestions(suggestions);
  } catch (e) {
    ref.read(entityUpdateProvider.notifier).setError(e.toString());
  }
}
