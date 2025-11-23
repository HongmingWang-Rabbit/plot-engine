import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chapter.dart';

/// Represents a tab in the editor
class EditorTab {
  final Chapter chapter;
  final bool isModified;
  final bool isPreview; // Preview tabs are shown in italics and can be replaced

  EditorTab({
    required this.chapter,
    this.isModified = false,
    this.isPreview = false,
  });

  EditorTab copyWith({
    Chapter? chapter,
    bool? isModified,
    bool? isPreview,
  }) {
    return EditorTab(
      chapter: chapter ?? this.chapter,
      isModified: isModified ?? this.isModified,
      isPreview: isPreview ?? this.isPreview,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorTab &&
          runtimeType == other.runtimeType &&
          chapter.id == other.chapter.id;

  @override
  int get hashCode => chapter.id.hashCode;
}

/// Tab state containing all open tabs and the active tab
class TabState {
  final List<EditorTab> tabs;
  final String? activeTabId; // Chapter ID of the active tab

  TabState({
    this.tabs = const [],
    this.activeTabId,
  });

  EditorTab? get activeTab =>
      tabs.where((tab) => tab.chapter.id == activeTabId).firstOrNull;

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

    // Check if chapter is already open
    final existingIndex = tabs.indexWhere((tab) => tab.chapter.id == chapter.id);
    if (existingIndex != -1) {
      // Just activate it
      state = state.copyWith(activeTabId: chapter.id);
      return;
    }

    // Remove existing preview tab if any
    tabs.removeWhere((tab) => tab.isPreview);

    // Add new preview tab
    tabs.add(EditorTab(chapter: chapter, isPreview: true));

    state = TabState(
      tabs: tabs,
      activeTabId: chapter.id,
    );
  }

  /// Convert preview tab to permanent tab (when user starts typing)
  void makeTabPermanent(String chapterId) {
    final tabs = state.tabs.map((tab) {
      if (tab.chapter.id == chapterId && tab.isPreview) {
        return tab.copyWith(isPreview: false);
      }
      return tab;
    }).toList();

    state = state.copyWith(tabs: tabs);
  }

  /// Mark a tab as modified (unsaved changes)
  void markTabModified(String chapterId, bool isModified) {
    final tabs = state.tabs.map((tab) {
      if (tab.chapter.id == chapterId) {
        return tab.copyWith(isModified: isModified);
      }
      return tab;
    }).toList();

    state = state.copyWith(tabs: tabs);
  }

  /// Update chapter content in a tab
  void updateTabChapter(Chapter updatedChapter) {
    final tabs = state.tabs.map((tab) {
      if (tab.chapter.id == updatedChapter.id) {
        return tab.copyWith(chapter: updatedChapter);
      }
      return tab;
    }).toList();

    state = state.copyWith(tabs: tabs);
  }

  /// Activate a specific tab
  void activateTab(String chapterId) {
    state = state.copyWith(activeTabId: chapterId);
  }

  /// Close a tab
  void closeTab(String chapterId) {
    final tabs = List<EditorTab>.from(state.tabs);
    final closingIndex = tabs.indexWhere((tab) => tab.chapter.id == chapterId);

    if (closingIndex == -1) return;

    tabs.removeAt(closingIndex);

    // If we're closing the active tab, activate another one
    String? newActiveTabId = state.activeTabId;
    if (state.activeTabId == chapterId) {
      if (tabs.isEmpty) {
        newActiveTabId = null;
      } else if (closingIndex < tabs.length) {
        // Activate the tab that's now in the same position
        newActiveTabId = tabs[closingIndex].chapter.id;
      } else {
        // Activate the last tab
        newActiveTabId = tabs.last.chapter.id;
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
