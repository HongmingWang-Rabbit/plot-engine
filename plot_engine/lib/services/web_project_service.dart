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
        );

        ref.read(projectProvider.notifier).setProject(project);
        ref.read(chaptersProvider.notifier).clearChapters();
        ref.read(knowledgeBaseProvider.notifier).clearItems();
        ref.read(currentChapterProvider.notifier).setCurrentChapter(null);

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
          );

          final chaptersData = projectData['chapters'] as List? ?? [];
          final chapters = chaptersData.map((c) => _chapterFromBackend(c)).toList();
          chapters.sort((a, b) => a.order.compareTo(b.order));

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
  Future<void> saveProject() async {
    final project = ref.read(projectProvider);
    if (project == null) return;

    await _backend.updateProject(project.id, title: project.name);

    final chapters = ref.read(chaptersProvider);
    for (final chapter in chapters) {
      await _backend.updateChapter(
        projectId: project.id,
        chapterId: chapter.id,
        title: chapter.title,
        content: chapter.content,
        orderIndex: chapter.order,
      );
    }

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
    final backendChapter = await _backend.createChapter(
      projectId: project.id,
      title: title,
      content: '',
      orderIndex: chapters.length,
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

    AppLogger.info('Created chapter on cloud', title);
    return chapter;
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

    await _backend.updateChapter(
      projectId: project.id,
      chapterId: chapter.id,
      title: chapter.title,
      content: chapter.content,
    );
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
