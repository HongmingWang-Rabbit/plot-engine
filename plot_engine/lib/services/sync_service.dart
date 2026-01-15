import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project.dart';
import '../models/chapter.dart';
import '../models/entity_metadata.dart';
import '../models/sync_metadata.dart';
import '../state/app_state.dart';
import '../core/utils/logger.dart';
import '../core/constants/sync_constants.dart';
import 'backend_project_service.dart';
import 'storage_service.dart';

/// Service for syncing local projects with the cloud
class SyncService {
  final Ref _ref;
  final BackendProjectService _backend;
  final StorageService _storage;

  Timer? _retryTimer;
  bool _isSyncing = false;

  SyncService(this._ref)
      : _backend = _ref.read(backendProjectServiceProvider),
        _storage = StorageService();

  /// Sync entire project to cloud
  /// Returns the cloud project ID if successful
  Future<String?> syncProject(Project project) async {
    if (_isSyncing) {
      AppLogger.info('Sync already in progress, skipping');
      return null;
    }

    _isSyncing = true;
    _ref.read(syncStatusProvider.notifier).setStatus(SyncStatus.syncing);

    try {
      // Load existing sync metadata
      var metadata = await _storage.loadSyncMetadata(project.path) ??
          SyncMetadata.empty();

      String cloudProjectId;

      // Check if project already exists in cloud
      if (metadata.cloudProjectId != null) {
        // Update existing cloud project
        cloudProjectId = metadata.cloudProjectId!;
        await _backend.updateProject(cloudProjectId, title: project.name);
        AppLogger.info('Updated cloud project', cloudProjectId);
      } else {
        // Create new cloud project
        final cloudProject = await _backend.createProject(title: project.name);
        cloudProjectId = cloudProject.id;
        metadata = metadata.copyWith(cloudProjectId: cloudProjectId);
        AppLogger.info('Created cloud project', cloudProjectId);
      }

      // Sync all chapters
      final chapters = _ref.read(chaptersProvider);
      for (final chapter in chapters) {
        metadata = await _syncChapter(cloudProjectId, chapter, metadata);
      }

      // Sync all entities
      final entityStore = _ref.read(entityStoreProvider);
      for (final entity in entityStore.getAll()) {
        metadata = await _syncEntity(cloudProjectId, entity, metadata);
      }

      // Update sync metadata
      metadata = metadata.withStatus(SyncStatus.synced);
      await _storage.saveSyncMetadata(project.path, metadata);

      // Update project as cloud stored
      final updatedProject = project.copyWith(isCloudStored: true);
      _ref.read(projectProvider.notifier).setProject(updatedProject);
      await _storage.saveProject(updatedProject);

      _ref.read(syncStatusProvider.notifier).setStatus(SyncStatus.synced);
      AppLogger.info('Project sync complete', project.name);

      return cloudProjectId;
    } catch (e, stackTrace) {
      AppLogger.error('Project sync failed', e, stackTrace);
      _ref.read(syncStatusProvider.notifier).setStatus(SyncStatus.failed);

      // Queue for retry
      _scheduleRetry(project);

      return null;
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync a single chapter to cloud
  Future<SyncMetadata> _syncChapter(
    String cloudProjectId,
    Chapter chapter,
    SyncMetadata metadata,
  ) async {
    try {
      final localId = chapter.id;
      final existingCloudId = metadata.getCloudChapterId(localId);

      if (existingCloudId != null) {
        // Update existing chapter
        await _backend.updateChapter(
          projectId: cloudProjectId,
          chapterId: existingCloudId,
          title: chapter.title,
          content: chapter.content,
          orderIndex: chapter.order,
        );
        AppLogger.info('Updated cloud chapter', chapter.title);
      } else {
        // Create new chapter
        try {
          final cloudChapter = await _backend.createChapter(
            projectId: cloudProjectId,
            title: chapter.title,
            content: chapter.content,
            orderIndex: chapter.order,
          );
          metadata = metadata.addChapterMapping(localId, cloudChapter.id);
          AppLogger.info('Created cloud chapter', chapter.title);
        } catch (createError) {
          // Check if chapter already exists (by order index match)
          if (_isAlreadyExistsError(createError)) {
            // Look up existing chapters
            final existingChapters = await _backend.getChapters(cloudProjectId);
            final matchingChapter = existingChapters
                .where((c) => c.order == chapter.order || c.title == chapter.title)
                .firstOrNull;

            if (matchingChapter != null) {
              // Map the existing cloud chapter to our local ID
              metadata = metadata.addChapterMapping(localId, matchingChapter.id);
              AppLogger.info('Mapped existing cloud chapter', chapter.title);

              // Update with our local data
              await _backend.updateChapter(
                projectId: cloudProjectId,
                chapterId: matchingChapter.id,
                title: chapter.title,
                content: chapter.content,
                orderIndex: chapter.order,
              );
              AppLogger.info('Updated existing cloud chapter', chapter.title);
            } else {
              rethrow;
            }
          } else {
            rethrow;
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to sync chapter: ${chapter.title}', e, stackTrace);
      // Add to pending queue for retry
      metadata = metadata.addToPendingQueue(SyncQueueItem(
        operation: SyncConstants.operationSyncChapter,
        localId: chapter.id,
        data: {
          'title': chapter.title,
          'content': chapter.content,
          'order': chapter.order,
        },
        lastAttempt: DateTime.now(),
      ));
    }
    return metadata;
  }

  /// Sync a single entity to cloud
  Future<SyncMetadata> _syncEntity(
    String cloudProjectId,
    EntityMetadata entity,
    SyncMetadata metadata,
  ) async {
    try {
      final localId = entity.id;
      final existingCloudId = metadata.getCloudEntityId(localId);

      if (existingCloudId != null) {
        // Update existing entity
        await _backend.updateEntity(
          projectId: cloudProjectId,
          entityId: existingCloudId,
          name: entity.name,
          summary: entity.summary,
          description: entity.description,
          type: entity.type.name,
        );
        AppLogger.info('Updated cloud entity', entity.name);
      } else {
        // Create new entity
        try {
          final response = await _backend.createEntity(
            projectId: cloudProjectId,
            name: entity.name,
            type: entity.type.name,
            summary: entity.summary,
            description: entity.description,
            customType: entity.customType,
          );
          final cloudId = response['id'] as String;
          metadata = metadata.addEntityMapping(localId, cloudId);
          AppLogger.info('Created cloud entity', entity.name);
        } catch (createError) {
          // Check if entity already exists (400 error)
          if (_isAlreadyExistsError(createError)) {
            // Look up existing entity by name
            final existingEntities = await _backend.getEntities(cloudProjectId);
            final matchingEntity = existingEntities
                .where((e) => e.name == entity.name)
                .firstOrNull;

            if (matchingEntity != null) {
              // Map the existing cloud entity to our local ID
              metadata = metadata.addEntityMapping(localId, matchingEntity.id);
              AppLogger.info('Mapped existing cloud entity', entity.name);

              // Update with our local data
              await _backend.updateEntity(
                projectId: cloudProjectId,
                entityId: matchingEntity.id,
                name: entity.name,
                summary: entity.summary,
                description: entity.description,
                type: entity.type.name,
              );
              AppLogger.info('Updated existing cloud entity', entity.name);
            } else {
              // Entity exists but couldn't find it - rethrow
              rethrow;
            }
          } else {
            rethrow;
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to sync entity: ${entity.name}', e, stackTrace);
      // Add to pending queue for retry
      metadata = metadata.addToPendingQueue(SyncQueueItem(
        operation: SyncConstants.operationSyncEntity,
        localId: entity.id,
        data: {
          'name': entity.name,
          'type': entity.type.name,
          'summary': entity.summary,
          'description': entity.description,
        },
        lastAttempt: DateTime.now(),
      ));
    }
    return metadata;
  }

  /// Schedule a retry for failed sync
  void _scheduleRetry(Project project) {
    _retryTimer?.cancel();

    // Get retry count from metadata
    _storage.loadSyncMetadata(project.path).then((metadata) {
      final retryCount = metadata?.pendingQueue.isEmpty == false
          ? metadata!.pendingQueue.first.retryCount
          : 0;

      if (retryCount >= SyncConstants.maxRetries) {
        AppLogger.warn('Max retries reached for sync', project.name);
        return;
      }

      final delays = SyncConstants.retryDelaysSeconds;
      final delaySeconds = delays[retryCount.clamp(0, delays.length - 1)];
      AppLogger.info('Scheduling sync retry in ${delaySeconds}s', 'attempt ${retryCount + 1}');

      _retryTimer = Timer(Duration(seconds: delaySeconds), () {
        syncProject(project);
      });
    }).catchError((e, stackTrace) {
      AppLogger.error('Failed to schedule sync retry', e, stackTrace);
    });
  }

  /// Sync project in background (non-blocking)
  void syncProjectBackground(Project project) {
    // Fire and forget - don't await
    syncProject(project).catchError((e) {
      AppLogger.warn('Background sync error', e.toString());
    });
  }

  /// Process any pending sync items
  Future<void> processPendingQueue(Project project) async {
    final metadata = await _storage.loadSyncMetadata(project.path);
    if (metadata == null || metadata.pendingQueue.isEmpty) return;

    final cloudProjectId = metadata.cloudProjectId;
    if (cloudProjectId == null) return;

    var updatedMetadata = metadata;

    for (final item in metadata.pendingQueue) {
      try {
        if (item.operation == SyncConstants.operationSyncChapter) {
          final chapters = _ref.read(chaptersProvider);
          final chapter = chapters.where((c) => c.id == item.localId).firstOrNull;
          if (chapter != null) {
            updatedMetadata = await _syncChapter(cloudProjectId, chapter, updatedMetadata);
          }
        } else if (item.operation == SyncConstants.operationSyncEntity) {
          final entityStore = _ref.read(entityStoreProvider);
          final entity = entityStore.get(item.localId);
          if (entity != null) {
            updatedMetadata = await _syncEntity(cloudProjectId, entity, updatedMetadata);
          }
        }
        // Remove from queue on success
        updatedMetadata = updatedMetadata.removeFromPendingQueue(item.localId);
      } catch (e, stackTrace) {
        // Log error for debugging
        AppLogger.warn('Queue item sync failed, will retry',
            'localId: ${item.localId}, retryCount: ${item.retryCount + 1}');
        AppLogger.error('Queue sync error details', e, stackTrace);

        // Increment retry count
        final updatedItem = item.copyWith(
          retryCount: item.retryCount + 1,
          lastAttempt: DateTime.now(),
        );
        updatedMetadata = updatedMetadata
            .removeFromPendingQueue(item.localId)
            .addToPendingQueue(updatedItem);
      }
    }

    await _storage.saveSyncMetadata(project.path, updatedMetadata);
  }

  /// Check if an error indicates the item already exists in cloud
  bool _isAlreadyExistsError(Object error) {
    return error.toString().contains(SyncConstants.errorAlreadyExists);
  }

  /// Get sync status for a project
  Future<SyncStatus> getSyncStatus(String projectPath) async {
    final metadata = await _storage.loadSyncMetadata(projectPath);
    return metadata?.syncStatus ?? SyncStatus.offline;
  }

  /// Get cloud project ID for a local project
  Future<String?> getCloudProjectId(String projectPath) async {
    final metadata = await _storage.loadSyncMetadata(projectPath);
    return metadata?.cloudProjectId;
  }

  /// Cancel any pending operations
  void dispose() {
    _retryTimer?.cancel();
  }
}

/// StateNotifier for sync status
class SyncStatusNotifier extends StateNotifier<SyncStatus> {
  SyncStatusNotifier() : super(SyncStatus.offline);

  void setStatus(SyncStatus status) {
    state = status;
  }

  void reset() {
    state = SyncStatus.offline;
  }
}

/// Provider for sync status
final syncStatusProvider = StateNotifierProvider<SyncStatusNotifier, SyncStatus>((ref) {
  return SyncStatusNotifier();
});

/// Provider for SyncService
final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});
