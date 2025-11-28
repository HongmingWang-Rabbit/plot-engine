enum AICommentType {
  character,
  plot,
  foreshadowing,
  consistency;

  static AICommentType fromString(String value) {
    return AICommentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AICommentType.plot,
    );
  }
}

class AIComment {
  final String id;
  final AICommentType type;
  final String message;
  final int position;
  final DateTime timestamp;

  const AIComment({
    required this.id,
    required this.type,
    required this.message,
    required this.position,
    required this.timestamp,
  });

  AIComment copyWith({
    String? id,
    AICommentType? type,
    String? message,
    int? position,
    DateTime? timestamp,
  }) {
    return AIComment(
      id: id ?? this.id,
      type: type ?? this.type,
      message: message ?? this.message,
      position: position ?? this.position,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'message': message,
      'position': position,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AIComment.fromJson(Map<String, dynamic> json) {
    return AIComment(
      id: json['id'] as String,
      type: AICommentType.fromString(json['type'] as String),
      message: json['message'] as String,
      position: json['position'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIComment &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
