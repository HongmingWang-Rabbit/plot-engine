import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project.dart';
import '../models/sync_metadata.dart';

/// Stub implementation for web platform
/// On web, projects are always cloud-stored via WebProjectService,
/// so no local-to-cloud sync is needed.

class SyncService {
  // ignore: unused_field
  final Ref _ref;

  SyncService(this._ref);

  Future<String?> syncProject(Project project) async => null;
  void syncProjectBackground(Project project) {}
  Future<void> processPendingQueue(Project project) async {}
  Future<SyncStatus> getSyncStatus(String projectPath) async => SyncStatus.synced;
  Future<String?> getCloudProjectId(String projectPath) async => null;
  void dispose() {}
}

class SyncStatusNotifier extends StateNotifier<SyncStatus> {
  SyncStatusNotifier() : super(SyncStatus.synced);

  void setStatus(SyncStatus status) {
    state = status;
  }

  void reset() {
    state = SyncStatus.synced;
  }
}

final syncStatusProvider = StateNotifierProvider<SyncStatusNotifier, SyncStatus>((ref) {
  return SyncStatusNotifier();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref);
});
