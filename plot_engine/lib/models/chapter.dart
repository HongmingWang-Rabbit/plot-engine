class Chapter {
  final String id;
  final String title;
  final String content;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  Chapter({
    required this.id,
    required this.title,
    required this.content,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  Chapter copyWith({
    String? id,
    String? title,
    String? content,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Chapter(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Metadata only (for chapters.json) - content stored separately
  Map<String, dynamic> toMetadataJson() {
    return {
      'id': id,
      'title': title,
      'order': order,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create chapter from metadata JSON (content loaded separately)
  factory Chapter.fromMetadataJson(Map<String, dynamic> json, String content) {
    return Chapter(
      id: json['id'] as String,
      title: json['title'] as String,
      content: content,
      order: json['order'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  // Full JSON serialization (backward compatibility)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'order': order,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String? ?? '',
      order: json['order'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
