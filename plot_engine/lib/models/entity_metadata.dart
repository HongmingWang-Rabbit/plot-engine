import 'entity_type.dart';

class EntityMetadata {
  final String id;
  final String name;
  final EntityType type;
  final String? customType; // For custom tabs (e.g., "factions", "timelines")
  final String summary;
  final String description;

  EntityMetadata({
    String? id,
    required this.name,
    required this.type,
    this.customType,
    required this.summary,
    required this.description,
  }) : id = id ?? '${DateTime.now().millisecondsSinceEpoch}';

  EntityMetadata copyWith({
    String? name,
    EntityType? type,
    String? customType,
    String? summary,
    String? description,
  }) {
    return EntityMetadata(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      customType: customType ?? this.customType,
      summary: summary ?? this.summary,
      description: description ?? this.description,
    );
  }

  // Save only metadata (name, type, summary) - description is stored separately
  Map<String, dynamic> toMetadataJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      if (customType != null) 'customType': customType,
      'summary': summary,
    };
  }

  // Load metadata and description separately
  factory EntityMetadata.fromMetadataJson(Map<String, dynamic> json, String description) {
    return EntityMetadata(
      id: json['id'] as String,
      name: json['name'] as String,
      type: EntityType.fromString(json['type'] as String),
      customType: json['customType'] as String?,
      summary: json['summary'] as String,
      description: description,
    );
  }

  // Full JSON serialization (for backward compatibility)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      if (customType != null) 'customType': customType,
      'summary': summary,
      'description': description,
    };
  }

  factory EntityMetadata.fromJson(Map<String, dynamic> json) {
    return EntityMetadata(
      id: json['id'] as String?,
      name: json['name'] as String,
      type: EntityType.fromString(json['type'] as String),
      customType: json['customType'] as String?,
      summary: json['summary'] as String,
      description: json['description'] as String? ?? '',
    );
  }
}
