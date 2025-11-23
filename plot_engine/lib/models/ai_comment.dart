class AIComment {
  final String id;
  final String type; // 'character', 'plot', 'foreshadowing', 'consistency'
  final String message;
  final int position; // character position in text
  final DateTime timestamp;

  AIComment({
    required this.id,
    required this.type,
    required this.message,
    required this.position,
    required this.timestamp,
  });
}
