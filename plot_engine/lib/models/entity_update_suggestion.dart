/// Represents a suggestion for updating an entity with new information
/// found in chapter content.
class EntityUpdateSuggestion {
  final String entityId;
  final String entityName;
  final String entityType;
  final String newInformation;
  final String suggestedAppendText;
  final List<String> relevantQuotes;

  const EntityUpdateSuggestion({
    required this.entityId,
    required this.entityName,
    required this.entityType,
    required this.newInformation,
    required this.suggestedAppendText,
    required this.relevantQuotes,
  });

  factory EntityUpdateSuggestion.fromJson(Map<String, dynamic> json) {
    return EntityUpdateSuggestion(
      entityId: json['entityId'] as String,
      entityName: json['entityName'] as String,
      entityType: json['entityType'] as String,
      newInformation: json['newInformation'] as String,
      suggestedAppendText: json['suggestedAppendText'] as String,
      relevantQuotes: (json['relevantQuotes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entityId': entityId,
      'entityName': entityName,
      'entityType': entityType,
      'newInformation': newInformation,
      'suggestedAppendText': suggestedAppendText,
      'relevantQuotes': relevantQuotes,
    };
  }
}

/// Response from the suggest-updates endpoint
class SuggestUpdatesResponse {
  final List<EntityUpdateSuggestion> suggestions;
  final String provider;
  final String model;
  final int? inputTokens;
  final int? outputTokens;

  const SuggestUpdatesResponse({
    required this.suggestions,
    required this.provider,
    required this.model,
    this.inputTokens,
    this.outputTokens,
  });

  factory SuggestUpdatesResponse.fromJson(Map<String, dynamic> json) {
    final usage = json['usage'] as Map<String, dynamic>?;
    return SuggestUpdatesResponse(
      suggestions: (json['suggestions'] as List<dynamic>?)
              ?.map((e) => EntityUpdateSuggestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      provider: json['provider'] as String? ?? 'openai',
      model: json['model'] as String? ?? '',
      inputTokens: usage?['input_tokens'] as int?,
      outputTokens: usage?['output_tokens'] as int?,
    );
  }
}

/// Response from the merge endpoint
class MergeEntityResponse {
  final String entityId;
  final String entityName;
  final String description;
  final String summary;
  final String provider;
  final String model;
  final int? inputTokens;
  final int? outputTokens;

  const MergeEntityResponse({
    required this.entityId,
    required this.entityName,
    required this.description,
    required this.summary,
    required this.provider,
    required this.model,
    this.inputTokens,
    this.outputTokens,
  });

  factory MergeEntityResponse.fromJson(Map<String, dynamic> json) {
    final usage = json['usage'] as Map<String, dynamic>?;
    return MergeEntityResponse(
      entityId: json['entityId'] as String,
      entityName: json['entityName'] as String,
      description: json['description'] as String,
      summary: json['summary'] as String,
      provider: json['provider'] as String? ?? 'openai',
      model: json['model'] as String? ?? '',
      inputTokens: usage?['input_tokens'] as int?,
      outputTokens: usage?['output_tokens'] as int?,
    );
  }
}
