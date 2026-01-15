import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/project.dart';
import '../models/chapter.dart';
import '../models/knowledge_item.dart';
import '../models/entity_metadata.dart';
import '../models/sync_metadata.dart';
import '../core/utils/logger.dart';
import '../core/exceptions/storage_exception.dart';

export '../core/exceptions/storage_exception.dart';

class StorageService {
  static const String _projectsDir = 'PlotEngine';
  static const String _projectFileName = 'project.json';
  static const String _chaptersFileName = 'chapters.json';
  static const String _knowledgeFileName = 'knowledge.json';
  static const String _entitiesFileName = 'entities.json';
  static const String _chaptersDir = 'chapters';
  static const String _entitiesDir = 'entities';
  static const String _syncMetadataFileName = 'sync_metadata.json';

  // Get the base directory for all projects
  Future<Directory> _getBaseDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final projectsDir = Directory(p.join(appDir.path, _projectsDir));
    if (!await projectsDir.exists()) {
      await _createDirectorySafe(projectsDir);
    }
    return projectsDir;
  }

  // Get project directory
  Future<Directory> _getProjectDirectory(String projectId) async {
    final baseDir = await _getBaseDirectory();
    final projectDir = Directory(p.join(baseDir.path, projectId));
    if (!await projectDir.exists()) {
      await _createDirectorySafe(projectDir);
    }
    return projectDir;
  }

  /// Safely create a directory with clear error messaging
  Future<void> _createDirectorySafe(Directory dir) async {
    try {
      await dir.create(recursive: true);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create directory: ${dir.path}', e, stackTrace);
      throw StorageException(
        'Failed to create directory "${p.basename(dir.path)}". '
        'This may be due to permission issues or cloud sync conflicts (e.g., OneDrive). '
        'Please try selecting a different location.',
        path: dir.path,
        originalError: e,
      );
    }
  }

  // Create a new project
  Future<Project> createProject(String name, {String? customPath}) async {
    final now = DateTime.now();
    final projectId = '${now.millisecondsSinceEpoch}';

    // Use custom path if provided, otherwise use default
    final Directory projectDir;
    if (customPath != null) {
      // Verify parent directory exists
      final parentDir = Directory(customPath);
      if (!await parentDir.exists()) {
        throw StorageException(
          'Selected folder does not exist: $customPath. Please select an existing folder.',
          path: customPath,
        );
      }

      final parentStat = await parentDir.stat();
      if (parentStat.type != FileSystemEntityType.directory) {
        throw StorageException(
          'Selected path is not a directory: $customPath',
          path: customPath,
        );
      }

      projectDir = Directory(p.join(customPath, name));
      if (!await projectDir.exists()) {
        await _createDirectorySafe(projectDir);
      }
    } else {
      projectDir = await _getProjectDirectory(projectId);
    }

    final project = Project(
      id: projectId,
      name: name,
      path: projectDir.path,
      createdAt: now,
      updatedAt: now,
    );

    await saveProject(project);
    return project;
  }

  // Save project metadata
  Future<void> saveProject(Project project) async {
    final projectDir = Directory(project.path);
    final projectFile = File(p.join(projectDir.path, _projectFileName));
    await projectFile.writeAsString(jsonEncode(project.toJson()));
  }

  // Load project from directory
  Future<Project?> loadProject(String projectPath) async {
    try {
      final projectFile = File(p.join(projectPath, _projectFileName));
      if (!await projectFile.exists()) {
        return null;
      }
      final content = await projectFile.readAsString();
      return Project.fromJson(jsonDecode(content));
    } catch (e, stackTrace) {
      AppLogger.error('Error loading project', e, stackTrace);
      return null;
    }
  }

  // List all projects
  Future<List<Project>> listProjects() async {
    final baseDir = await _getBaseDirectory();
    final projects = <Project>[];

    await for (final entity in baseDir.list()) {
      if (entity is Directory) {
        final project = await loadProject(entity.path);
        if (project != null) {
          projects.add(project);
        }
      }
    }

    return projects;
  }

  // Get chapters directory
  Future<Directory> _getChaptersDirectory(String projectPath) async {
    final chaptersDir = Directory(p.join(projectPath, _chaptersDir));
    if (!await chaptersDir.exists()) {
      await chaptersDir.create(recursive: true);
    }
    return chaptersDir;
  }

  // Get chapter content file path
  String _getChapterContentPath(String projectPath, String chapterId) {
    return p.join(projectPath, _chaptersDir, 'chapter_$chapterId.txt');
  }

  // Save chapters
  Future<void> saveChapters(String projectPath, List<Chapter> chapters) async {
    // Ensure chapters directory exists
    await _getChaptersDirectory(projectPath);

    // Save metadata to chapters.json
    final chaptersFile = File(p.join(projectPath, _chaptersFileName));
    final chaptersJson = chapters.map((c) => c.toMetadataJson()).toList();
    await chaptersFile.writeAsString(jsonEncode(chaptersJson));

    // Save each chapter's content to separate file
    for (final chapter in chapters) {
      final contentFile = File(_getChapterContentPath(projectPath, chapter.id));
      await contentFile.writeAsString(chapter.content);
    }

    AppLogger.save('Saved chapters', itemCount: chapters.length, path: projectPath);
  }

  // Load chapters
  Future<List<Chapter>> loadChapters(String projectPath) async {
    try {
      final chaptersFile = File(p.join(projectPath, _chaptersFileName));
      if (!await chaptersFile.exists()) {
        return [];
      }

      // Load metadata
      final metadataContent = await chaptersFile.readAsString();
      final List<dynamic> chaptersJson = jsonDecode(metadataContent);

      // Load each chapter with its content
      final chapters = <Chapter>[];
      for (final json in chaptersJson) {
        final chapterId = json['id'] as String;
        final contentFile = File(_getChapterContentPath(projectPath, chapterId));

        // Load content from file, or empty string if file doesn't exist
        String content = '';
        if (await contentFile.exists()) {
          content = await contentFile.readAsString();
        }

        chapters.add(Chapter.fromMetadataJson(json, content));
      }

      return chapters;
    } catch (e, stackTrace) {
      AppLogger.error('Error loading chapters', e, stackTrace);
      return [];
    }
  }

  // Save knowledge base
  Future<void> saveKnowledgeBase(String projectPath, List<KnowledgeItem> items) async {
    final knowledgeFile = File(p.join(projectPath, _knowledgeFileName));
    final itemsJson = items.map((i) => i.toJson()).toList();
    await knowledgeFile.writeAsString(jsonEncode(itemsJson));
  }

  // Load knowledge base
  Future<List<KnowledgeItem>> loadKnowledgeBase(String projectPath) async {
    try {
      final knowledgeFile = File(p.join(projectPath, _knowledgeFileName));
      if (!await knowledgeFile.exists()) {
        return [];
      }
      final content = await knowledgeFile.readAsString();
      final List<dynamic> itemsJson = jsonDecode(content);
      return itemsJson.map((json) => KnowledgeItem.fromJson(json)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error loading knowledge base', e, stackTrace);
      return [];
    }
  }

  // Get entities directory
  Future<Directory> _getEntitiesDirectory(String projectPath) async {
    final entitiesDir = Directory(p.join(projectPath, _entitiesDir));
    if (!await entitiesDir.exists()) {
      await entitiesDir.create(recursive: true);
    }
    return entitiesDir;
  }

  // Get entity description file path
  String _getEntityDescriptionPath(String projectPath, String entityId) {
    return p.join(projectPath, _entitiesDir, 'entity_$entityId.txt');
  }

  // Save entities
  Future<void> saveEntities(String projectPath, List<EntityMetadata> entities) async {
    // Ensure entities directory exists
    await _getEntitiesDirectory(projectPath);

    // Save metadata to entities.json
    final entitiesFile = File(p.join(projectPath, _entitiesFileName));
    final entitiesJson = entities.map((e) => e.toMetadataJson()).toList();
    await entitiesFile.writeAsString(jsonEncode(entitiesJson));

    // Save each entity's description to separate file
    for (final entity in entities) {
      final descriptionFile = File(_getEntityDescriptionPath(projectPath, entity.id));
      await descriptionFile.writeAsString(entity.description);
    }

    AppLogger.save('Saved entities', itemCount: entities.length, path: projectPath);
  }

  // Load entities
  Future<List<EntityMetadata>> loadEntities(String projectPath) async {
    try {
      final entitiesFile = File(p.join(projectPath, _entitiesFileName));
      if (!await entitiesFile.exists()) {
        // Try to load from old knowledge.json for backward compatibility
        return await _loadLegacyKnowledgeAsEntities(projectPath);
      }

      // Load metadata
      final metadataContent = await entitiesFile.readAsString();
      final List<dynamic> entitiesJson = jsonDecode(metadataContent);

      // Load each entity with its description
      final entities = <EntityMetadata>[];
      for (final json in entitiesJson) {
        final entityId = json['id'] as String;
        final descriptionFile = File(_getEntityDescriptionPath(projectPath, entityId));

        // Load description from file, or empty string if file doesn't exist
        String description = '';
        if (await descriptionFile.exists()) {
          description = await descriptionFile.readAsString();
        }

        entities.add(EntityMetadata.fromMetadataJson(json, description));
      }

      return entities;
    } catch (e, stackTrace) {
      AppLogger.error('Error loading entities', e, stackTrace);
      return [];
    }
  }

  // Load legacy knowledge.json and convert to entities
  // This is a stub for backward compatibility - legacy format not yet implemented
  Future<List<EntityMetadata>> _loadLegacyKnowledgeAsEntities(String projectPath) async {
    final knowledgeFile = File(p.join(projectPath, _knowledgeFileName));
    if (await knowledgeFile.exists()) {
      AppLogger.warn('Legacy knowledge.json found but conversion not implemented');
    }
    return [];
  }

  // Delete project
  Future<void> deleteProject(String projectPath) async {
    final projectDir = Directory(projectPath);
    if (await projectDir.exists()) {
      await projectDir.delete(recursive: true);
    }
  }

  // Save sync metadata
  Future<void> saveSyncMetadata(String projectPath, SyncMetadata metadata) async {
    final metadataFile = File(p.join(projectPath, _syncMetadataFileName));
    await metadataFile.writeAsString(jsonEncode(metadata.toJson()));
    AppLogger.info('Saved sync metadata', projectPath);
  }

  // Load sync metadata
  Future<SyncMetadata?> loadSyncMetadata(String projectPath) async {
    try {
      final metadataFile = File(p.join(projectPath, _syncMetadataFileName));
      if (!await metadataFile.exists()) {
        return null;
      }
      final content = await metadataFile.readAsString();
      return SyncMetadata.fromJson(jsonDecode(content));
    } catch (e, stackTrace) {
      AppLogger.error('Error loading sync metadata', e, stackTrace);
      return null;
    }
  }

  // Delete sync metadata (called when project is removed from cloud)
  Future<void> deleteSyncMetadata(String projectPath) async {
    final metadataFile = File(p.join(projectPath, _syncMetadataFileName));
    if (await metadataFile.exists()) {
      await metadataFile.delete();
    }
  }
}
