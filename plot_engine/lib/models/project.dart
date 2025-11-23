import 'knowledge_tab.dart';

class Project {
  final String id;
  final String name;
  final String path;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<KnowledgeTab> knowledgeTabs;

  Project({
    required this.id,
    required this.name,
    required this.path,
    required this.createdAt,
    required this.updatedAt,
    List<KnowledgeTab>? knowledgeTabs,
  }) : knowledgeTabs = knowledgeTabs ?? KnowledgeTab.defaultTabs();

  Project copyWith({
    String? id,
    String? name,
    String? path,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<KnowledgeTab>? knowledgeTabs,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      knowledgeTabs: knowledgeTabs ?? this.knowledgeTabs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'knowledgeTabs': knowledgeTabs.map((t) => t.toJson()).toList(),
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      knowledgeTabs: (json['knowledgeTabs'] as List<dynamic>?)
              ?.map((t) => KnowledgeTab.fromJson(t as Map<String, dynamic>))
              .toList() ??
          KnowledgeTab.defaultTabs(),
    );
  }
}
