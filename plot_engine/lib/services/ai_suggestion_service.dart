import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_models.dart';
import '../state/app_state.dart';
import '../state/settings_state.dart';
import '../l10n/app_localizations.dart';
import 'ai_service.dart';

/// Minimum characters of new content before triggering analysis
const int _minNewContentLength = 200;

/// Debounce duration after typing stops
const Duration _debounceDuration = Duration(seconds: 3);

/// Delay before analyzing a newly opened file
const Duration _newFileAnalysisDelay = Duration(seconds: 5);

/// Service that watches content changes and automatically triggers AI analysis
class AISuggestionNotifier extends StateNotifier<AISuggestionQueueState> {
  final AIService _aiService;
  final Ref _ref;
  Timer? _debounceTimer;
  Timer? _newFileTimer;

  AISuggestionNotifier(this._aiService, this._ref) : super(const AISuggestionQueueState());

  /// Check if background AI analysis is enabled
  bool get _isAnalysisEnabled => _ref.read(aiBackgroundAnalysisProvider);

  /// Called when content changes - checks if we should trigger analysis
  void onContentChanged(String content, String chapterId, String projectId) {
    // Reset if chapter changed
    if (state.currentChapterId != chapterId) {
      print('[AI Suggestion] Chapter changed to: $chapterId');

      // Cancel any existing timers
      _debounceTimer?.cancel();
      _newFileTimer?.cancel();

      state = state.copyWith(
        currentChapterId: chapterId,
        lastAnalyzedLength: 0,
        suggestions: state.suggestions.where((s) => s.chapterId == chapterId).toList(),
      );

      // Only schedule analysis if enabled
      if (_isAnalysisEnabled) {
        // Schedule analysis for newly opened file after 10 seconds
        print('[AI Suggestion] New file opened, scheduling initial analysis in ${_newFileAnalysisDelay.inSeconds}s...');
        _newFileTimer = Timer(_newFileAnalysisDelay, () {
          print('[AI Suggestion] New file timer fired, running initial analysis...');
          _runAnalysis(content, chapterId, projectId);
        });
      } else {
        print('[AI Suggestion] Background analysis disabled, skipping auto-analysis');
      }

      return; // Don't check for content length on first open
    }

    // Cancel the new file timer if user starts typing
    if (_newFileTimer?.isActive == true) {
      print('[AI Suggestion] User typing detected, cancelling new file timer');
      _newFileTimer?.cancel();
    }

    // Skip if analysis is disabled
    if (!_isAnalysisEnabled) {
      return;
    }

    // Cancel any pending content-based analysis
    _debounceTimer?.cancel();

    // Calculate new content added
    final newContentLength = content.length - state.lastAnalyzedLength;

    print('[AI Suggestion] Content changed: ${content.length} chars total, $newContentLength new chars (need $_minNewContentLength to trigger)');

    // Check if we have enough new content (about a paragraph)
    if (newContentLength >= _minNewContentLength) {
      print('[AI Suggestion] Scheduling analysis in ${_debounceDuration.inSeconds}s...');
      // Debounce - wait for user to stop typing
      _debounceTimer = Timer(_debounceDuration, () {
        _runAnalysis(content, chapterId, projectId);
      });
    }
  }

  /// Get current locale code for API calls
  String get _locale => _ref.read(localeProvider).apiLocaleCode;

  /// Get translation for a key
  String _tr(String key) => L10n.get(_ref.read(localeProvider), key);

  /// Run AI analysis on the content
  Future<void> _runAnalysis(String content, String chapterId, String projectId) async {
    if (state.isAnalyzing) {
      print('[AI Suggestion] Already analyzing, skipping...');
      return;
    }

    print('[AI Suggestion] ▶ Starting analysis for chapter: $chapterId');
    state = state.copyWith(isAnalyzing: true);

    final newSuggestions = <AISuggestion>[];
    final locale = _locale;

    // 1. Run consistency check
    try {
      print('[AI Suggestion] Calling /ai/validate/consistency...');
      final issues = await _aiService.checkConsistency(
        projectId: projectId,
        chapterId: chapterId,
        locale: locale,
      );
      print('[AI Suggestion] ✓ Consistency: ${issues.length} issues');

      for (final issue in issues) {
        newSuggestions.add(AISuggestion(
          id: 'consistency_${DateTime.now().millisecondsSinceEpoch}_${newSuggestions.length}',
          type: _mapIssueType(issue.type),
          priority: _mapSeverity(issue.severity),
          title: _getTitleForType(issue.type),
          summary: issue.description,
          suggestion: issue.suggestion,
          chapterId: chapterId,
          createdAt: DateTime.now(),
        ));
      }
    } catch (e) {
      print('[AI Suggestion] ✗ Consistency check failed: $e');
    }

    // 2. Run foreshadowing suggestions
    try {
      print('[AI Suggestion] Calling /ai/suggest/foreshadowing...');
      final foreshadowing = await _aiService.getForeshadowingSuggestions(
        projectId: projectId,
        chapterId: chapterId,
        locale: locale,
      );
      print('[AI Suggestion] ✓ Foreshadowing: ${foreshadowing.totalCount} suggestions');

      // Add callbacks
      for (final callback in foreshadowing.callbacks) {
        newSuggestions.add(AISuggestion(
          id: 'callback_${DateTime.now().millisecondsSinceEpoch}_${newSuggestions.length}',
          type: AISuggestionType.foreshadowing,
          priority: AISuggestionPriority.medium,
          title: '${_tr('suggestion_callback_to_chapter')} ${callback.referenceChapter}',
          summary: callback.element,
          suggestion: callback.suggestion,
          location: callback.location,
          chapterId: chapterId,
          createdAt: DateTime.now(),
        ));
      }

      // Add foreshadowing suggestions
      for (final fs in foreshadowing.foreshadowing) {
        newSuggestions.add(AISuggestion(
          id: 'foreshadow_${DateTime.now().millisecondsSinceEpoch}_${newSuggestions.length}',
          type: AISuggestionType.foreshadowing,
          priority: _mapSubtlety(fs.subtlety),
          title: '${_tr('suggestion_foreshadowing')}: ${fs.type}',
          summary: fs.suggestion,
          chapterId: chapterId,
          createdAt: DateTime.now(),
        ));
      }

      // Add thematic resonances
      for (final theme in foreshadowing.thematicResonances) {
        newSuggestions.add(AISuggestion(
          id: 'theme_${DateTime.now().millisecondsSinceEpoch}_${newSuggestions.length}',
          type: AISuggestionType.foreshadowing,
          priority: AISuggestionPriority.low,
          title: '${_tr('suggestion_theme')}: ${theme.theme}',
          summary: theme.earlierOccurrence,
          suggestion: theme.suggestedEcho,
          chapterId: chapterId,
          createdAt: DateTime.now(),
        ));
      }
    } catch (e) {
      print('[AI Suggestion] ✗ Foreshadowing check failed: $e');
    }

    // 3. Run timeline validation
    try {
      print('[AI Suggestion] Calling /ai/validate/timeline...');
      final timelineIssues = await _aiService.validateTimeline(
        projectId: projectId,
        locale: locale,
      );
      print('[AI Suggestion] ✓ Timeline: ${timelineIssues.length} issues');

      for (final issue in timelineIssues) {
        newSuggestions.add(AISuggestion(
          id: 'timeline_${DateTime.now().millisecondsSinceEpoch}_${newSuggestions.length}',
          type: AISuggestionType.consistency,
          priority: AISuggestionPriority.medium,
          title: _tr('suggestion_timeline_issue'),
          summary: issue.description,
          suggestion: issue.suggestion,
          details: '${_tr('suggestion_chapters_involved')}: ${issue.chapters.join(", ")}',
          chapterId: chapterId,
          createdAt: DateTime.now(),
        ));
      }
    } catch (e) {
      print('[AI Suggestion] ✗ Timeline check failed: $e');
    }

    // 4. Run entity update suggestions
    try {
      print('[AI Suggestion] Calling /ai/entities/suggest-updates...');
      final backend = _ref.read(backendProjectServiceProvider);
      final entityUpdates = await backend.suggestEntityUpdates(
        projectId: projectId,
        chapterContent: content,
        locale: locale,
      );
      print('[AI Suggestion] ✓ Entity Updates: ${entityUpdates.suggestions.length} suggestions');

      for (final suggestion in entityUpdates.suggestions) {
        newSuggestions.add(AISuggestion(
          id: 'entity_${DateTime.now().millisecondsSinceEpoch}_${newSuggestions.length}',
          type: AISuggestionType.entityUpdate,
          priority: AISuggestionPriority.medium,
          title: '${_tr('suggestion_entity_update')}: ${suggestion.entityName}',
          summary: suggestion.newInformation,
          suggestion: suggestion.suggestedAppendText,
          details: suggestion.relevantQuotes.isNotEmpty
              ? '${_tr('relevant_quotes')}: "${suggestion.relevantQuotes.first}"'
              : null,
          chapterId: chapterId,
          createdAt: DateTime.now(),
        ));
      }

      // Also update the entity update provider state for the dedicated UI
      _ref.read(entityUpdateProvider.notifier).setSuggestions(entityUpdates.suggestions);
    } catch (e) {
      print('[AI Suggestion] ✗ Entity update check failed: $e');
    }

    // Add new suggestions to the queue (avoid duplicates based on summary)
    final existingSummaries = state.suggestions.map((s) => s.summary).toSet();
    final uniqueNewSuggestions = newSuggestions
        .where((s) => !existingSummaries.contains(s.summary))
        .toList();

    print('[AI Suggestion] ✓ Added ${uniqueNewSuggestions.length} new suggestions (${newSuggestions.length - uniqueNewSuggestions.length} duplicates filtered)');

    state = state.copyWith(
      suggestions: [...state.suggestions, ...uniqueNewSuggestions],
      lastAnalyzedLength: content.length,
      isAnalyzing: false,
    );

    print('[AI Suggestion] ✓ Analysis complete. Total suggestions: ${state.suggestions.length}');
  }

  /// Manually trigger analysis (for user-initiated checks)
  Future<void> analyzeNow() async {
    final chapter = _ref.read(currentChapterProvider);
    final project = _ref.read(projectProvider);
    if (chapter == null || project == null) return;

    await _runAnalysis(chapter.content, chapter.id, project.id);
  }

  /// Mark a suggestion as read
  void markAsRead(String suggestionId) {
    state = state.copyWith(
      suggestions: state.suggestions.map((s) {
        if (s.id == suggestionId) {
          return s.copyWith(isRead: true);
        }
        return s;
      }).toList(),
    );
  }

  /// Dismiss a suggestion
  void dismiss(String suggestionId) {
    state = state.copyWith(
      suggestions: state.suggestions.map((s) {
        if (s.id == suggestionId) {
          return s.copyWith(isDismissed: true);
        }
        return s;
      }).toList(),
    );
  }

  /// Clear all suggestions for current chapter
  void clearAll() {
    state = state.copyWith(
      suggestions: state.suggestions
          .where((s) => s.chapterId != state.currentChapterId)
          .toList(),
    );
  }

  /// Clear dismissed suggestions
  void clearDismissed() {
    state = state.copyWith(
      suggestions: state.suggestions.where((s) => !s.isDismissed).toList(),
    );
  }

  AISuggestionType _mapIssueType(String type) {
    switch (type.toLowerCase()) {
      case 'consistency':
      case 'contradiction':
        return AISuggestionType.consistency;
      case 'plot_hole':
      case 'plothole':
        return AISuggestionType.plotHole;
      case 'character':
      case 'character_development':
        return AISuggestionType.characterDevelopment;
      case 'pacing':
        return AISuggestionType.pacing;
      case 'dialogue':
        return AISuggestionType.dialogue;
      case 'foreshadowing':
        return AISuggestionType.foreshadowing;
      default:
        return AISuggestionType.general;
    }
  }

  AISuggestionPriority _mapSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'critical':
        return AISuggestionPriority.high;
      case 'medium':
        return AISuggestionPriority.medium;
      case 'low':
      default:
        return AISuggestionPriority.low;
    }
  }

  AISuggestionPriority _mapSubtlety(String subtlety) {
    // Higher subtlety = lower priority (subtle suggestions are less urgent)
    switch (subtlety.toLowerCase()) {
      case 'low':
        return AISuggestionPriority.high; // Low subtlety = obvious, high priority
      case 'medium':
        return AISuggestionPriority.medium;
      case 'high':
      default:
        return AISuggestionPriority.low; // High subtlety = subtle, low priority
    }
  }

  String _getTitleForType(String type) {
    switch (type.toLowerCase()) {
      case 'consistency':
      case 'contradiction':
        return _tr('suggestion_consistency_issue');
      case 'plot_hole':
      case 'plothole':
        return _tr('suggestion_plot_hole');
      case 'character':
        return _tr('suggestion_character_issue');
      case 'pacing':
        return _tr('suggestion_pacing');
      case 'dialogue':
        return _tr('suggestion_dialogue');
      default:
        return _tr('suggestion_writing');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _newFileTimer?.cancel();
    super.dispose();
  }
}

/// Provider for the AI suggestion queue
final aiSuggestionProvider = StateNotifierProvider<AISuggestionNotifier, AISuggestionQueueState>((ref) {
  final aiService = ref.read(aiServiceProvider);
  return AISuggestionNotifier(aiService, ref);
});

/// Provider for currently selected/expanded suggestion
final selectedSuggestionProvider = StateProvider<AISuggestion?>((ref) => null);
