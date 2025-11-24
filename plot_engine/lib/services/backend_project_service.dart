import '../models/project.dart';
import '../models/chapter.dart';
import 'api_client.dart';

/// Service for syncing projects and chapters with the backend
/// This service provides methods to interact with the PlotEngine backend API
class BackendProjectService {
  final ApiClient _apiClient;

  BackendProjectService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  // ===== Project Operations =====

  /// Create a new project on the backend
  Future<Project> createProject({
    required String title,
    String? description,
    String? genre,
    String? initialChapterTitle,
    String? initialChapterContent,
  }) async {
    final response = await _apiClient.post('/projects', {
      'title': title,
      if (description != null) 'description': description,
      if (genre != null) 'genre': genre,
      if (initialChapterTitle != null)
        'initialChapterTitle': initialChapterTitle,
      if (initialChapterContent != null)
        'initialChapterContent': initialChapterContent,
    });

    return _projectFromBackend(response['project']);
  }

  /// Get list of projects from backend
  Future<List<Project>> getProjects({int limit = 20, int offset = 0}) async {
    final response =
        await _apiClient.get('/projects?limit=$limit&offset=$offset');

    final projects = (response['projects'] as List)
        .map((p) => _projectFromBackend(p))
        .toList();

    return projects;
  }

  /// Get a single project by ID
  Future<Project> getProject(String projectId) async {
    final response = await _apiClient.get('/projects/$projectId');
    return _projectFromBackend(response['project']);
  }

  /// Update a project
  Future<Project> updateProject(
    String projectId, {
    String? title,
    String? description,
    String? genre,
  }) async {
    final response = await _apiClient.patch('/projects/$projectId', {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (genre != null) 'genre': genre,
    });

    return _projectFromBackend(response['project']);
  }

  /// Delete a project
  Future<void> deleteProject(String projectId) async {
    await _apiClient.delete('/projects/$projectId');
  }

  // ===== Chapter Operations =====

  /// Get chapters for a project
  Future<List<Chapter>> getChapters(String projectId,
      {int limit = 100, int offset = 0}) async {
    final response = await _apiClient
        .get('/projects/$projectId/chapters?limit=$limit&offset=$offset');

    final chapters = (response['chapters'] as List)
        .map((c) => _chapterFromBackend(c))
        .toList();

    return chapters;
  }

  /// Create a new chapter
  Future<Chapter> createChapter({
    required String projectId,
    required String title,
    String? content,
  }) async {
    final response = await _apiClient.post('/projects/$projectId/chapters', {
      'title': title,
      if (content != null) 'content': content,
    });

    return _chapterFromBackend(response['chapter']);
  }

  /// Update a chapter
  Future<Chapter> updateChapter({
    required String projectId,
    required String chapterId,
    String? title,
    String? content,
  }) async {
    final response = await _apiClient
        .patch('/projects/$projectId/chapters/$chapterId', {
      if (title != null) 'title': title,
      if (content != null) 'content': content,
    });

    return _chapterFromBackend(response['chapter']);
  }

  /// Delete a chapter
  Future<void> deleteChapter({
    required String projectId,
    required String chapterId,
  }) async {
    await _apiClient.delete('/projects/$projectId/chapters/$chapterId');
  }

  /// Reorder chapters
  Future<void> reorderChapters({
    required String projectId,
    required List<Map<String, dynamic>> chapterOrder,
  }) async {
    await _apiClient.post('/projects/$projectId/chapters/reorder', {
      'chapters': chapterOrder,
    });
  }

  // ===== AI Operations =====

  /// Extract entities from text
  Future<Map<String, dynamic>> extractEntities({
    required String text,
    String provider = 'anthropic',
  }) async {
    final response = await _apiClient.post('/ai/extract/entities', {
      'text': text,
      'provider': provider,
    });

    return response['entities'] as Map<String, dynamic>;
  }

  /// Check consistency of a chapter
  Future<List<dynamic>> checkConsistency({
    required String projectId,
    required String chapterId,
    int contextRange = 5,
  }) async {
    final response = await _apiClient.post('/ai/validate/consistency', {
      'projectId': projectId,
      'chapterId': chapterId,
      'contextRange': contextRange,
    });

    return response['issues'] as List<dynamic>;
  }

  /// Get foreshadowing suggestions
  Future<Map<String, dynamic>> getForeshadowingSuggestions({
    required String projectId,
    required String chapterId,
  }) async {
    final response = await _apiClient.post('/ai/suggest/foreshadow', {
      'projectId': projectId,
      'chapterId': chapterId,
    });

    return response['suggestions'] as Map<String, dynamic>;
  }

  // ===== Helper Methods =====

  /// Convert backend project JSON to Project model
  Project _projectFromBackend(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['title'] as String,
      path: json['path'] as String? ?? '', // Backend may not have local path
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert backend chapter JSON to Chapter model
  Chapter _chapterFromBackend(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String? ?? '',
      order: json['orderIndex'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert local Project to backend format
  Map<String, dynamic> projectToBackend(Project project) {
    return {
      'title': project.name,
      // Backend doesn't store local path
    };
  }

  /// Convert local Chapter to backend format
  Map<String, dynamic> chapterToBackend(Chapter chapter) {
    return {
      'title': chapter.title,
      'content': chapter.content,
      'orderIndex': chapter.order,
    };
  }
}
