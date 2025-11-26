import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_models.dart';
import 'api_client.dart';

/// Service for AI-powered writing assistance
class AIService {
  final ApiClient _apiClient;

  AIService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

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
  }) async {
    final response = await _apiClient.post('/ai/validate/consistency', {
      'projectId': projectId,
      'chapterId': chapterId,
      'contextRange': contextRange,
    });

    final issues = response['issues'] as List? ?? [];
    return issues.map((i) => ConsistencyIssue.fromJson(i)).toList();
  }

  /// Validate timeline across entire project
  Future<List<TimelineIssue>> validateTimeline({
    required String projectId,
  }) async {
    final response = await _apiClient.post('/ai/validate/timeline', {
      'projectId': projectId,
    });

    final issues = response['issues'] as List? ?? [];
    return issues.map((i) => TimelineIssue.fromJson(i)).toList();
  }

  // ===== Foreshadowing =====

  /// Get foreshadowing suggestions for a specific chapter
  Future<ForeshadowingSuggestions> getForeshadowingSuggestions({
    required String projectId,
    required String chapterId,
  }) async {
    final response = await _apiClient.post('/ai/suggest/foreshadow', {
      'projectId': projectId,
      'chapterId': chapterId,
    });

    return ForeshadowingSuggestions.fromJson(
      response['suggestions'] as Map<String, dynamic>,
    );
  }

  /// Detect foreshadowing opportunities across the entire project
  Future<List<ForeshadowingOpportunity>> detectForeshadowingOpportunities({
    required String projectId,
  }) async {
    final response = await _apiClient.post('/ai/suggest/foreshadow/detect', {
      'projectId': projectId,
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
