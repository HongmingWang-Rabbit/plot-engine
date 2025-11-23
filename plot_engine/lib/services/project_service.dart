import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project.dart';
import '../models/chapter.dart';
import '../models/knowledge_item.dart';
import '../state/app_state.dart';
import '../core/utils/logger.dart';
import 'storage_service.dart';
import 'recent_projects_service.dart';

class ProjectService {
  final Ref ref;
  final StorageService _storage = StorageService();
  final RecentProjectsService _recentProjects = RecentProjectsService();

  ProjectService(this.ref);

  // Create a new project
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

  // Open an existing project
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

        ref.read(projectProvider.notifier).setProject(project);
        ref.read(chaptersProvider.notifier).setChapters(chapters);
        ref.read(knowledgeBaseProvider.notifier).setItems(knowledgeItems);

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

  // Get recent projects
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

  // Get last opened project path
  Future<String?> getLastProjectPath() async {
    return await _recentProjects.getLastProjectPath();
  }

  // Save current project
  Future<void> saveProject() async {
    final project = ref.read(projectProvider);
    if (project == null) return;

    await _storage.saveProject(project);

    final chapters = ref.read(chaptersProvider);
    await _storage.saveChapters(project.path, chapters);

    final knowledgeItems = ref.read(knowledgeBaseProvider);
    await _storage.saveKnowledgeBase(project.path, knowledgeItems);
  }

  // List all projects
  Future<List<Project>> listProjects() async {
    return await _storage.listProjects();
  }

  // Delete project
  Future<void> deleteProject(String projectPath) async {
    await _storage.deleteProject(projectPath);
  }

  // Create a new chapter
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

  // Update chapter
  Future<void> updateChapter(Chapter chapter) async {
    ref.read(chaptersProvider.notifier).updateChapter(chapter);

    // Update current chapter if it's the same
    final current = ref.read(currentChapterProvider);
    if (current?.id == chapter.id) {
      ref.read(currentChapterProvider.notifier).setCurrentChapter(chapter);
    }

    await saveProject();
  }

  // Delete chapter
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

  // Set current chapter
  void setCurrentChapter(Chapter chapter) {
    ref.read(currentChapterProvider.notifier).setCurrentChapter(chapter);
  }

  // Add knowledge item
  Future<void> addKnowledgeItem(KnowledgeItem item) async {
    ref.read(knowledgeBaseProvider.notifier).addItem(item);
    await saveProject();
  }

  // Update knowledge item
  Future<void> updateKnowledgeItem(KnowledgeItem item) async {
    ref.read(knowledgeBaseProvider.notifier).updateItem(item);
    await saveProject();
  }

  // Delete knowledge item
  Future<void> deleteKnowledgeItem(String itemId) async {
    ref.read(knowledgeBaseProvider.notifier).deleteItem(itemId);
    await saveProject();
  }
}

// Provider for ProjectService
final projectServiceProvider = Provider<ProjectService>((ref) {
  return ProjectService(ref);
});
