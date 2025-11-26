import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/ai_models.dart';
import '../../state/app_state.dart';
import '../../services/ai_service.dart';

class SidebarComments extends ConsumerWidget {
  const SidebarComments({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedEntity = ref.watch(selectedEntityProvider);
    final project = ref.watch(projectProvider);
    final currentChapter = ref.watch(currentChapterProvider);
    final isLoading = ref.watch(aiLoadingProvider);
    final aiError = ref.watch(aiErrorProvider);
    final consistencyIssues = ref.watch(consistencyIssuesProvider);
    final foreshadowing = ref.watch(foreshadowingSuggestionsProvider);

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
                  selectedEntity != null ? Icons.info_outline : Icons.auto_awesome,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedEntity != null ? 'Entity Details' : 'AI Assistant',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (selectedEntity != null)
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
            ),
          ),
          // Content
          Expanded(
            child: selectedEntity != null
                ? _buildEntityDetails(context, ref, selectedEntity)
                : _buildAIAssistant(
                    context,
                    ref,
                    project,
                    currentChapter,
                    isLoading,
                    aiError,
                    consistencyIssues,
                    foreshadowing,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIAssistant(
    BuildContext context,
    WidgetRef ref,
    project,
    currentChapter,
    bool isLoading,
    String? aiError,
    List<ConsistencyIssue> consistencyIssues,
    ForeshadowingSuggestions? foreshadowing,
  ) {
    if (project == null) {
      return _buildEmptyState(
        context,
        'Open a project to use AI features',
        Icons.auto_awesome,
      );
    }

    if (currentChapter == null) {
      return _buildEmptyState(
        context,
        'Select a chapter to analyze',
        Icons.article,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Action Buttons
          _buildActionButtons(context, ref, project, currentChapter, isLoading),
          const SizedBox(height: 16),

          // Error message
          if (aiError != null) ...[
            _buildErrorCard(context, aiError),
            const SizedBox(height: 16),
          ],

          // Loading indicator
          if (isLoading) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Analyzing...'),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Consistency Issues
            if (consistencyIssues.isNotEmpty) ...[
              _buildSectionHeader(context, 'Consistency Issues', Icons.warning_amber),
              const SizedBox(height: 8),
              ...consistencyIssues.map((issue) => _buildConsistencyCard(context, issue)),
              const SizedBox(height: 16),
            ],

            // Foreshadowing Suggestions
            if (foreshadowing != null && foreshadowing.totalCount > 0) ...[
              _buildSectionHeader(context, 'Foreshadowing', Icons.lightbulb_outline),
              const SizedBox(height: 8),
              ...foreshadowing.callbacks.map((c) => _buildCallbackCard(context, c)),
              ...foreshadowing.foreshadowing.map((f) => _buildForeshadowCard(context, f)),
              ...foreshadowing.thematicResonances.map((t) => _buildThemeCard(context, t)),
            ],

            // Empty state if no results
            if (consistencyIssues.isEmpty && (foreshadowing == null || foreshadowing.totalCount == 0))
              _buildEmptyState(
                context,
                'Click an action above to analyze\nyour chapter with AI',
                Icons.psychology,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    project,
    currentChapter,
    bool isLoading,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Check Consistency Button
        _ActionButton(
          icon: Icons.fact_check,
          label: 'Check Consistency',
          subtitle: 'Find plot holes & contradictions',
          onPressed: isLoading
              ? null
              : () => _runConsistencyCheck(ref, project.id, currentChapter.id),
        ),
        const SizedBox(height: 8),
        // Get Foreshadowing Button
        _ActionButton(
          icon: Icons.lightbulb_outline,
          label: 'Foreshadowing Ideas',
          subtitle: 'Get narrative suggestions',
          onPressed: isLoading
              ? null
              : () => _runForeshadowing(ref, project.id, currentChapter.id),
        ),
        const SizedBox(height: 8),
        // Extract Entities Button
        _ActionButton(
          icon: Icons.person_search,
          label: 'Extract Entities',
          subtitle: 'Find characters, places, objects',
          onPressed: isLoading
              ? null
              : () => _runEntityExtraction(ref, currentChapter.content),
        ),
      ],
    );
  }

  Future<void> _runConsistencyCheck(WidgetRef ref, String projectId, String chapterId) async {
    ref.read(aiLoadingProvider.notifier).state = true;
    ref.read(aiErrorProvider.notifier).state = null;

    try {
      final aiService = ref.read(aiServiceProvider);
      final issues = await aiService.checkConsistency(
        projectId: projectId,
        chapterId: chapterId,
      );
      ref.read(consistencyIssuesProvider.notifier).state = issues;
    } catch (e) {
      ref.read(aiErrorProvider.notifier).state = 'Failed to check consistency: $e';
    } finally {
      ref.read(aiLoadingProvider.notifier).state = false;
    }
  }

  Future<void> _runForeshadowing(WidgetRef ref, String projectId, String chapterId) async {
    ref.read(aiLoadingProvider.notifier).state = true;
    ref.read(aiErrorProvider.notifier).state = null;

    try {
      final aiService = ref.read(aiServiceProvider);
      final suggestions = await aiService.getForeshadowingSuggestions(
        projectId: projectId,
        chapterId: chapterId,
      );
      ref.read(foreshadowingSuggestionsProvider.notifier).state = suggestions;
    } catch (e) {
      ref.read(aiErrorProvider.notifier).state = 'Failed to get suggestions: $e';
    } finally {
      ref.read(aiLoadingProvider.notifier).state = false;
    }
  }

  Future<void> _runEntityExtraction(WidgetRef ref, String content) async {
    ref.read(aiLoadingProvider.notifier).state = true;
    ref.read(aiErrorProvider.notifier).state = null;

    try {
      final aiService = ref.read(aiServiceProvider);
      final entities = await aiService.extractEntities(text: content);
      ref.read(extractedEntitiesProvider.notifier).state = entities;

      // Show results in a different way - for now just update the provider
      // The entities can be imported to the knowledge base
    } catch (e) {
      ref.read(aiErrorProvider.notifier).state = 'Failed to extract entities: $e';
    } finally {
      ref.read(aiLoadingProvider.notifier).state = false;
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildConsistencyCard(BuildContext context, ConsistencyIssue issue) {
    final severityColor = _getSeverityColor(issue.severity);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    issue.severity.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: severityColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    issue.type,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              issue.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (issue.suggestion.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.tips_and_updates,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        issue.suggestion,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCallbackCard(BuildContext context, ForeshadowingCallback callback) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.replay, size: 16, color: Colors.blue),
                const SizedBox(width: 6),
                Text(
                  'Callback to Ch. ${callback.referenceChapter}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              callback.element,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              callback.suggestion,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (callback.location.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Location: ${callback.location}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildForeshadowCard(BuildContext context, ForeshadowingSuggestion foreshadow) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 16, color: Colors.purple),
                const SizedBox(width: 6),
                Text(
                  foreshadow.type.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getSubtletyColor(foreshadow.subtlety).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    foreshadow.subtlety,
                    style: TextStyle(
                      fontSize: 10,
                      color: _getSubtletyColor(foreshadow.subtlety),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              foreshadow.suggestion,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, ThematicResonance theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sync_alt, size: 16, color: Colors.teal),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    theme.theme,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Earlier: ${theme.earlierOccurrence}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Suggestion: ${theme.suggestedEcho}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String error) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
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

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow.shade700;
      default:
        return Colors.grey;
    }
  }

  Color _getSubtletyColor(String subtlety) {
    switch (subtlety.toLowerCase()) {
      case 'high':
        return Colors.green;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.orange;
      default:
        return Colors.grey;
    }
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
