import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project.dart';
import '../models/chapter.dart';
import '../models/knowledge_item.dart';
import '../models/entity_metadata.dart';
import '../state/app_state.dart';
import '../state/tab_state.dart';
import '../core/utils/logger.dart';
import 'storage_service.dart';
import 'recent_projects_service.dart';
import 'template_project_service.dart';
import 'base_project_service.dart';

class ProjectService implements BaseProjectService {
  final Ref ref;
  final StorageService _storage = StorageService();
  final RecentProjectsService _recentProjects = RecentProjectsService();

  ProjectService(this.ref);

  @override
  Future<Project> createProject(String name, {String? customPath}) async {
    return await ErrorHandler.handleAsync(
      () async {
        final project = await _storage.createProject(name, customPath: customPath);
        ref.read(projectProvider.notifier).setProject(project);
        ref.read(chaptersProvider.notifier).clearChapters();
        ref.read(knowledgeBaseProvider.notifier).clearItems();
        ref.read(currentChapterProvider.notifier).setCurrentChapter(null);

        // Track as recent project
        await _recentProjects.addRecentProject(project.path);

        AppLogger.info('Created project', name);
        return project;
      },
      'Create project',
    ) ?? (throw Exception('Failed to create project'));
  }

  @override
  Future<bool> openProject(String projectPath) async {
    return await ErrorHandler.handleAsync(
      () async {
        final project = await _storage.loadProject(projectPath);
        if (project == null) {
          AppLogger.warn('Project not found', projectPath);
          return false;
        }

        final chapters = await _storage.loadChapters(projectPath);
        final knowledgeItems = await _storage.loadKnowledgeBase(projectPath);
        final entities = await _storage.loadEntities(projectPath);

        ref.read(projectProvider.notifier).setProject(project);
        ref.read(chaptersProvider.notifier).setChapters(chapters);
        ref.read(knowledgeBaseProvider.notifier).setItems(knowledgeItems);

        // Load entities into the entity store
        ref.read(entityStoreProvider).setAll(entities);

        // Set first chapter as current if available
        if (chapters.isNotEmpty) {
          ref.read(currentChapterProvider.notifier).setCurrentChapter(chapters.first);
        }

        // Track as recent project
        await _recentProjects.addRecentProject(projectPath);

        AppLogger.load('Opened project', itemCount: chapters.length, path: projectPath);
        return true;
      },
      'Open project',
    ) ?? false;
  }

  @override
  Future<List<Project>> getRecentProjects() async {
    final recentPaths = await _recentProjects.getRecentProjects();
    final projects = <Project>[];

    for (final path in recentPaths) {
      final project = await _storage.loadProject(path);
      if (project != null) {
        projects.add(project);
      } else {
        // Remove invalid project from recents
        await _recentProjects.removeRecentProject(path);
      }
    }

    return projects;
  }

  @override
  Future<String?> getLastProjectPath() async {
    return await _recentProjects.getLastProjectPath();
  }

  @override
  Future<void> saveProject() async {
    final project = ref.read(projectProvider);
    if (project == null) return;

    await _storage.saveProject(project);

    final chapters = ref.read(chaptersProvider);
    await _storage.saveChapters(project.path, chapters);

    final knowledgeItems = ref.read(knowledgeBaseProvider);
    await _storage.saveKnowledgeBase(project.path, knowledgeItems);

    // Save entities
    final entities = ref.read(entityStoreProvider).getAll();
    await _storage.saveEntities(project.path, entities);
  }

  @override
  Future<List<Project>> listProjects() async {
    return await _storage.listProjects();
  }

  @override
  Future<void> deleteProject(String projectPath) async {
    await _storage.deleteProject(projectPath);
  }

  @override
  Future<Chapter> createChapter(String title) async {
    final project = ref.read(projectProvider);
    if (project == null) {
      throw Exception('No project is open');
    }

    final chapters = ref.read(chaptersProvider);
    final now = DateTime.now();
    final chapter = Chapter(
      id: '${now.millisecondsSinceEpoch}',
      title: title,
      content: '',
      order: chapters.length,
      createdAt: now,
      updatedAt: now,
    );

    ref.read(chaptersProvider.notifier).addChapter(chapter);
    ref.read(currentChapterProvider.notifier).setCurrentChapter(chapter);
    await saveProject();

    AppLogger.info('Created chapter', title);
    return chapter;
  }

  @override
  Future<void> updateChapter(Chapter chapter) async {
    ref.read(chaptersProvider.notifier).updateChapter(chapter);

    // Update current chapter if it's the same
    final current = ref.read(currentChapterProvider);
    if (current?.id == chapter.id) {
      ref.read(currentChapterProvider.notifier).setCurrentChapter(chapter);
    }

    await saveProject();
  }

  @override
  Future<void> deleteChapter(String chapterId) async {
    ref.read(chaptersProvider.notifier).deleteChapter(chapterId);

    // Clear current chapter if it was deleted
    final current = ref.read(currentChapterProvider);
    if (current?.id == chapterId) {
      final chapters = ref.read(chaptersProvider);
      ref.read(currentChapterProvider.notifier).setCurrentChapter(
        chapters.isNotEmpty ? chapters.first : null,
      );
    }

    await saveProject();
  }

  @override
  void setCurrentChapter(Chapter chapter) {
    ref.read(currentChapterProvider.notifier).setCurrentChapter(chapter);
  }

  @override
  Future<void> addKnowledgeItem(KnowledgeItem item) async {
    ref.read(knowledgeBaseProvider.notifier).addItem(item);
    await saveProject();
  }

  @override
  Future<void> updateKnowledgeItem(KnowledgeItem item) async {
    ref.read(knowledgeBaseProvider.notifier).updateItem(item);
    await saveProject();
  }

  @override
  Future<void> deleteKnowledgeItem(String itemId) async {
    ref.read(knowledgeBaseProvider.notifier).deleteItem(itemId);
    await saveProject();
  }

  @override
  Future<void> saveEntity(EntityMetadata entity) async {
    final project = ref.read(projectProvider);
    if (project == null) return;

    // For local storage, save all entities (simpler than tracking individual changes)
    final entityStore = ref.read(entityStoreProvider);
    await _storage.saveEntities(project.path, entityStore.getAll());
  }

  @override
  Future<void> deleteEntity(String entityId) async {
    final project = ref.read(projectProvider);
    if (project == null) return;

    // For local storage, save all entities after deletion from store
    final entityStore = ref.read(entityStoreProvider);
    await _storage.saveEntities(project.path, entityStore.getAll());
  }

  @override
  Future<Project> createTemplateProject({String? customPath}) async {
    return await ErrorHandler.handleAsync(
      () async {
        // Create the project
        final templateProject = TemplateProjectService.createTemplateProject();
        final project = await _storage.createProject(
          templateProject.name,
          customPath: customPath,
        );

        // Set the project in state
        ref.read(projectProvider.notifier).setProject(project);

        // Create template chapters
        final templateChapters = TemplateProjectService.createTemplateChapters();
        ref.read(chaptersProvider.notifier).setChapters(templateChapters);

        // Clear old knowledge items (we're now using EntityMetadata instead)
        ref.read(knowledgeBaseProvider.notifier).clearItems();

        // Set first chapter as current and open in tab
        if (templateChapters.isNotEmpty) {
          ref.read(currentChapterProvider.notifier).setCurrentChapter(templateChapters.first);
          ref.read(tabStateProvider.notifier).openPreview(templateChapters.first);
        }

        // Load template entities into entity store
        final entityStore = ref.read(entityStoreProvider);
        final templateEntities = TemplateProjectService.createTemplateEntities();
        for (final entity in templateEntities) {
          entityStore.save(entity);
        }

        // Save everything
        await _storage.saveProject(project);
        await _storage.saveChapters(project.path, templateChapters);
        await _storage.saveKnowledgeBase(project.path, []); // Empty knowledge base
        await _storage.saveEntities(project.path, templateEntities);

        // Track as recent project
        await _recentProjects.addRecentProject(project.path);

        AppLogger.info('Created template project', project.name);
        return project;
      },
      'Create template project',
    ) ?? (throw Exception('Failed to create template project'));
  }
}
