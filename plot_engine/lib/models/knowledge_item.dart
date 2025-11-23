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
}
