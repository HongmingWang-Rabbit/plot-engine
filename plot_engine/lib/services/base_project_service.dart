import '../models/project.dart';
import '../models/chapter.dart';
import '../models/knowledge_item.dart';
import '../models/entity_metadata.dart';

/// Base interface for project services (local and cloud)
abstract class BaseProjectService {
  // Project operations
  Future<Project> createProject(String name, {String? customPath});
  Future<bool> openProject(String projectPath);
  Future<List<Project>> getRecentProjects();
  Future<String?> getLastProjectPath();
  Future<void> saveProject();
  Future<void> updateProjectMetadata(); // Just update project name/metadata, not chapters
  Future<List<Project>> listProjects();
  Future<void> deleteProject(String projectPath);

  // Chapter operations
  Future<Chapter> createChapter(String title);
  Future<void> updateChapter(Chapter chapter);
  Future<void> deleteChapter(String chapterId);
  Future<void> reorderChapters(int oldIndex, int newIndex);
  void setCurrentChapter(Chapter chapter);

  // Knowledge base operations
  Future<void> addKnowledgeItem(KnowledgeItem item);
  Future<void> updateKnowledgeItem(KnowledgeItem item);
  Future<void> deleteKnowledgeItem(String itemId);

  // Entity operations
  Future<void> saveEntity(EntityMetadata entity);
  Future<void> deleteEntity(String entityId);

  // Template project
  Future<Project> createTemplateProject({String? customPath});
}
