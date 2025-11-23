class KnowledgeItem {
  final String id;
  final String name;
  final String type; // 'character', 'location', 'object', 'event'
  final String description;
  final List<String> appearances; // chapter IDs where this appears

  KnowledgeItem({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    this.appearances = const [],
  });

  KnowledgeItem copyWith({
    String? id,
    String? name,
    String? type,
    String? description,
    List<String>? appearances,
  }) {
    return KnowledgeItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      appearances: appearances ?? this.appearances,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'description': description,
      'appearances': appearances,
    };
  }

  factory KnowledgeItem.fromJson(Map<String, dynamic> json) {
    return KnowledgeItem(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      appearances: (json['appearances'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}
