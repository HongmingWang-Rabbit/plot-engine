import '../models/project.dart';
import '../models/chapter.dart';
import '../models/knowledge_item.dart';

/// Base interface for project services (local and cloud)
abstract class BaseProjectService {
  // Project operations
  Future<Project> createProject(String name, {String? customPath});
  Future<bool> openProject(String projectPath);
  Future<List<Project>> getRecentProjects();
  Future<String?> getLastProjectPath();
  Future<void> saveProject();
  Future<List<Project>> listProjects();
  Future<void> deleteProject(String projectPath);

  // Chapter operations
  Future<Chapter> createChapter(String title);
  Future<void> updateChapter(Chapter chapter);
  Future<void> deleteChapter(String chapterId);
  void setCurrentChapter(Chapter chapter);

  // Knowledge base operations
  Future<void> addKnowledgeItem(KnowledgeItem item);
  Future<void> updateKnowledgeItem(KnowledgeItem item);
  Future<void> deleteKnowledgeItem(String itemId);

  // Template project
  Future<Project> createTemplateProject({String? customPath});
}
