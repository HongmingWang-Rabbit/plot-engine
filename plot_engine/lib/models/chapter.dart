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
}
