import '../models/project.dart';
import '../models/chapter.dart';
import '../models/entity_metadata.dart';
import '../models/entity_type.dart';
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
  /// Returns project with all data (chapters, entities, etc.)
  Future<Project> getProject(String projectId) async {
    final response = await _apiClient.get('/projects/$projectId');
    return _projectFromBackend(response['project']);
  }

  /// Get full project response (for accessing chapters/entities)
  Future<Map<String, dynamic>> getProjectResponse(String projectId) async {
    final response = await _apiClient.get('/projects/$projectId');
    return response['project'] as Map<String, dynamic>;
  }

  /// Get entities from project response
  List<EntityMetadata> getEntitiesFromProject(Map<String, dynamic> projectResponse) {
    final entitiesList = projectResponse['entities'] as List?;
    if (entitiesList == null) return [];

    return entitiesList.map((e) => _entityFromBackend(e)).toList();
  }

  /// Fetch entities from dedicated endpoint (fallback if not in project response)
  Future<List<EntityMetadata>> getEntities(String projectId) async {
    try {
      final response = await _apiClient.get('/projects/$projectId/entities');
      final entitiesList = response['entities'] as List?;
      if (entitiesList == null) return [];
      return entitiesList.map((e) => _entityFromBackend(e)).toList();
    } catch (e) {
      print('[BackendProjectService] Error fetching entities: $e');
      return [];
    }
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
    int? orderIndex,
  }) async {
    final response = await _apiClient.post('/projects/$projectId/chapters', {
      'title': title,
      if (content != null) 'content': content,
      if (orderIndex != null) 'order_index': orderIndex,
    });

    // Response may be wrapped in 'chapter' or direct
    final chapterData = response['chapter'] ?? response;
    return _chapterFromBackend(chapterData as Map<String, dynamic>);
  }

  /// Update a chapter
  Future<Chapter> updateChapter({
    required String projectId,
    required String chapterId,
    String? title,
    String? content,
    int? orderIndex,
  }) async {
    final response = await _apiClient
        .patch('/projects/$projectId/chapters/$chapterId', {
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (orderIndex != null) 'order_index': orderIndex,
    });

    // Response may be wrapped in 'chapter' or direct
    final chapterData = response['chapter'] ?? response;
    return _chapterFromBackend(chapterData as Map<String, dynamic>);
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

  // ===== Entity Operations =====

  /// Create a new entity
  Future<Map<String, dynamic>> createEntity({
    required String projectId,
    required String name,
    required String type,
    required String summary,
    required String description,
    String? customType,
  }) async {
    final response = await _apiClient.post('/projects/$projectId/entities', {
      'name': name,
      'type': type,
      'summary': summary,
      'description': description,
      if (customType != null) 'customType': customType,
    });

    return response['entity'] as Map<String, dynamic>;
  }

  /// Update an entity
  Future<Map<String, dynamic>> updateEntity({
    required String projectId,
    required String entityId,
    String? name,
    String? summary,
    String? description,
    String? type,
  }) async {
    final response = await _apiClient.patch(
      '/projects/$projectId/entities/$entityId',
      {
        if (name != null) 'name': name,
        if (summary != null) 'summary': summary,
        if (description != null) 'description': description,
        if (type != null) 'type': type,
      },
    );

    return response['entity'] as Map<String, dynamic>;
  }

  /// Delete an entity
  Future<void> deleteEntity({
    required String projectId,
    required String entityId,
  }) async {
    await _apiClient.delete('/projects/$projectId/entities/$entityId');
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
    final now = DateTime.now();
    return Project(
      id: json['id'] as String,
      name: json['title'] as String,
      path: json['path'] as String? ?? '', // Backend may not have local path
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

  /// Convert backend entity JSON to EntityMetadata model
  EntityMetadata _entityFromBackend(Map<String, dynamic> json) {
    final now = DateTime.now();

    // Map backend type to EntityType enum
    EntityType entityType;
    switch (json['type'] as String) {
      case 'character':
        entityType = EntityType.character;
        break;
      case 'location':
        entityType = EntityType.location;
        break;
      case 'object':
        entityType = EntityType.object;
        break;
      case 'event':
        entityType = EntityType.event;
        break;
      case 'custom':
        entityType = EntityType.custom;
        break;
      default:
        entityType = EntityType.character;
    }

    return EntityMetadata(
      id: json['id'] as String,
      name: json['name'] as String,
      type: entityType,
      summary: json['summary'] as String? ?? '',
      description: json['description'] as String? ?? '',
      customType: json['customType'] as String?,
    );
  }

  /// Convert backend chapter JSON to Chapter model
  /// Handles both snake_case (API) and camelCase field names
  Chapter _chapterFromBackend(Map<String, dynamic> json) {
    final now = DateTime.now();
    final id = json['id']?.toString() ?? 'chapter_${now.millisecondsSinceEpoch}';
    final title = json['title']?.toString() ?? 'Untitled Chapter';

    return Chapter(
      id: id,
      title: title,
      content: json['content']?.toString() ?? '',
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
