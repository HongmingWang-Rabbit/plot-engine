// Models for AI API responses

// ===== Consistency Check Models =====

class ConsistencyIssue {
  final String type;
  final String severity;
  final String description;
  final String suggestion;

  ConsistencyIssue({
    required this.type,
    required this.severity,
    required this.description,
    required this.suggestion,
  });

  factory ConsistencyIssue.fromJson(Map<String, dynamic> json) {
    return ConsistencyIssue(
      type: json['type'] as String? ?? '',
      severity: json['severity'] as String? ?? 'low',
      description: json['description'] as String? ?? '',
      suggestion: json['suggestion'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'severity': severity,
    'description': description,
    'suggestion': suggestion,
  };
}

// ===== Entity Extraction Models =====

class ExtractedEntity {
  final String name;
  final String description;
  final List<String>? traits;

  ExtractedEntity({
    required this.name,
    required this.description,
    this.traits,
  });

  factory ExtractedEntity.fromJson(Map<String, dynamic> json) {
    return ExtractedEntity(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      traits: (json['traits'] as List?)?.map((e) => e.toString()).toList(),
    );
  }
}

class ExtractedEvent {
  final String description;
  final List<String> charactersInvolved;

  ExtractedEvent({
    required this.description,
    required this.charactersInvolved,
  });

  factory ExtractedEvent.fromJson(Map<String, dynamic> json) {
    return ExtractedEvent(
      description: json['description'] as String? ?? '',
      charactersInvolved: (json['characters_involved'] as List?)
          ?.map((e) => e.toString())
          .toList() ?? [],
    );
  }
}

class ExtractedRelationship {
  final String character1;
  final String character2;
  final String type;
  final String description;

  ExtractedRelationship({
    required this.character1,
    required this.character2,
    required this.type,
    required this.description,
  });

  factory ExtractedRelationship.fromJson(Map<String, dynamic> json) {
    return ExtractedRelationship(
      character1: json['character1'] as String? ?? '',
      character2: json['character2'] as String? ?? '',
      type: json['type'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

class ExtractedEntities {
  final List<ExtractedEntity> characters;
  final List<ExtractedEntity> locations;
  final List<ExtractedEntity> objects;
  final List<ExtractedEvent> events;
  final List<ExtractedRelationship> relationships;

  ExtractedEntities({
    required this.characters,
    required this.locations,
    required this.objects,
    required this.events,
    required this.relationships,
  });

  factory ExtractedEntities.fromJson(Map<String, dynamic> json) {
    return ExtractedEntities(
      characters: (json['characters'] as List?)
          ?.map((e) => ExtractedEntity.fromJson(e))
          .toList() ?? [],
      locations: (json['locations'] as List?)
          ?.map((e) => ExtractedEntity.fromJson(e))
          .toList() ?? [],
      objects: (json['objects'] as List?)
          ?.map((e) => ExtractedEntity.fromJson(e))
          .toList() ?? [],
      events: (json['events'] as List?)
          ?.map((e) => ExtractedEvent.fromJson(e))
          .toList() ?? [],
      relationships: (json['relationships'] as List?)
          ?.map((e) => ExtractedRelationship.fromJson(e))
          .toList() ?? [],
    );
  }

  int get totalCount =>
      characters.length + locations.length + objects.length + events.length;
}

// ===== Foreshadowing Models =====

class ForeshadowingCallback {
  final int referenceChapter;
  final String element;
  final String suggestion;
  final String location;

  ForeshadowingCallback({
    required this.referenceChapter,
    required this.element,
    required this.suggestion,
    required this.location,
  });

  factory ForeshadowingCallback.fromJson(Map<String, dynamic> json) {
    return ForeshadowingCallback(
      referenceChapter: json['reference_chapter'] as int? ?? 0,
      element: json['element'] as String? ?? '',
      suggestion: json['suggestion'] as String? ?? '',
      location: json['location'] as String? ?? '',
    );
  }
}

class ForeshadowingSuggestion {
  final String type;
  final String suggestion;
  final String subtlety;

  ForeshadowingSuggestion({
    required this.type,
    required this.suggestion,
    required this.subtlety,
  });

  factory ForeshadowingSuggestion.fromJson(Map<String, dynamic> json) {
    return ForeshadowingSuggestion(
      type: json['type'] as String? ?? '',
      suggestion: json['suggestion'] as String? ?? '',
      subtlety: json['subtlety'] as String? ?? 'medium',
    );
  }
}

class ThematicResonance {
  final String theme;
  final String earlierOccurrence;
  final String suggestedEcho;

  ThematicResonance({
    required this.theme,
    required this.earlierOccurrence,
    required this.suggestedEcho,
  });

  factory ThematicResonance.fromJson(Map<String, dynamic> json) {
    return ThematicResonance(
      theme: json['theme'] as String? ?? '',
      earlierOccurrence: json['earlier_occurrence'] as String? ?? '',
      suggestedEcho: json['suggested_echo'] as String? ?? '',
    );
  }
}

class ForeshadowingSuggestions {
  final List<ForeshadowingCallback> callbacks;
  final List<ForeshadowingSuggestion> foreshadowing;
  final List<ThematicResonance> thematicResonances;

  ForeshadowingSuggestions({
    required this.callbacks,
    required this.foreshadowing,
    required this.thematicResonances,
  });

  factory ForeshadowingSuggestions.fromJson(Map<String, dynamic> json) {
    return ForeshadowingSuggestions(
      callbacks: (json['callbacks'] as List?)
          ?.map((e) => ForeshadowingCallback.fromJson(e))
          .toList() ?? [],
      foreshadowing: (json['foreshadowing'] as List?)
          ?.map((e) => ForeshadowingSuggestion.fromJson(e))
          .toList() ?? [],
      thematicResonances: (json['thematic_resonances'] as List?)
          ?.map((e) => ThematicResonance.fromJson(e))
          .toList() ?? [],
    );
  }

  int get totalCount =>
      callbacks.length + foreshadowing.length + thematicResonances.length;
}

// ===== Timeline Models =====

class TimelineIssue {
  final List<int> chapters;
  final String description;
  final String suggestion;

  TimelineIssue({
    required this.chapters,
    required this.description,
    required this.suggestion,
  });

  factory TimelineIssue.fromJson(Map<String, dynamic> json) {
    return TimelineIssue(
      chapters: (json['chapters'] as List?)
          ?.map((e) => e as int)
          .toList() ?? [],
      description: json['description'] as String? ?? '',
      suggestion: json['suggestion'] as String? ?? '',
    );
  }
}

// ===== Foreshadowing Opportunity Models =====

class ForeshadowingOpportunity {
  final int targetChapter;
  final String element;
  final List<int> couldBeForeshadowedIn;
  final String suggestion;

  ForeshadowingOpportunity({
    required this.targetChapter,
    required this.element,
    required this.couldBeForeshadowedIn,
    required this.suggestion,
  });

  factory ForeshadowingOpportunity.fromJson(Map<String, dynamic> json) {
    return ForeshadowingOpportunity(
      targetChapter: json['target_chapter'] as int? ?? 0,
      element: json['element'] as String? ?? '',
      couldBeForeshadowedIn: (json['could_be_foreshadowed_in'] as List?)
          ?.map((e) => e as int)
          .toList() ?? [],
      suggestion: json['suggestion'] as String? ?? '',
    );
  }
}

// ===== AI Writing Models =====

/// Token usage information from AI responses
class AIUsage {
  final int inputTokens;
  final int outputTokens;

  AIUsage({
    required this.inputTokens,
    required this.outputTokens,
  });

  factory AIUsage.fromJson(Map<String, dynamic> json) {
    return AIUsage(
      inputTokens: json['input_tokens'] as int? ?? 0,
      outputTokens: json['output_tokens'] as int? ?? 0,
    );
  }
}

/// Response from the Ask AI endpoint
class AskAIResponse {
  final String answer;
  final String provider;
  final String model;
  final AIUsage usage;

  AskAIResponse({
    required this.answer,
    required this.provider,
    required this.model,
    required this.usage,
  });

  factory AskAIResponse.fromJson(Map<String, dynamic> json) {
    return AskAIResponse(
      answer: json['answer'] as String? ?? '',
      provider: json['provider'] as String? ?? 'anthropic',
      model: json['model'] as String? ?? '',
      usage: AIUsage.fromJson(json['usage'] as Map<String, dynamic>? ?? {}),
    );
  }
}

/// Context level for Ask AI requests
enum AskContext {
  project,
  chapter,
  selection;

  String toJson() => name;
}

/// Response from the Continue Writing endpoint
class ContinueWritingResponse {
  final String content;
  final String provider;
  final String model;
  final AIUsage usage;

  ContinueWritingResponse({
    required this.content,
    required this.provider,
    required this.model,
    required this.usage,
  });

  factory ContinueWritingResponse.fromJson(Map<String, dynamic> json) {
    return ContinueWritingResponse(
      content: json['content'] as String? ?? '',
      provider: json['provider'] as String? ?? 'anthropic',
      model: json['model'] as String? ?? '',
      usage: AIUsage.fromJson(json['usage'] as Map<String, dynamic>? ?? {}),
    );
  }
}

/// Response from the Modify Chapter endpoint
class ModifyChapterResponse {
  final String content;
  final bool isFullChapter;
  final String provider;
  final String model;
  final AIUsage usage;

  ModifyChapterResponse({
    required this.content,
    required this.isFullChapter,
    required this.provider,
    required this.model,
    required this.usage,
  });

  factory ModifyChapterResponse.fromJson(Map<String, dynamic> json) {
    return ModifyChapterResponse(
      content: json['content'] as String? ?? '',
      isFullChapter: json['isFullChapter'] as bool? ?? false,
      provider: json['provider'] as String? ?? 'anthropic',
      model: json['model'] as String? ?? '',
      usage: AIUsage.fromJson(json['usage'] as Map<String, dynamic>? ?? {}),
    );
  }
}

/// State for AI writing operations
class AIWritingState {
  final bool isLoading;
  final String? error;
  final String? lastResponse;
  final AIWritingAction? lastAction;

  const AIWritingState({
    this.isLoading = false,
    this.error,
    this.lastResponse,
    this.lastAction,
  });

  AIWritingState copyWith({
    bool? isLoading,
    String? error,
    String? lastResponse,
    AIWritingAction? lastAction,
  }) {
    return AIWritingState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastResponse: lastResponse ?? this.lastResponse,
      lastAction: lastAction ?? this.lastAction,
    );
  }
}

/// Type of AI writing action
enum AIWritingAction {
  ask,
  continueWriting,
  modify,
}

// ===== AI Suggestion Message Models =====

/// Type of AI suggestion
enum AISuggestionType {
  consistency,
  foreshadowing,
  characterDevelopment,
  plotHole,
  pacing,
  dialogue,
  general,
}

/// Priority/severity of the suggestion
enum AISuggestionPriority {
  high,
  medium,
  low,
}

/// A single AI suggestion message
class AISuggestion {
  final String id;
  final AISuggestionType type;
  final AISuggestionPriority priority;
  final String title;
  final String summary;
  final String? details;
  final String? suggestion;
  final String? location; // Where in the text this applies
  final String chapterId;
  final DateTime createdAt;
  final bool isRead;
  final bool isDismissed;

  const AISuggestion({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.summary,
    this.details,
    this.suggestion,
    this.location,
    required this.chapterId,
    required this.createdAt,
    this.isRead = false,
    this.isDismissed = false,
  });

  AISuggestion copyWith({
    bool? isRead,
    bool? isDismissed,
  }) {
    return AISuggestion(
      id: id,
      type: type,
      priority: priority,
      title: title,
      summary: summary,
      details: details,
      suggestion: suggestion,
      location: location,
      chapterId: chapterId,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }

  String get typeLabel {
    switch (type) {
      case AISuggestionType.consistency:
        return 'Consistency';
      case AISuggestionType.foreshadowing:
        return 'Foreshadowing';
      case AISuggestionType.characterDevelopment:
        return 'Character';
      case AISuggestionType.plotHole:
        return 'Plot Hole';
      case AISuggestionType.pacing:
        return 'Pacing';
      case AISuggestionType.dialogue:
        return 'Dialogue';
      case AISuggestionType.general:
        return 'Suggestion';
    }
  }
}

/// State for the AI suggestion queue
class AISuggestionQueueState {
  final List<AISuggestion> suggestions;
  final bool isAnalyzing;
  final String? currentChapterId;
  final int lastAnalyzedLength;

  const AISuggestionQueueState({
    this.suggestions = const [],
    this.isAnalyzing = false,
    this.currentChapterId,
    this.lastAnalyzedLength = 0,
  });

  AISuggestionQueueState copyWith({
    List<AISuggestion>? suggestions,
    bool? isAnalyzing,
    String? currentChapterId,
    int? lastAnalyzedLength,
  }) {
    return AISuggestionQueueState(
      suggestions: suggestions ?? this.suggestions,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      currentChapterId: currentChapterId ?? this.currentChapterId,
      lastAnalyzedLength: lastAnalyzedLength ?? this.lastAnalyzedLength,
    );
  }

  /// Get unread suggestions for current chapter
  List<AISuggestion> get unreadSuggestions =>
      suggestions.where((s) => !s.isRead && !s.isDismissed).toList();

  /// Get all active (not dismissed) suggestions for current chapter
  List<AISuggestion> get activeSuggestions =>
      suggestions.where((s) => !s.isDismissed).toList();

  /// Count of unread suggestions
  int get unreadCount => unreadSuggestions.length;
}
