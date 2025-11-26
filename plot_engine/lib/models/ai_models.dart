/// Models for AI API responses

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
