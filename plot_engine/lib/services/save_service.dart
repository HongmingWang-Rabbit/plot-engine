import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/tab_state.dart';
import '../state/status_state.dart';
import '../core/utils/logger.dart';
import '../core/services/chapter_coordinator.dart';
import 'project_service.dart';

/// Centralized save service for consistent save behavior across the app
class SaveService {
  final Ref ref;

  SaveService(this.ref);

  /// Save the current active tab
  Future<void> saveCurrentTab() async {
    final tabState = ref.read(tabStateProvider);
    final activeTab = tabState.activeTab;

    if (activeTab == null) {
      ref.read(statusProvider.notifier).showError('No active tab to save');
      return;
    }

    ref.read(statusProvider.notifier).showLoading('Saving...');

    // Only save chapter tabs
    if (activeTab.type != TabContentType.chapter || activeTab.chapter == null) {
      return;
    }

    await ErrorHandler.handleAsyncWithCallback(
      () async {
        // The chapter content is already up-to-date from auto-save
        // Just need to save to disk and clear the modified flag
        await ref.read(projectServiceProvider).updateChapter(activeTab.chapter!);

        // Clear modified flag using coordinator
        ref.read(chapterCoordinatorProvider).clearModified(activeTab.chapter!.id);

        AppLogger.save('Saved chapter', itemCount: 1);
        ref.read(statusProvider.notifier).showSuccess('Saved successfully');
      },
      'Save current tab',
      onError: (error) {
        ref.read(statusProvider.notifier).showError('Error saving: $error');
      },
    );
  }

  /// Save the entire project (all modified tabs)
  Future<void> saveProject() async {
    ref.read(statusProvider.notifier).showLoading('Saving project...');

    await ErrorHandler.handleAsyncWithCallback(
      () async {
        // Save all chapters to disk
        await ref.read(projectServiceProvider).saveProject();

        // Clear all modified flags using coordinator
        final tabState = ref.read(tabStateProvider);
        int modifiedCount = tabState.tabs.where((tab) => tab.isModified).length;
        ref.read(chapterCoordinatorProvider).clearAllModified();

        AppLogger.save('Saved project', itemCount: modifiedCount);
        ref.read(statusProvider.notifier).showSuccess('Project saved successfully');
      },
      'Save project',
      onError: (error) {
        ref.read(statusProvider.notifier).showError('Error saving project: $error');
      },
    );
  }
}

final saveServiceProvider = Provider<SaveService>((ref) {
  return SaveService(ref);
});
