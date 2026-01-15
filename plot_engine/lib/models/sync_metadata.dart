/// Sync status for a project
enum SyncStatus {
  /// Changes exist that haven't been synced yet
  pending,

  /// Sync is currently in progress
  syncing,

  /// All changes have been synced to cloud
  synced,

  /// Last sync attempt failed
  failed,

  /// User is offline or not logged in
  offline,
}

/// Represents an item queued for sync retry
class SyncQueueItem {
  final String operation;
  final String localId;
  final Map<String, dynamic> data;
  final int retryCount;
  final DateTime lastAttempt;

  const SyncQueueItem({
    required this.operation,
    required this.localId,
    required this.data,
    this.retryCount = 0,
    required this.lastAttempt,
  });

  SyncQueueItem copyWith({
    String? operation,
    String? localId,
    Map<String, dynamic>? data,
    int? retryCount,
    DateTime? lastAttempt,
  }) {
    return SyncQueueItem(
      operation: operation ?? this.operation,
      localId: localId ?? this.localId,
      data: data ?? this.data,
      retryCount: retryCount ?? this.retryCount,
      lastAttempt: lastAttempt ?? this.lastAttempt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'operation': operation,
      'localId': localId,
      'data': data,
      'retryCount': retryCount,
      'lastAttempt': lastAttempt.toIso8601String(),
    };
  }

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) {
    return SyncQueueItem(
      operation: json['operation'] as String,
      localId: json['localId'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map),
      retryCount: json['retryCount'] as int? ?? 0,
      lastAttempt: DateTime.parse(json['lastAttempt'] as String),
    );
  }
}

/// Metadata for syncing a local project with the cloud
class SyncMetadata {
  /// The cloud project ID (UUID from server), null if not yet synced
  final String? cloudProjectId;

  /// Map of local chapter IDs (timestamp) to cloud chapter IDs (UUID)
  final Map<String, String> chapterIdMap;

  /// Map of local entity IDs (timestamp) to cloud entity IDs (UUID)
  final Map<String, String> entityIdMap;

  /// Last successful sync timestamp
  final DateTime? lastSyncedAt;

  /// Current sync status
  final SyncStatus syncStatus;

  /// Items queued for retry
  final List<SyncQueueItem> pendingQueue;

  const SyncMetadata({
    this.cloudProjectId,
    this.chapterIdMap = const {},
    this.entityIdMap = const {},
    this.lastSyncedAt,
    this.syncStatus = SyncStatus.pending,
    this.pendingQueue = const [],
  });

  /// Check if this project has been synced to cloud
  bool get isCloudSynced => cloudProjectId != null;

  /// Get cloud chapter ID for a local chapter ID
  String? getCloudChapterId(String localId) => chapterIdMap[localId];

  /// Get cloud entity ID for a local entity ID
  String? getCloudEntityId(String localId) => entityIdMap[localId];

  /// Check if a chapter has been synced
  bool isChapterSynced(String localId) => chapterIdMap.containsKey(localId);

  /// Check if an entity has been synced
  bool isEntitySynced(String localId) => entityIdMap.containsKey(localId);

  SyncMetadata copyWith({
    String? cloudProjectId,
    Map<String, String>? chapterIdMap,
    Map<String, String>? entityIdMap,
    DateTime? lastSyncedAt,
    SyncStatus? syncStatus,
    List<SyncQueueItem>? pendingQueue,
  }) {
    return SyncMetadata(
      cloudProjectId: cloudProjectId ?? this.cloudProjectId,
      chapterIdMap: chapterIdMap ?? this.chapterIdMap,
      entityIdMap: entityIdMap ?? this.entityIdMap,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      pendingQueue: pendingQueue ?? this.pendingQueue,
    );
  }

  /// Add a chapter ID mapping
  SyncMetadata addChapterMapping(String localId, String cloudId) {
    return copyWith(
      chapterIdMap: {...chapterIdMap, localId: cloudId},
    );
  }

  /// Add an entity ID mapping
  SyncMetadata addEntityMapping(String localId, String cloudId) {
    return copyWith(
      entityIdMap: {...entityIdMap, localId: cloudId},
    );
  }

  /// Add an item to the pending queue
  SyncMetadata addToPendingQueue(SyncQueueItem item) {
    return copyWith(
      pendingQueue: [...pendingQueue, item],
    );
  }

  /// Remove an item from the pending queue
  SyncMetadata removeFromPendingQueue(String localId) {
    return copyWith(
      pendingQueue: pendingQueue.where((item) => item.localId != localId).toList(),
    );
  }

  /// Update sync status
  SyncMetadata withStatus(SyncStatus status) {
    return copyWith(
      syncStatus: status,
      lastSyncedAt: status == SyncStatus.synced ? DateTime.now() : lastSyncedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cloudProjectId': cloudProjectId,
      'chapterIdMap': chapterIdMap,
      'entityIdMap': entityIdMap,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'syncStatus': syncStatus.name,
      'pendingQueue': pendingQueue.map((item) => item.toJson()).toList(),
    };
  }

  factory SyncMetadata.fromJson(Map<String, dynamic> json) {
    return SyncMetadata(
      cloudProjectId: json['cloudProjectId'] as String?,
      chapterIdMap: Map<String, String>.from(json['chapterIdMap'] as Map? ?? {}),
      entityIdMap: Map<String, String>.from(json['entityIdMap'] as Map? ?? {}),
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.parse(json['lastSyncedAt'] as String)
          : null,
      syncStatus: SyncStatus.values.firstWhere(
        (s) => s.name == json['syncStatus'],
        orElse: () => SyncStatus.pending,
      ),
      pendingQueue: (json['pendingQueue'] as List<dynamic>?)
              ?.map((item) => SyncQueueItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Create an empty metadata for a new project
  factory SyncMetadata.empty() => const SyncMetadata();

  /// Create metadata for a project that was just synced
  factory SyncMetadata.synced({
    required String cloudProjectId,
    Map<String, String>? chapterIdMap,
    Map<String, String>? entityIdMap,
  }) {
    return SyncMetadata(
      cloudProjectId: cloudProjectId,
      chapterIdMap: chapterIdMap ?? {},
      entityIdMap: entityIdMap ?? {},
      lastSyncedAt: DateTime.now(),
      syncStatus: SyncStatus.synced,
    );
  }
}
