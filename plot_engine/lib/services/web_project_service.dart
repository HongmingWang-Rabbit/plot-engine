import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project.dart';
import '../models/chapter.dart';
import '../models/knowledge_item.dart';
import '../models/entity_metadata.dart';
import '../models/entity_type.dart';
import '../state/app_state.dart';
import '../state/tab_state.dart';
import '../core/utils/logger.dart';
import 'backend_project_service.dart';
import 'base_project_service.dart';
import 'template_project_service.dart';
import 'api_client.dart';

/// Web-specific project service that uses cloud storage instead of local files
/// All operations go through the backend API
class WebProjectService implements BaseProjectService {
  final Ref ref;
  final BackendProjectService _backend;
  final ApiClient _apiClient;

  WebProjectService(this.ref)
      : _backend = BackendProjectService(apiClient: ref.read(apiClientProvider)),
        _apiClient = ref.read(apiClientProvider);

  // Create a new project
  Future<Project> createProject(String name, {String? customPath}) async {
    return await ErrorHandler.handleAsync(
      () async {
        // Create project on backend
        final backendProject = await _backend.createProject(title: name);

        // Backend returns Project with name already set
        final project = Project(
          id: backendProject.id,
          name: backendProject.name,
          path: backendProject.id, // Use project ID as "path" for web
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

  // Open an existing project
  // NOTE: With file-first architecture, getProject() returns EVERYTHING
  // (chapters, characters, locations, etc.) from the project.json file in Google Drive
  Future<bool> openProject(String projectId) async {
    // Set loading state
    ref.read(projectLoadingProvider.notifier).setLoading(true);

    try {
      return await ErrorHandler.handleAsync(
        () async {
          print('📂 Opening project from Google Drive: $projectId');

          // Load entire project from Google Drive (via backend)
          // Response is wrapped in { "project": {...} }
          final response = await _apiClient.get('/projects/$projectId');
          final projectData = response['project'] as Map<String, dynamic>;

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

          // Load chapters from project response (already included)
          final chaptersData = projectData['chapters'] as List? ?? [];
          final chapters = chaptersData.map((c) => _chapterFromBackend(c)).toList();
          chapters.sort((a, b) => a.order.compareTo(b.order));

          // Load entities from project response (already included)
          final entities = _backend.getEntitiesFromProject(projectData);

          ref.read(projectProvider.notifier).setProject(project);
          ref.read(chaptersProvider.notifier).setChapters(chapters);
          ref.read(knowledgeBaseProvider.notifier).clearItems();
          ref.read(entityStoreProvider).setAll(entities);

          // Set first chapter as current if available
          if (chapters.isNotEmpty) {
            ref.read(currentChapterProvider.notifier).setCurrentChapter(chapters.first);
          }

          print('✅ Loaded project from Google Drive: ${chapters.length} chapters, ${entities.length} entities');
          AppLogger.load('Opened project from cloud', itemCount: chapters.length, path: projectId);
          return true;
        },
        'Open project',
      ) ?? false;
    } finally {
      // Clear loading state
      ref.read(projectLoadingProvider.notifier).setLoading(false);
    }
  }

  // Get recent projects - for web, get all projects from backend
  Future<List<Project>> getRecentProjects() async {
    return await listProjects();
  }

  // Get last opened project path (not applicable for web)
  Future<String?> getLastProjectPath() async {
    return null;
  }

  // Save current project
  Future<void> saveProject() async {
    final project = ref.read(projectProvider);
    if (project == null) return;

    // Update project on backend
    await _backend.updateProject(
      project.id,
      title: project.name,
    );

    // Save all chapters
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

    // Save all entities - sync local entity store to backend
    final entities = ref.read(entityStoreProvider).getAll();
    for (final entity in entities) {
      try {
        // Try to update first, if that fails create new
        await _backend.updateEntity(
          projectId: project.id,
          entityId: entity.id,
          name: entity.name,
          summary: entity.summary,
          description: entity.description,
          type: _entityTypeToString(entity.type),
        );
      } catch (e) {
        // Entity doesn't exist on backend, create it
        try {
          await _backend.createEntity(
            projectId: project.id,
            name: entity.name,
            type: _entityTypeToString(entity.type),
            summary: entity.summary,
            description: entity.description,
            customType: entity.customType,
          );
        } catch (createError) {
          print('[WebProjectService] Failed to save entity ${entity.name}: $createError');
        }
      }
    }
  }

  // List all projects
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

  // Delete project
  Future<void> deleteProject(String projectId) async {
    await _backend.deleteProject(projectId);
    // Note: Entities file will be deleted when backend deletes the project's files
  }

  // Create a new chapter
  Future<Chapter> createChapter(String title) async {
    final project = ref.read(projectProvider);
    if (project == null) {
      throw Exception('No project is open');
    }

    final chapters = ref.read(chaptersProvider);

    // Create chapter on backend with order_index
    final backendChapter = await _backend.createChapter(
      projectId: project.id,
      title: title,
      content: '',
      orderIndex: chapters.length, // New chapter at the end
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

  // Update chapter
  Future<void> updateChapter(Chapter chapter) async {
    final project = ref.read(projectProvider);
    if (project == null) return;

    ref.read(chaptersProvider.notifier).updateChapter(chapter);

    // Update current chapter if it's the same
    final current = ref.read(currentChapterProvider);
    if (current?.id == chapter.id) {
      ref.read(currentChapterProvider.notifier).setCurrentChapter(chapter);
    }

    // Update chapter on backend
    await _backend.updateChapter(
      projectId: project.id,
      chapterId: chapter.id,
      title: chapter.title,
      content: chapter.content,
    );
  }

  // Delete chapter
  Future<void> deleteChapter(String chapterId) async {
    final project = ref.read(projectProvider);
    if (project == null) return;

    ref.read(chaptersProvider.notifier).deleteChapter(chapterId);

    // Clear current chapter if it was deleted
    final current = ref.read(currentChapterProvider);
    if (current?.id == chapterId) {
      final chapters = ref.read(chaptersProvider);
      ref.read(currentChapterProvider.notifier).setCurrentChapter(
        chapters.isNotEmpty ? chapters.first : null,
      );
    }

    // Delete chapter from backend
    await _backend.deleteChapter(
      projectId: project.id,
      chapterId: chapterId,
    );
  }

  // Set current chapter
  void setCurrentChapter(Chapter chapter) {
    ref.read(currentChapterProvider.notifier).setCurrentChapter(chapter);
  }

  // Add knowledge item
  Future<void> addKnowledgeItem(KnowledgeItem item) async {
    ref.read(knowledgeBaseProvider.notifier).addItem(item);
    // TODO: Add backend API for knowledge items when available
  }

  // Update knowledge item
  Future<void> updateKnowledgeItem(KnowledgeItem item) async {
    ref.read(knowledgeBaseProvider.notifier).updateItem(item);
    // TODO: Add backend API for knowledge items when available
  }

  // Delete knowledge item
  Future<void> deleteKnowledgeItem(String itemId) async {
    ref.read(knowledgeBaseProvider.notifier).deleteItem(itemId);
    // TODO: Add backend API for knowledge items when available
  }

  // Helper: Convert EntityType enum to string for backend
  String _entityTypeToString(EntityType type) {
    switch (type) {
      case EntityType.character:
        return 'character';
      case EntityType.location:
        return 'location';
      case EntityType.object:
        return 'object';
      case EntityType.event:
        return 'event';
      case EntityType.custom:
        return 'custom';
      case EntityType.unknown:
        throw ArgumentError('Cannot create entity with unknown type');
    }
  }

  // Helper: Convert backend chapter JSON to Chapter model
  Chapter _chapterFromBackend(Map<String, dynamic> json) {
    final now = DateTime.now();
    return Chapter(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String? ?? '',
      // Handle both order_index (API) and orderIndex
      order: json['order_index'] as int? ?? json['orderIndex'] as int? ?? 0,
      // Handle both snake_case and camelCase timestamps
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

  // Create template project with sample content
  @override
  Future<Project> createTemplateProject({String? customPath}) async {
    return await ErrorHandler.handleAsync(
      () async {
        // Get template data
        final templateProject = TemplateProjectService.createTemplateProject();

        // Create the project on backend
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

        // Set the project in state
        ref.read(projectProvider.notifier).setProject(project);

        // Create template chapters on backend
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

        // Clear old knowledge items (we're using EntityMetadata instead)
        ref.read(knowledgeBaseProvider.notifier).clearItems();

        // Set first chapter as current and open in tab
        if (createdChapters.isNotEmpty) {
          ref.read(currentChapterProvider.notifier).setCurrentChapter(createdChapters.first);
          ref.read(tabStateProvider.notifier).openPreview(createdChapters.first);
        }

        // Load template entities and save to backend
        final entityStore = ref.read(entityStoreProvider);
        final templateEntities = TemplateProjectService.createTemplateEntities();

        for (final entity in templateEntities) {
          // Save entity to backend
          await _backend.createEntity(
            projectId: project.id,
            name: entity.name,
            type: _entityTypeToString(entity.type),
            summary: entity.summary,
            description: entity.description,
            customType: entity.customType,
          );
          // Also save to local entity store
          entityStore.save(entity);
        }

        AppLogger.info('Created template project on cloud', project.name);
        return project;
      },
      'Create template project',
    ) ?? (throw Exception('Failed to create template project'));
  }
}
