class KnowledgeTab {
  final String id;
  final String name;
  final String icon; // Material icon name
  final String? customIconPath; // Path to custom image file (relative to project)
  final bool isDeletable; // false for "Chapters" tab
  final int order;

  KnowledgeTab({
    required this.id,
    required this.name,
    required this.icon,
    this.customIconPath,
    this.isDeletable = true,
    required this.order,
  });

  bool get hasCustomIcon => customIconPath != null && customIconPath!.isNotEmpty;

  KnowledgeTab copyWith({
    String? id,
    String? name,
    String? icon,
    String? customIconPath,
    bool? isDeletable,
    int? order,
  }) {
    return KnowledgeTab(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      customIconPath: customIconPath ?? this.customIconPath,
      isDeletable: isDeletable ?? this.isDeletable,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      if (customIconPath != null) 'customIconPath': customIconPath,
      'isDeletable': isDeletable,
      'order': order,
    };
  }

  factory KnowledgeTab.fromJson(Map<String, dynamic> json) {
    return KnowledgeTab(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      customIconPath: json['customIconPath'] as String?,
      isDeletable: json['isDeletable'] as bool? ?? true,
      order: json['order'] as int,
    );
  }

  // Default tabs
  static KnowledgeTab chaptersTab() {
    return KnowledgeTab(
      id: 'chapters',
      name: 'Chapters',
      icon: 'menu_book',
      isDeletable: false,
      order: 0,
    );
  }

  static List<KnowledgeTab> defaultTabs() {
    return [
      chaptersTab(),
      KnowledgeTab(
        id: 'characters',
        name: 'Characters',
        icon: 'person',
        order: 1,
      ),
      KnowledgeTab(
        id: 'locations',
        name: 'Locations',
        icon: 'place',
        order: 2,
      ),
      KnowledgeTab(
        id: 'objects',
        name: 'Objects',
        icon: 'category',
        order: 3,
      ),
      KnowledgeTab(
        id: 'settings',
        name: 'Settings',
        icon: 'tune',
        order: 4,
      ),
      KnowledgeTab(
        id: 'timeline',
        name: 'Timeline',
        icon: 'schedule',
        order: 5,
      ),
    ];
  }
}
