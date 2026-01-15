/// Constants for cloud sync operations
class SyncConstants {
  SyncConstants._();

  /// Retry delays in seconds for exponential backoff
  /// Pattern: 5s, 15s, 45s, 2min, 5min
  static const List<int> retryDelaysSeconds = [5, 15, 45, 120, 300];

  /// Maximum number of retry attempts before giving up
  static const int maxRetries = 5;

  /// Queue operation types
  static const String operationSyncChapter = 'sync_chapter';
  static const String operationSyncEntity = 'sync_entity';
  static const String operationSyncProject = 'sync_project';

  /// Error message substring indicating duplicate item
  /// Used to detect "already exists" errors from backend
  static const String errorAlreadyExists = 'already exists';
}
