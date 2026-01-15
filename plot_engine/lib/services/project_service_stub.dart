import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project.dart';
import '../models/chapter.dart';
import '../models/knowledge_item.dart';
import '../models/entity_metadata.dart';
import 'base_project_service.dart';

/// Stub implementation for web platform
/// On web, WebProjectService is used instead of ProjectService.
/// This stub exists to satisfy imports but should never be instantiated on web.
class ProjectService implements BaseProjectService {
  final Ref ref;

  ProjectService(this.ref);

  @override
  Future<Project> createProject(String name, {String? customPath}) {
    throw UnsupportedError('ProjectService is not available on web');
  }

  @override
  Future<bool> openProject(String projectPath) {
    throw UnsupportedError('ProjectService is not available on web');
  }

  @override
  Future<List<Project>> getRecentProjects() {
    throw UnsupportedError('ProjectService is not available on web');
  }

  @override
  Future<String?> getLastProjectPath() {
    throw UnsupportedError('ProjectService is not available on web');
  }

  @override
  Future<void> updateProjectMetadata() {
    throw UnsupportedError('ProjectService is not available on web');
  }

  @override
  Future<void> saveProject() {
    throw UnsupportedError('ProjectService is not available on web');
  }

  @override
  Future<List<Project>> listProjects() {
    throw UnsupportedError('ProjectService is not available on web');
  }

  @override
  Future<void> deleteProject(String projectPath) {
    throw UnsupportedError('ProjectService is not available on web');
  }

  @override
  Future<Chapter> createChapter(String title) {
    throw UnsupportedError('ProjectService is not available on web');
  }

  @override
  Future<void> updateChapter(Chapter chapter) {
    throw UnsupportedError('ProjectService is not available on web');
  }

  @override
  Future<void> deleteChapter(String chapterId) {
    throw UnsupportedError('ProjectService is not available on web');
  }

  @override
  Future<void> reorderChapters(int oldIndex, int newIndex) {
    throw UnsupportedError('ProjectService is not available on web');
  }

  @override
  void setCurrentChapter(Chapter chapter) {
    throw UnsupportedError('ProjectService is not available on web');
  }

  @override
  Future<void> addKnowledgeItem(KnowledgeItem item) {
    throw UnsupportedError('ProjectService is not available on web');
  }

  @override
  Future<void> updateKnowledgeItem(KnowledgeItem item) {
    throw UnsupportedError('ProjectService is not available on web');
  }

  @override
  Future<void> deleteKnowledgeItem(String itemId) {
    throw UnsupportedError('ProjectService is not available on web');
  }

  @override
  Future<void> saveEntity(EntityMetadata entity) {
    throw UnsupportedError('ProjectService is not available on web');
  }

  @override
  Future<void> deleteEntity(String entityId) {
    throw UnsupportedError('ProjectService is not available on web');
  }

  @override
  Future<Project> createTemplateProject({String? customPath}) {
    throw UnsupportedError('ProjectService is not available on web');
  }
}
