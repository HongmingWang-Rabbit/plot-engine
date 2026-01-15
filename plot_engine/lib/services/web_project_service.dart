import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project.dart';
import '../models/chapter.dart';
import '../models/knowledge_item.dart';
import '../models/entity_metadata.dart';
import '../state/app_state.dart';
import '../state/tab_state.dart';
import '../core/utils/logger.dart';
import 'backend_project_service.dart';
import 'base_project_service.dart';
import 'template_project_service.dart';

/// Web-specific project service that uses cloud storage instead of local files
/// All operations go through the backend API
class WebProjectService implements BaseProjectService {
  final Ref ref;
  final BackendProjectService _backend;

  WebProjectService(this.ref)
      : _backend = BackendProjectService(apiClient: ref.read(apiClientProvider));

  /// Check if an ID is client-generated (timestamp) vs backend UUID
  bool _isClientGeneratedId(String id) => !id.contains('-');

  @override
  Future<Project> createProject(String name, {String? customPath}) async {
    return await ErrorHandler.handleAsync(
      () async {
        final backendProject = await _backend.createProject(title: name);

        final project = Project(
          id: backendProject.id,
          name: backendProject.name,
          path: backendProject.id,
          createdAt: backendProject.createdAt,
          updatedAt: backendProject.updatedAt,
          isCloudStored: true,
        );

        ref.read(projectProvider.notifier).setProject(project);
        ref.read(chaptersProvider.notifier).clearChapters();
        ref.read(knowledgeBaseProvider.notifier).clearItems();
        ref.read(entityStoreProvider).clear();

        // Create default chapter
        final backendChapter = await _backend.createChapter(
          projectId: project.id,
          title: 'Chapter 1',
          content: '',
          orderIndex: 0,
        );

        final chapter = Chapter(
          id: backendChapter.id,
          title: backendChapter.title,
          content: backendChapter.content,
          order: backendChapter.order,
          createdAt: backendChapter.createdAt,
          updatedAt: backendChapter.updatedAt,
        );

        ref.read(chaptersProvider.notifier).addChapter(chapter);
        ref.read(currentChapterProvider.notifier).setCurrentChapter(chapter);
        ref.read(tabStateProvider.notifier).openPreview(chapter);

        AppLogger.info('Created project on cloud', name);
        return project;
      },
      'Create project',
    ) ?? (throw Exception('Failed to create project'));
  }

  @override
  Future<bool> openProject(String projectId) async {
    ref.read(projectLoadingProvider.notifier).setLoading(true);

    try {
      return await ErrorHandler.handleAsync(
        () async {
          final projectData = await _backend.getProjectResponse(projectId);

          final project = Project(
            id: projectData['id'],
            name: projectData['title'],
            path: projectData['id'],
            createdAt: projectData['created_at'] != null
                ? DateTime.parse(projectData['created_at'])
                : DateTime.now(),
            updatedAt: projectData['updated_at'] != null
                ? DateTime.parse(projectData['updated_at'])
                : DateTime.now(),
            isCloudStored: true,
          );

          final chaptersData = projectData['chapters'] as List? ?? [];
          var chapters = chaptersData.map((c) => _chapterFromBackend(c)).toList();
          // Sort chapters by order (ascending - chapter 1 at top, latest at bottom)
          chapters.sort((a, b) => a.order.compareTo(b.order));

          // Normalize order values if they're not sequential (e.g., all zeros)
          final needsNormalization = chapters.length > 1 &&
              chapters.every((c) => c.order == chapters.first.order);
          if (needsNormalization) {
            chapters = chapters.asMap().entries.map((entry) {
              return entry.value.copyWith(order: entry.key);
            }).toList();
            // Try to sync normalized orders to backend (non-fatal if it fails)
            try {
              final chapterOrder = chapters
                  .map((c) => {'chapterId': c.id, 'orderIndex': c.order})
                  .toList();
              await _backend.reorderChapters(projectId: projectId, chapterOrder: chapterOrder);
              AppLogger.info('Normalized chapter orders', '${chapters.length} chapters');
            } catch (e) {
              AppLogger.warn('Failed to sync normalized chapter orders', e.toString());
              // Continue anyway - local order is updated
            }
          }

          var entities = _backend.getEntitiesFromProject(projectData);
          if (entities.isEmpty) {
            entities = await _backend.getEntities(projectId);
          }

          ref.read(projectProvider.notifier).setProject(project);
          ref.read(chaptersProvider.notifier).setChapters(chapters);
          ref.read(knowledgeBaseProvider.notifier).clearItems();
          ref.read(entityStoreProvider).setAll(entities);
          ref.read(entityStoreVersionProvider.notifier).increment();

          if (chapters.isNotEmpty) {
            ref.read(currentChapterProvider.notifier).setCurrentChapter(chapters.first);
            ref.read(tabStateProvider.notifier).openPreview(chapters.first);
          }

          AppLogger.load('Opened project from cloud', itemCount: chapters.length, path: projectId);
          return true;
        },
        'Open project',
      ) ?? false;
    } finally {
      ref.read(projectLoadingProvider.notifier).setLoading(false);
    }
  }

  @override
  Future<List<Project>> getRecentProjects() async {
    return await listProjects();
  }

  @override
  Future<String?> getLastProjectPath() async {
    return null;
  }

  @override
  Future<void> updateProjectMetadata() async {
    final project = ref.read(projectProvider);
    if (project == null) return;

    await _backend.updateProject(project.id, title: project.name);
    AppLogger.info('Updated project metadata', project.name);
  }

  @override
  Future<void> saveProject() async {
    final project = ref.read(projectProvider);
    if (project == null) return;

    // Update project metadata
    await updateProjectMetadata();

    // Update chapters
    final chapters = ref.read(chaptersProvider);
    for (final chapter in chapters) {
      try {
        if (_isClientGeneratedId(chapter.id)) {
          await _syncChapterToBackend(project.id, chapter);
        } else {
          await _backend.updateChapter(
            projectId: project.id,
            chapterId: chapter.id,
            title: chapter.title,
            content: chapter.content,
            orderIndex: chapter.order,
          );
        }
      } catch (e) {
        AppLogger.warn('Failed to sync chapter', '${chapter.title}: $e');
      }
    }

    // Update entities
    final entityStore = ref.read(entityStoreProvider);
    for (final entity in entityStore.getAll()) {
      await _syncEntityToBackend(project.id, entity);
    }
  }

  @override
  Future<List<Project>> listProjects() async {
    final backendProjects = await _backend.getProjects();
    return backendProjects.map((bp) => Project(
      id: bp.id,
      name: bp.name,
      path: bp.id,
      createdAt: bp.createdAt,
      updatedAt: bp.updatedAt,
      isCloudStored: true,
    )).toList();
  }

  @override
  Future<void> deleteProject(String projectId) async {
    await _backend.deleteProject(projectId);
  }

  @override
  Future<Chapter> createChapter(String title) async {
    final project = ref.read(projectProvider);
    if (project == null) {
      throw Exception('No project is open');
    }

    final chapters = ref.read(chaptersProvider);
    final now = DateTime.now();

    // Create local chapter immediately with client-generated ID
    final localChapter = Chapter(
      id: '${now.millisecondsSinceEpoch}',
      title: title,
      content: '',
      order: chapters.length,
      createdAt: now,
      updatedAt: now,
    );

    // Add to UI immediately (optimistic update)
    ref.read(chaptersProvider.notifier).addChapter(localChapter);
    ref.read(currentChapterProvider.notifier).setCurrentChapter(localChapter);
    ref.read(tabStateProvider.notifier).openPreview(localChapter);

    AppLogger.info('Created chapter locally', title);

    // Sync with backend in background
    _syncChapterToBackend(project.id, localChapter);

    return localChapter;
  }

  /// Sync a locally-created chapter to the backend
  Future<void> _syncChapterToBackend(String projectId, Chapter chapter) async {
    if (!_isClientGeneratedId(chapter.id)) return;

    try {
      final backendChapter = await _backend.createChapter(
        projectId: projectId,
        title: chapter.title,
        content: chapter.content,
        orderIndex: chapter.order,
      );

      final backendId = backendChapter.id;
      if (backendId != chapter.id) {
        // Get the CURRENT local chapter state (user may have typed more content)
        final chapters = ref.read(chaptersProvider);
        final currentLocalChapter = chapters.where((c) => c.id == chapter.id).firstOrNull;

        // Keep all local data, only update the ID
        final updatedChapter = Chapter(
          id: backendId,
          title: currentLocalChapter?.title ?? chapter.title,
          content: currentLocalChapter?.content ?? chapter.content,
          order: currentLocalChapter?.order ?? chapter.order,
          createdAt: backendChapter.createdAt,
          updatedAt: DateTime.now(),
        );

        // Replace in chapters list
        ref.read(chaptersProvider.notifier).replaceChapter(chapter.id, updatedChapter);

        // Update current chapter if it's the one we just synced
        final currentChapter = ref.read(currentChapterProvider);
        if (currentChapter?.id == chapter.id) {
          // Keep the current content from currentChapterProvider too
          final latestContent = currentChapter?.content ?? updatedChapter.content;
          ref.read(currentChapterProvider.notifier).setCurrentChapter(
            updatedChapter.copyWith(content: latestContent),
          );
        }

        // Update tab if open (keep the tab's current chapter content)
        final tabState = ref.read(tabStateProvider);
        final existingTab = tabState.tabs.where((t) => t.id == 'chapter-${chapter.id}').firstOrNull;
        final tabContent = existingTab?.chapter?.content ?? updatedChapter.content;
        ref.read(tabStateProvider.notifier).replaceChapterTab(
          chapter.id,
          updatedChapter.copyWith(content: tabContent),
        );

        AppLogger.info('Synced chapter to cloud', chapter.title);
      }
    } catch (e) {
      AppLogger.warn('Failed to sync chapter to cloud', e.toString());
    }
  }

  @override
  Future<void> updateChapter(Chapter chapter) async {
    final project = ref.read(projectProvider);
    if (project == null) return;

    ref.read(chaptersProvider.notifier).updateChapter(chapter);

    final current = ref.read(currentChapterProvider);
    if (current?.id == chapter.id) {
      ref.read(currentChapterProvider.notifier).setCurrentChapter(chapter);
    }

    // If chapter has a client-generated ID, sync it to backend first (POST)
    // Otherwise update it (PATCH)
    if (_isClientGeneratedId(chapter.id)) {
      await _syncChapterToBackend(project.id, chapter);
    } else {
      await _backend.updateChapter(
        projectId: project.id,
        chapterId: chapter.id,
        title: chapter.title,
        content: chapter.content,
      );
    }
  }

  @override
  Future<void> deleteChapter(String chapterId) async {
    final project = ref.read(projectProvider);
    if (project == null) return;

    ref.read(chaptersProvider.notifier).deleteChapter(chapterId);

    final current = ref.read(currentChapterProvider);
    if (current?.id == chapterId) {
      final chapters = ref.read(chaptersProvider);
      ref.read(currentChapterProvider.notifier).setCurrentChapter(
        chapters.isNotEmpty ? chapters.first : null,
      );
    }

    await _backend.deleteChapter(projectId: project.id, chapterId: chapterId);
  }

  @override
  Future<void> reorderChapters(int oldIndex, int newIndex) async {
    final project = ref.read(projectProvider);
    if (project == null) return;

    final chapters = ref.read(chaptersProvider).toList();
    if (oldIndex < 0 || oldIndex >= chapters.length ||
        newIndex < 0 || newIndex >= chapters.length) {
      return;
    }

    // Remove and insert at new position
    final chapter = chapters.removeAt(oldIndex);
    chapters.insert(newIndex, chapter);

    // Update order field (ascending - top item gets order 0)
    final updatedChapters = <Chapter>[];
    for (int i = 0; i < chapters.length; i++) {
      updatedChapters.add(chapters[i].copyWith(order: i));
    }

    // Update UI immediately (optimistic update)
    ref.read(chaptersProvider.notifier).setChapters(updatedChapters);

    // Sync to backend
    final chapterOrder = updatedChapters
        .map((c) => {'chapterId': c.id, 'orderIndex': c.order})
        .toList();

    try {
      print('[WebProjectService] Syncing chapter order to backend...');
      print('[WebProjectService] Project ID: ${project.id}');
      print('[WebProjectService] Chapter order: $chapterOrder');
      await _backend.reorderChapters(
        projectId: project.id,
        chapterOrder: chapterOrder,
      );
      print('[WebProjectService] ✓ Chapter order synced successfully');
      AppLogger.info('Reordered chapters on cloud', 'moved from $oldIndex to $newIndex');
    } catch (e) {
      print('[WebProjectService] ✗ Failed to sync chapter order!');
      print('[WebProjectService] Error: $e');
      print('[WebProjectService] Error type: ${e.runtimeType}');
      AppLogger.warn('Failed to sync chapter order to cloud', e.toString());
    }
  }

  @override
  void setCurrentChapter(Chapter chapter) {
    ref.read(currentChapterProvider.notifier).setCurrentChapter(chapter);
  }

  @override
  Future<void> addKnowledgeItem(KnowledgeItem item) async {
    ref.read(knowledgeBaseProvider.notifier).addItem(item);
  }

  @override
  Future<void> updateKnowledgeItem(KnowledgeItem item) async {
    ref.read(knowledgeBaseProvider.notifier).updateItem(item);
  }

  @override
  Future<void> deleteKnowledgeItem(String itemId) async {
    ref.read(knowledgeBaseProvider.notifier).deleteItem(itemId);
  }

  @override
  Future<void> saveEntity(EntityMetadata entity) async {
    final project = ref.read(projectProvider);
    if (project == null) return;
    await _syncEntityToBackend(project.id, entity);
  }

  @override
  Future<void> deleteEntity(String entityId) async {
    final project = ref.read(projectProvider);
    if (project == null) return;

    if (!_isClientGeneratedId(entityId)) {
      try {
        await _backend.deleteEntity(projectId: project.id, entityId: entityId);
      } catch (e) {
        // 404 is expected if entity was never saved or already deleted
      }
    }
  }

  @override
  Future<Project> createTemplateProject({String? customPath}) async {
    return await ErrorHandler.handleAsync(
      () async {
        final templateProject = TemplateProjectService.createTemplateProject();

        final backendProject = await _backend.createProject(
          title: templateProject.name,
          description: 'A sample project to explore PlotEngine features',
        );

        final project = Project(
          id: backendProject.id,
          name: backendProject.name,
          path: backendProject.id,
          createdAt: backendProject.createdAt,
          updatedAt: backendProject.updatedAt,
          isCloudStored: true,
        );

        ref.read(projectProvider.notifier).setProject(project);

        final templateChapters = TemplateProjectService.createTemplateChapters();
        final createdChapters = <Chapter>[];

        for (int i = 0; i < templateChapters.length; i++) {
          final templateChapter = templateChapters[i];
          final backendChapter = await _backend.createChapter(
            projectId: project.id,
            title: templateChapter.title,
            content: templateChapter.content,
            orderIndex: i,
          );

          createdChapters.add(Chapter(
            id: backendChapter.id,
            title: backendChapter.title,
            content: backendChapter.content,
            order: backendChapter.order,
            createdAt: backendChapter.createdAt,
            updatedAt: backendChapter.updatedAt,
          ));
        }

        ref.read(chaptersProvider.notifier).setChapters(createdChapters);
        ref.read(knowledgeBaseProvider.notifier).clearItems();

        if (createdChapters.isNotEmpty) {
          ref.read(currentChapterProvider.notifier).setCurrentChapter(createdChapters.first);
          ref.read(tabStateProvider.notifier).openPreview(createdChapters.first);
        }

        final entityStore = ref.read(entityStoreProvider);
        final templateEntities = TemplateProjectService.createTemplateEntities();

        for (final entity in templateEntities) {
          await _backend.createEntity(
            projectId: project.id,
            name: entity.name,
            type: entity.type.name,
            summary: entity.summary,
            description: entity.description,
            customType: entity.customType,
          );
          entityStore.save(entity);
        }
        ref.read(entityStoreVersionProvider.notifier).increment();

        AppLogger.info('Created template project on cloud', project.name);
        return project;
      },
      'Create template project',
    ) ?? (throw Exception('Failed to create template project'));
  }

  // Private helper methods

  Future<void> _syncEntityToBackend(String projectId, EntityMetadata entity) async {
    if (_isClientGeneratedId(entity.id)) {
      try {
        final backendEntity = await _backend.createEntity(
          projectId: projectId,
          name: entity.name,
          type: entity.type.name,
          summary: entity.summary,
          description: entity.description,
          customType: entity.customType,
        );

        final backendId = backendEntity['id'] as String;
        if (backendId != entity.id) {
          final entityStore = ref.read(entityStoreProvider);
          entityStore.deleteById(entity.id);
          entityStore.save(entity.copyWith(id: backendId));
          ref.read(entityStoreVersionProvider.notifier).increment();
        }
      } catch (e) {
        // Silently handle errors for entity sync
      }
    } else {
      try {
        await _backend.updateEntity(
          projectId: projectId,
          entityId: entity.id,
          name: entity.name,
          summary: entity.summary,
          description: entity.description,
          type: entity.type.name,
        );
      } catch (e) {
        // Silently handle errors for entity sync
      }
    }
  }

  Chapter _chapterFromBackend(Map<String, dynamic> json) {
    final now = DateTime.now();
    return Chapter(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String? ?? '',
      order: json['order_index'] as int? ?? json['orderIndex'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : (json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : now),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : (json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : now),
    );
  }
}
