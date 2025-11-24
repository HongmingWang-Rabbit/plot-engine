import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/chapter.dart';
import '../../state/app_state.dart';
import '../../state/tab_state.dart';

/// Coordinates chapter updates across multiple state providers
///
/// This service ensures that when a chapter is updated, all related
/// state providers (chapters list, current chapter, tabs) are kept in sync.
class ChapterCoordinator {
  final Ref ref;

  ChapterCoordinator(this.ref);

  /// Update a chapter across all relevant providers
  void updateChapter(
    Chapter chapter, {
    bool markModified = false,
    bool updateCurrent = true,
  }) {
    // Update in chapters list
    ref.read(chaptersProvider.notifier).updateChapter(chapter);

    // Update current chapter if it's the same chapter
    if (updateCurrent) {
      final current = ref.read(currentChapterProvider);
      if (current?.id == chapter.id) {
        ref.read(currentChapterProvider.notifier).setCurrentChapter(chapter);
      }
    }

    // Update tab if open (only for chapter tabs)
    final tabState = ref.read(tabStateProvider);
    if (tabState.tabs.any((t) => t.type == TabContentType.chapter && t.chapter?.id == chapter.id)) {
      ref.read(tabStateProvider.notifier).updateTabChapter(chapter);

      if (markModified) {
        ref.read(tabStateProvider.notifier).markTabModified(chapter.id, true);
      }
    }
  }

  /// Update chapter content only (optimized for auto-save)
  void updateContent(String chapterId, String content) {
    // Get current chapter
    final chapters = ref.read(chaptersProvider);
    final chapter = chapters.firstWhere((c) => c.id == chapterId);

    // Create updated chapter
    final updatedChapter = Chapter(
      id: chapter.id,
      title: chapter.title,
      content: content,
      order: chapter.order,
      createdAt: chapter.createdAt,
      updatedAt: DateTime.now(),
    );

    // Update across all providers
    updateChapter(updatedChapter, markModified: true);
  }

  /// Update chapter title
  void updateTitle(String chapterId, String title) {
    final chapters = ref.read(chaptersProvider);
    final chapter = chapters.firstWhere((c) => c.id == chapterId);

    final updatedChapter = Chapter(
      id: chapter.id,
      title: title,
      content: chapter.content,
      order: chapter.order,
      createdAt: chapter.createdAt,
      updatedAt: DateTime.now(),
    );

    updateChapter(updatedChapter, markModified: true);
  }

  /// Clear modified flag for a chapter
  void clearModified(String chapterId) {
    ref.read(tabStateProvider.notifier).markTabModified(chapterId, false);
  }

  /// Clear all modified flags
  void clearAllModified() {
    final tabState = ref.read(tabStateProvider);
    for (final tab in tabState.tabs) {
      if (tab.isModified && tab.type == TabContentType.chapter && tab.chapter != null) {
        ref.read(tabStateProvider.notifier).markTabModified(tab.chapter!.id, false);
      }
    }
  }
}

/// Provider for chapter coordinator
final chapterCoordinatorProvider = Provider<ChapterCoordinator>((ref) {
  return ChapterCoordinator(ref);
});
