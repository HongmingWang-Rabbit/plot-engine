import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/project.dart';
import '../models/chapter.dart';
import '../models/knowledge_item.dart';
import '../models/entity_metadata.dart';

class StorageService {
  static const String _projectsDir = 'PlotEngine';
  static const String _projectFileName = 'project.json';
  static const String _chaptersFileName = 'chapters.json';
  static const String _knowledgeFileName = 'knowledge.json';
  static const String _entitiesFileName = 'entities.json';
  static const String _chaptersDir = 'chapters';
  static const String _entitiesDir = 'entities';

  // Get the base directory for all projects
  Future<Directory> _getBaseDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final projectsDir = Directory('${appDir.path}/$_projectsDir');
    if (!await projectsDir.exists()) {
      await projectsDir.create(recursive: true);
    }
    return projectsDir;
  }

  // Get project directory
  Future<Directory> _getProjectDirectory(String projectId) async {
    final baseDir = await _getBaseDirectory();
    final projectDir = Directory('${baseDir.path}/$projectId');
    if (!await projectDir.exists()) {
      await projectDir.create(recursive: true);
    }
    return projectDir;
  }

  // Create a new project
  Future<Project> createProject(String name, {String? customPath}) async {
    final now = DateTime.now();
    final projectId = '${now.millisecondsSinceEpoch}';

    // Use custom path if provided, otherwise use default
    final Directory projectDir;
    if (customPath != null) {
      projectDir = Directory('$customPath/$name');
      if (!await projectDir.exists()) {
        await projectDir.create(recursive: true);
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
    final projectFile = File('${projectDir.path}/$_projectFileName');
    await projectFile.writeAsString(jsonEncode(project.toJson()));
  }

  // Load project from directory
  Future<Project?> loadProject(String projectPath) async {
    try {
      final projectFile = File('$projectPath/$_projectFileName');
      if (!await projectFile.exists()) {
        return null;
      }
      final content = await projectFile.readAsString();
      return Project.fromJson(jsonDecode(content));
    } catch (e) {
      print('Error loading project: $e');
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
    final chaptersDir = Directory('$projectPath/$_chaptersDir');
    if (!await chaptersDir.exists()) {
      await chaptersDir.create(recursive: true);
    }
    return chaptersDir;
  }

  // Get chapter content file path
  String _getChapterContentPath(String projectPath, String chapterId) {
    return '$projectPath/$_chaptersDir/chapter_$chapterId.txt';
  }

  // Save chapters
  Future<void> saveChapters(String projectPath, List<Chapter> chapters) async {
    print('📝 Saving chapters to: $projectPath');
    print('📝 Number of chapters: ${chapters.length}');

    // Ensure chapters directory exists
    await _getChaptersDirectory(projectPath);

    // Save metadata to chapters.json
    final chaptersFile = File('$projectPath/$_chaptersFileName');
    final chaptersJson = chapters.map((c) => c.toMetadataJson()).toList();
    await chaptersFile.writeAsString(jsonEncode(chaptersJson));
    print('📝 Saved chapters metadata to: ${chaptersFile.path}');

    // Save each chapter's content to separate file
    for (final chapter in chapters) {
      final contentFile = File(_getChapterContentPath(projectPath, chapter.id));
      await contentFile.writeAsString(chapter.content);
      print('📝 Saved chapter ${chapter.id} (${chapter.content.length} chars) to: ${contentFile.path}');
    }

    print('✅ All chapters saved successfully');
  }

  // Load chapters
  Future<List<Chapter>> loadChapters(String projectPath) async {
    try {
      final chaptersFile = File('$projectPath/$_chaptersFileName');
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
    } catch (e) {
      print('Error loading chapters: $e');
      return [];
    }
  }

  // Save knowledge base
  Future<void> saveKnowledgeBase(String projectPath, List<KnowledgeItem> items) async {
    final knowledgeFile = File('$projectPath/$_knowledgeFileName');
    final itemsJson = items.map((i) => i.toJson()).toList();
    await knowledgeFile.writeAsString(jsonEncode(itemsJson));
  }

  // Load knowledge base
  Future<List<KnowledgeItem>> loadKnowledgeBase(String projectPath) async {
    try {
      final knowledgeFile = File('$projectPath/$_knowledgeFileName');
      if (!await knowledgeFile.exists()) {
        return [];
      }
      final content = await knowledgeFile.readAsString();
      final List<dynamic> itemsJson = jsonDecode(content);
      return itemsJson.map((json) => KnowledgeItem.fromJson(json)).toList();
    } catch (e) {
      print('Error loading knowledge base: $e');
      return [];
    }
  }

  // Get entities directory
  Future<Directory> _getEntitiesDirectory(String projectPath) async {
    final entitiesDir = Directory('$projectPath/$_entitiesDir');
    if (!await entitiesDir.exists()) {
      await entitiesDir.create(recursive: true);
    }
    return entitiesDir;
  }

  // Get entity description file path
  String _getEntityDescriptionPath(String projectPath, String entityId) {
    return '$projectPath/$_entitiesDir/entity_$entityId.txt';
  }

  // Save entities
  Future<void> saveEntities(String projectPath, List<EntityMetadata> entities) async {
    print('📝 Saving entities to: $projectPath');
    print('📝 Number of entities: ${entities.length}');

    // Ensure entities directory exists
    await _getEntitiesDirectory(projectPath);

    // Save metadata to entities.json
    final entitiesFile = File('$projectPath/$_entitiesFileName');
    final entitiesJson = entities.map((e) => e.toMetadataJson()).toList();
    await entitiesFile.writeAsString(jsonEncode(entitiesJson));
    print('📝 Saved entities metadata to: ${entitiesFile.path}');

    // Save each entity's description to separate file
    for (final entity in entities) {
      final descriptionFile = File(_getEntityDescriptionPath(projectPath, entity.id));
      await descriptionFile.writeAsString(entity.description);
      print('📝 Saved entity ${entity.id} (${entity.description.length} chars) to: ${descriptionFile.path}');
    }

    print('✅ All entities saved successfully');
  }

  // Load entities
  Future<List<EntityMetadata>> loadEntities(String projectPath) async {
    try {
      final entitiesFile = File('$projectPath/$_entitiesFileName');
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
    } catch (e) {
      print('Error loading entities: $e');
      return [];
    }
  }

  // Load legacy knowledge.json and convert to entities
  Future<List<EntityMetadata>> _loadLegacyKnowledgeAsEntities(String projectPath) async {
    try {
      final knowledgeFile = File('$projectPath/$_knowledgeFileName');
      if (!await knowledgeFile.exists()) {
        return [];
      }
      final content = await knowledgeFile.readAsString();
      final List<dynamic> itemsJson = jsonDecode(content);

      // Convert old KnowledgeItems to EntityMetadata
      // This is for backward compatibility only
      print('⚠️  Converting legacy knowledge.json to entities format');
      return [];
    } catch (e) {
      print('Error loading legacy knowledge: $e');
      return [];
    }
  }

  // Delete project
  Future<void> deleteProject(String projectPath) async {
    final projectDir = Directory(projectPath);
    if (await projectDir.exists()) {
      await projectDir.delete(recursive: true);
    }
  }
}
