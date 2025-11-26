import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chapter.dart';
import '../models/entity_metadata.dart';

/// Type of content in a tab
enum TabContentType {
  chapter,
  entity,
}

/// Represents a tab in the editor
class EditorTab {
  final String id; // Unique ID for the tab
  final String title; // Display title
  final TabContentType type;
  final Chapter? chapter; // For chapter tabs
  final EntityMetadata? entity; // For entity tabs
  final bool isModified;
  final bool isPreview; // Preview tabs are shown in italics and can be replaced

  EditorTab({
    required this.id,
    required this.title,
    required this.type,
    this.chapter,
    this.entity,
    this.isModified = false,
    this.isPreview = false,
  });

  // Constructor for chapter tabs
  factory EditorTab.chapter({
    required Chapter chapter,
    bool isModified = false,
    bool isPreview = false,
  }) {
    return EditorTab(
      id: 'chapter-${chapter.id}',
      title: chapter.title,
      type: TabContentType.chapter,
      chapter: chapter,
      isModified: isModified,
      isPreview: isPreview,
    );
  }

  // Constructor for entity tabs
  factory EditorTab.entity({
    required EntityMetadata entity,
    bool isPreview = false,
  }) {
    return EditorTab(
      id: 'entity-${entity.id}',
      title: entity.name,
      type: TabContentType.entity,
      entity: entity,
      isPreview: isPreview,
    );
  }

  EditorTab copyWith({
    String? title,
    Chapter? chapter,
    EntityMetadata? entity,
    bool? isModified,
    bool? isPreview,
  }) {
    return EditorTab(
      id: id,
      title: title ?? this.title,
      type: type,
      chapter: chapter ?? this.chapter,
      entity: entity ?? this.entity,
      isModified: isModified ?? this.isModified,
      isPreview: isPreview ?? this.isPreview,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorTab &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Tab state containing all open tabs and the active tab
class TabState {
  final List<EditorTab> tabs;
  final String? activeTabId; // Tab ID of the active tab

  TabState({
    this.tabs = const [],
    this.activeTabId,
  });

  EditorTab? get activeTab =>
      tabs.where((tab) => tab.id == activeTabId).firstOrNull;

  TabState copyWith({
    List<EditorTab>? tabs,
    String? activeTabId,
  }) {
    return TabState(
      tabs: tabs ?? this.tabs,
      activeTabId: activeTabId ?? this.activeTabId,
    );
  }
}

/// Notifier for managing editor tabs
class TabStateNotifier extends StateNotifier<TabState> {
  TabStateNotifier() : super(TabState());

  /// Open a chapter in preview mode (replaces existing preview tab)
  void openPreview(Chapter chapter) {
    final tabs = List<EditorTab>.from(state.tabs);
    final tabId = 'chapter-${chapter.id}';

    // Check if chapter is already open
    final existingIndex = tabs.indexWhere((tab) => tab.id == tabId);
    if (existingIndex != -1) {
      // Just activate it
      state = state.copyWith(activeTabId: tabId);
      return;
    }

    // Remove existing preview tab if any
    tabs.removeWhere((tab) => tab.isPreview);

    // Add new preview tab
    tabs.add(EditorTab.chapter(chapter: chapter, isPreview: true));

    state = TabState(
      tabs: tabs,
      activeTabId: tabId,
    );
  }

  /// Open an entity in preview mode (replaces existing preview tab)
  void openEntityPreview(EntityMetadata entity) {
    final tabs = List<EditorTab>.from(state.tabs);
    final tabId = 'entity-${entity.id}';

    // Check if entity is already open
    final existingIndex = tabs.indexWhere((tab) => tab.id == tabId);
    if (existingIndex != -1) {
      // Just activate it
      state = state.copyWith(activeTabId: tabId);
      return;
    }

    // Remove existing preview tab if any
    tabs.removeWhere((tab) => tab.isPreview);

    // Add new entity preview tab
    tabs.add(EditorTab.entity(entity: entity, isPreview: true));

    state = TabState(
      tabs: tabs,
      activeTabId: tabId,
    );
  }

  /// Convert preview tab to permanent tab (when user starts typing)
  void makeTabPermanent(String chapterId) {
    final tabId = 'chapter-$chapterId';
    final tabs = state.tabs.map((tab) {
      if (tab.id == tabId && tab.isPreview) {
        return tab.copyWith(isPreview: false);
      }
      return tab;
    }).toList();

    state = state.copyWith(tabs: tabs);
  }

  /// Mark a tab as modified (unsaved changes)
  void markTabModified(String chapterId, bool isModified) {
    final tabId = 'chapter-$chapterId';
    final tabs = state.tabs.map((tab) {
      if (tab.id == tabId) {
        return tab.copyWith(isModified: isModified);
      }
      return tab;
    }).toList();

    state = state.copyWith(tabs: tabs);
  }

  /// Update chapter content in a tab
  void updateTabChapter(Chapter updatedChapter) {
    final tabId = 'chapter-${updatedChapter.id}';
    final tabs = state.tabs.map((tab) {
      if (tab.id == tabId) {
        return tab.copyWith(chapter: updatedChapter);
      }
      return tab;
    }).toList();

    state = state.copyWith(tabs: tabs);
  }

  /// Update just the chapter title in a tab
  void updateTabChapterTitle(String chapterId, String newTitle) {
    final tabId = 'chapter-$chapterId';
    final tabs = state.tabs.map((tab) {
      if (tab.id == tabId && tab.chapter != null) {
        final updatedChapter = tab.chapter!.copyWith(title: newTitle);
        return tab.copyWith(title: newTitle, chapter: updatedChapter);
      }
      return tab;
    }).toList();

    state = state.copyWith(tabs: tabs);
  }

  /// Update entity content in a tab
  void updateTabEntity(EntityMetadata updatedEntity) {
    final tabId = 'entity-${updatedEntity.id}';
    final tabs = state.tabs.map((tab) {
      if (tab.id == tabId) {
        return tab.copyWith(entity: updatedEntity);
      }
      return tab;
    }).toList();

    state = state.copyWith(tabs: tabs);
  }

  /// Activate a specific tab by ID
  void activateTab(String tabId) {
    state = state.copyWith(activeTabId: tabId);
  }

  /// Close a tab by ID
  void closeTab(String tabId) {
    final tabs = List<EditorTab>.from(state.tabs);
    final closingIndex = tabs.indexWhere((tab) => tab.id == tabId);

    if (closingIndex == -1) return;

    tabs.removeAt(closingIndex);

    // If we're closing the active tab, activate another one
    String? newActiveTabId = state.activeTabId;
    if (state.activeTabId == tabId) {
      if (tabs.isEmpty) {
        newActiveTabId = null;
      } else if (closingIndex < tabs.length) {
        // Activate the tab that's now in the same position
        newActiveTabId = tabs[closingIndex].id;
      } else {
        // Activate the last tab
        newActiveTabId = tabs.last.id;
      }
    }

    state = TabState(
      tabs: tabs,
      activeTabId: newActiveTabId,
    );
  }

  /// Close all tabs
  void closeAllTabs() {
    state = TabState();
  }
}

final tabStateProvider = StateNotifierProvider<TabStateNotifier, TabState>((ref) {
  return TabStateNotifier();
});
