import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/tab_state.dart';
import '../state/status_state.dart';
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

    try {
      // The chapter content is already up-to-date from auto-save
      // Just need to save to disk and clear the modified flag
      await ref.read(projectServiceProvider).updateChapter(activeTab.chapter);

      // Clear modified flag after successful save
      ref.read(tabStateProvider.notifier).markTabModified(activeTab.chapter.id, false);

      ref.read(statusProvider.notifier).showSuccess('Saved successfully');
    } catch (e) {
      ref.read(statusProvider.notifier).showError('Error saving: $e');
    }
  }

  /// Save the entire project (all modified tabs)
  Future<void> saveProject() async {
    ref.read(statusProvider.notifier).showLoading('Saving project...');

    try {
      // Save all chapters to disk
      await ref.read(projectServiceProvider).saveProject();

      // Clear modified flags for all tabs
      final tabState = ref.read(tabStateProvider);
      for (final tab in tabState.tabs) {
        if (tab.isModified) {
          ref.read(tabStateProvider.notifier).markTabModified(tab.chapter.id, false);
        }
      }

      ref.read(statusProvider.notifier).showSuccess('Project saved successfully');
    } catch (e) {
      ref.read(statusProvider.notifier).showError('Error saving project: $e');
    }
  }
}

final saveServiceProvider = Provider<SaveService>((ref) {
  return SaveService(ref);
});
