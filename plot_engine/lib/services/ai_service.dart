import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_models.dart';
import '../l10n/app_localizations.dart';
import 'api_client.dart';

/// Service for AI-powered writing assistance
class AIService {
  final ApiClient _apiClient;

  AIService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  // ===== AI Writing Endpoints =====

  /// Ask AI a question about the project, chapter, or selection
  Future<AskAIResponse> askAI({
    required String projectId,
    required String question,
    AskContext context = AskContext.project,
    String? chapterId,
    String? selection,
    String provider = 'anthropic',
    String locale = 'en',
  }) async {
    final response = await _apiClient.post('/ai/ask', {
      'projectId': projectId,
      'question': question,
      'context': context.toJson(),
      if (chapterId != null) 'chapterId': chapterId,
      if (selection != null) 'selection': selection,
      'provider': provider,
      'locale': locale,
    });

    return AskAIResponse.fromJson(response);
  }

  /// Continue writing from where the chapter left off
  Future<ContinueWritingResponse> continueWriting({
    required String projectId,
    required String chapterId,
    String? prompt,
    int maxWords = 500,
    String provider = 'anthropic',
    String locale = 'en',
  }) async {
    final response = await _apiClient.post('/ai/write/continue', {
      'projectId': projectId,
      'chapterId': chapterId,
      if (prompt != null) 'prompt': prompt,
      'maxWords': maxWords,
      'provider': provider,
      'locale': locale,
    });

    return ContinueWritingResponse.fromJson(response);
  }

  /// Modify chapter content based on instructions
  Future<ModifyChapterResponse> modifyChapter({
    required String projectId,
    required String chapterId,
    required String prompt,
    String? selection,
    String provider = 'anthropic',
    String locale = 'en',
  }) async {
    final response = await _apiClient.post('/ai/write/modify', {
      'projectId': projectId,
      'chapterId': chapterId,
      'prompt': prompt,
      if (selection != null) 'selection': selection,
      'provider': provider,
      'locale': locale,
    });

    return ModifyChapterResponse.fromJson(response);
  }

  // ===== Entity Extraction =====

  /// Extract entities (characters, locations, objects, events) from text
  Future<ExtractedEntities> extractEntities({
    required String text,
    String provider = 'anthropic',
  }) async {
    final response = await _apiClient.post('/ai/extract/entities', {
      'text': text,
      'provider': provider,
    });

    final entities = response['entities'];
    if (entities == null) {
      return ExtractedEntities(
        characters: [],
        locations: [],
        objects: [],
        events: [],
        relationships: [],
      );
    }

    return ExtractedEntities.fromJson(entities as Map<String, dynamic>);
  }

  // ===== Consistency Checking =====

  /// Check a chapter for consistency issues against previous chapters
  Future<List<ConsistencyIssue>> checkConsistency({
    required String projectId,
    required String chapterId,
    int contextRange = 5,
    String locale = 'en',
  }) async {
    final response = await _apiClient.post('/ai/validate/consistency', {
      'projectId': projectId,
      'chapterId': chapterId,
      'contextRange': contextRange,
      'locale': locale,
    });

    print('[AIService] checkConsistency response: $response');

    final issues = response['issues'] as List? ?? [];
    return issues.map((i) => ConsistencyIssue.fromJson(i)).toList();
  }

  /// Validate timeline across entire project
  Future<List<TimelineIssue>> validateTimeline({
    required String projectId,
    String locale = 'en',
  }) async {
    final response = await _apiClient.post('/ai/validate/timeline', {
      'projectId': projectId,
      'locale': locale,
    });

    print('[AIService] validateTimeline response: $response');

    final issues = response['issues'] as List? ?? [];
    return issues.map((i) => TimelineIssue.fromJson(i)).toList();
  }

  // ===== Foreshadowing =====

  /// Get foreshadowing suggestions for a specific chapter
  Future<ForeshadowingSuggestions> getForeshadowingSuggestions({
    required String projectId,
    required String chapterId,
    String locale = 'en',
  }) async {
    final response = await _apiClient.post('/ai/suggest/foreshadow', {
      'projectId': projectId,
      'chapterId': chapterId,
      'locale': locale,
    });

    print('[AIService] getForeshadowingSuggestions response: $response');

    return ForeshadowingSuggestions.fromJson(
      response['suggestions'] as Map<String, dynamic>,
    );
  }

  /// Detect foreshadowing opportunities across the entire project
  Future<List<ForeshadowingOpportunity>> detectForeshadowingOpportunities({
    required String projectId,
    String locale = 'en',
  }) async {
    final response = await _apiClient.post('/ai/suggest/foreshadow/detect', {
      'projectId': projectId,
      'locale': locale,
    });

    final opportunities = response['opportunities'] as List? ?? [];
    return opportunities.map((o) => ForeshadowingOpportunity.fromJson(o)).toList();
  }
}

// Riverpod provider for AI service
final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
});

// ===== State Providers for AI Results =====

// Loading states
final aiLoadingProvider = StateProvider<bool>((ref) => false);
final aiErrorProvider = StateProvider<String?>((ref) => null);

// Consistency issues for current chapter
final consistencyIssuesProvider = StateProvider<List<ConsistencyIssue>>((ref) => []);

// Foreshadowing suggestions for current chapter
final foreshadowingSuggestionsProvider = StateProvider<ForeshadowingSuggestions?>((ref) => null);

// Extracted entities from current chapter
final extractedEntitiesProvider = StateProvider<ExtractedEntities?>((ref) => null);

// Timeline issues for project
final timelineIssuesProvider = StateProvider<List<TimelineIssue>>((ref) => []);

// Foreshadowing opportunities for project
final foreshadowingOpportunitiesProvider = StateProvider<List<ForeshadowingOpportunity>>((ref) => []);

// ===== AI Writing State Providers =====

/// State notifier for AI writing operations
class AIWritingNotifier extends StateNotifier<AIWritingState> {
  final AIService _aiService;
  final Ref _ref;

  AIWritingNotifier(this._aiService, this._ref) : super(const AIWritingState());

  /// Get current locale code for API calls
  String get _locale => _ref.read(localeProvider).apiLocaleCode;

  /// Ask AI a question
  Future<String?> askAI({
    required String projectId,
    required String question,
    AskContext context = AskContext.project,
    String? chapterId,
    String? selection,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _aiService.askAI(
        projectId: projectId,
        question: question,
        context: context,
        chapterId: chapterId,
        selection: selection,
        locale: _locale,
      );
      state = state.copyWith(
        isLoading: false,
        lastResponse: response.answer,
        lastAction: AIWritingAction.ask,
      );
      return response.answer;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Continue writing from chapter
  Future<String?> continueWriting({
    required String projectId,
    required String chapterId,
    String? prompt,
    int maxWords = 500,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _aiService.continueWriting(
        projectId: projectId,
        chapterId: chapterId,
        prompt: prompt,
        maxWords: maxWords,
        locale: _locale,
      );
      state = state.copyWith(
        isLoading: false,
        lastResponse: response.content,
        lastAction: AIWritingAction.continueWriting,
      );
      return response.content;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Modify chapter content
  Future<String?> modifyChapter({
    required String projectId,
    required String chapterId,
    required String prompt,
    String? selection,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _aiService.modifyChapter(
        projectId: projectId,
        chapterId: chapterId,
        prompt: prompt,
        selection: selection,
        locale: _locale,
      );
      state = state.copyWith(
        isLoading: false,
        lastResponse: response.content,
        lastAction: AIWritingAction.modify,
      );
      return response.content;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Clear the last response
  void clearResponse() {
    state = state.copyWith(lastResponse: null, lastAction: null);
  }
}

/// Provider for AI writing state notifier
final aiWritingProvider = StateNotifierProvider<AIWritingNotifier, AIWritingState>((ref) {
  return AIWritingNotifier(ref.read(aiServiceProvider), ref);
});
