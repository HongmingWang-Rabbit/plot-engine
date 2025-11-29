import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/ai_models.dart';
import '../../services/ai_service.dart';
import '../../state/app_state.dart';
import '../../state/tab_state.dart';
import '../../l10n/app_localizations.dart';

/// Compact AI input bar for user-initiated AI interactions
class AIInputBar extends ConsumerStatefulWidget {
  /// Callback when AI generates content to append to editor
  final void Function(String content)? onContentGenerated;

  const AIInputBar({
    super.key,
    this.onContentGenerated,
  });

  @override
  ConsumerState<AIInputBar> createState() => _AIInputBarState();
}

class _AIInputBarState extends ConsumerState<AIInputBar> {
  final TextEditingController _promptController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showResponse = false;

  @override
  void dispose() {
    _promptController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String? get _projectId => ref.read(projectProvider)?.id;

  String? get _chapterId {
    final activeTab = ref.read(tabStateProvider).activeTab;
    if (activeTab?.type == TabContentType.chapter) {
      return activeTab?.chapter?.id;
    }
    return null;
  }

  bool get _hasChapter => _chapterId != null;

  Future<void> _handleAskAI() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    final projectId = _projectId;
    if (projectId == null) return;

    await ref.read(aiWritingProvider.notifier).askAI(
      projectId: projectId,
      question: prompt,
      context: _hasChapter ? AskContext.chapter : AskContext.project,
      chapterId: _chapterId,
    );

    setState(() => _showResponse = true);
  }

  Future<void> _handleContinueWriting() async {
    final projectId = _projectId;
    final chapterId = _chapterId;
    if (projectId == null || chapterId == null) return;

    final prompt = _promptController.text.trim();

    final content = await ref.read(aiWritingProvider.notifier).continueWriting(
      projectId: projectId,
      chapterId: chapterId,
      prompt: prompt.isEmpty ? null : prompt,
    );

    if (content != null) {
      widget.onContentGenerated?.call(content);
      _promptController.clear();
    }
    setState(() => _showResponse = true);
  }

  Future<void> _handleModify() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    final projectId = _projectId;
    final chapterId = _chapterId;
    if (projectId == null || chapterId == null) return;

    final content = await ref.read(aiWritingProvider.notifier).modifyChapter(
      projectId: projectId,
      chapterId: chapterId,
      prompt: prompt,
    );

    if (content != null) {
      widget.onContentGenerated?.call(content);
      _promptController.clear();
    }
    setState(() => _showResponse = true);
  }

  void _insertResponse() {
    final aiState = ref.read(aiWritingProvider);
    if (aiState.lastResponse != null) {
      widget.onContentGenerated?.call(aiState.lastResponse!);
      ref.read(aiWritingProvider.notifier).clearResponse();
      setState(() => _showResponse = false);
    }
  }

  void _closeResponse() {
    ref.read(aiWritingProvider.notifier).clearResponse();
    setState(() => _showResponse = false);
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiWritingProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final project = ref.watch(projectProvider);

    if (project == null) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Response area (shown above input when there's a response)
        if (_showResponse && (aiState.lastResponse != null || aiState.error != null))
          _buildResponseArea(context, colorScheme, aiState),

        // Input bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            border: Border(
              top: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              // Input field
              Expanded(
                child: TextField(
                  controller: _promptController,
                  focusNode: _focusNode,
                  enabled: !aiState.isLoading,
                  decoration: InputDecoration(
                    hintText: ref.tr('ai_prompt_hint'),
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    isDense: true,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                  onSubmitted: (_) => _handleAskAI(),
                ),
              ),
              const SizedBox(width: 8),

              // Action buttons
              if (aiState.isLoading)
                SizedBox(
                  width: 36,
                  height: 36,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  ),
                )
              else ...[
                // Ask AI button
                _ActionIconButton(
                  icon: Icons.question_answer,
                  tooltip: ref.tr('ask_ai'),
                  onPressed: _handleAskAI,
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 4),
                // Continue Writing button
                _ActionIconButton(
                  icon: Icons.edit_note,
                  tooltip: ref.tr('continue_writing'),
                  onPressed: _hasChapter ? _handleContinueWriting : null,
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 4),
                // Modify button
                _ActionIconButton(
                  icon: Icons.auto_fix_high,
                  tooltip: ref.tr('modify_chapter'),
                  onPressed: _hasChapter ? _handleModify : null,
                  colorScheme: colorScheme,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResponseArea(BuildContext context, ColorScheme colorScheme, AIWritingState aiState) {
    final isError = aiState.error != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError
            ? colorScheme.errorContainer.withValues(alpha: 0.3)
            : colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError
              ? colorScheme.error.withValues(alpha: 0.5)
              : colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      constraints: const BoxConstraints(maxHeight: 150),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.auto_awesome,
                size: 16,
                color: isError ? colorScheme.error : colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isError ? ref.tr('error') : ref.tr('ai_response'),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isError ? colorScheme.error : colorScheme.primary,
                  ),
                ),
              ),
              if (!isError && aiState.lastResponse != null)
                TextButton.icon(
                  onPressed: _insertResponse,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(ref.tr('insert')),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 28),
                  ),
                ),
              IconButton(
                onPressed: _closeResponse,
                icon: const Icon(Icons.close, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              child: SelectableText(
                aiState.error ?? aiState.lastResponse ?? '',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact icon button for AI actions
class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final ColorScheme colorScheme;

  const _ActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: onPressed != null
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        foregroundColor: onPressed != null
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant,
        padding: const EdgeInsets.all(8),
        minimumSize: const Size(36, 36),
      ),
    );
  }
}
