import 'package:shared_preferences/shared_preferences.dart';
import 'package:macos_secure_bookmarks/macos_secure_bookmarks.dart';
import 'dart:convert';
import 'dart:io';

// Store both path and bookmark data for each project
class ProjectBookmark {
  final String path;
  final String bookmarkData; // Base64 encoded bookmark

  ProjectBookmark({required this.path, required this.bookmarkData});

  Map<String, dynamic> toJson() => {
        'path': path,
        'bookmarkData': bookmarkData,
      };

  factory ProjectBookmark.fromJson(Map<String, dynamic> json) {
    return ProjectBookmark(
      path: json['path'] as String,
      bookmarkData: json['bookmarkData'] as String,
    );
  }
}

class RecentProjectsService {
  static const String _recentProjectsKey = 'recent_projects_bookmarks';
  static const String _lastProjectKey = 'last_project_bookmark';
  static const int _maxRecentProjects = 10;

  final SecureBookmarks _secureBookmarks = SecureBookmarks();

  // Create a security-scoped bookmark for a project path
  Future<String?> _createBookmark(String projectPath) async {
    try {
      if (!Platform.isMacOS) {
        return null; // Bookmarks only needed on macOS
      }

      // bookmark() returns the bookmark data, already encoded
      final bookmark = await _secureBookmarks.bookmark(File(projectPath));
      return bookmark;
    } catch (e) {
      print('Error creating bookmark: $e');
      return null;
    }
  }

  // Resolve a bookmark to get the file path with access
  Future<String?> _resolveBookmark(String bookmarkData) async {
    try {
      if (!Platform.isMacOS) {
        return null;
      }

      // resolveBookmark() expects the bookmark string directly
      final resolvedFile = await _secureBookmarks.resolveBookmark(bookmarkData);

      if (resolvedFile != null) {
        // Start accessing the security-scoped resource
        await _secureBookmarks.startAccessingSecurityScopedResource(resolvedFile);
        return resolvedFile.path;
      }
      return null;
    } catch (e) {
      print('Error resolving bookmark: $e');
      return null;
    }
  }

  // Get recent projects with their paths
  Future<List<String>> getRecentProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final recentJson = prefs.getString(_recentProjectsKey);

    if (recentJson == null) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(recentJson);
      final bookmarks =
          decoded.map((json) => ProjectBookmark.fromJson(json)).toList();

      // Try to resolve each bookmark and return valid paths
      final validPaths = <String>[];
      for (final bookmark in bookmarks) {
        final resolvedPath = await _resolveBookmark(bookmark.bookmarkData);
        if (resolvedPath != null) {
          validPaths.add(resolvedPath);
        }
      }

      return validPaths;
    } catch (e) {
      print('Error loading recent projects: $e');
      return [];
    }
  }

  // Add project to recent list
  Future<void> addRecentProject(String projectPath) async {
    final prefs = await SharedPreferences.getInstance();

    // Create bookmark for this path
    final bookmarkData = await _createBookmark(projectPath);
    if (bookmarkData == null) {
      print('Warning: Could not create bookmark for $projectPath');
      // On non-macOS or if bookmark creation fails, store path anyway
      return;
    }

    final newBookmark = ProjectBookmark(
      path: projectPath,
      bookmarkData: bookmarkData,
    );

    // Get existing bookmarks
    final recentJson = prefs.getString(_recentProjectsKey);
    List<ProjectBookmark> bookmarks = [];

    if (recentJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(recentJson);
        bookmarks =
            decoded.map((json) => ProjectBookmark.fromJson(json)).toList();
      } catch (e) {
        print('Error loading recent projects: $e');
      }
    }

    // Remove if already exists (we'll add it to the front)
    bookmarks.removeWhere((b) => b.path == projectPath);

    // Add to front
    bookmarks.insert(0, newBookmark);

    // Keep only max items
    if (bookmarks.length > _maxRecentProjects) {
      bookmarks = bookmarks.sublist(0, _maxRecentProjects);
    }

    // Save
    final bookmarksJson = bookmarks.map((b) => b.toJson()).toList();
    await prefs.setString(_recentProjectsKey, jsonEncode(bookmarksJson));

    // Also save as last opened
    await prefs.setString(_lastProjectKey, jsonEncode(newBookmark.toJson()));
  }

  // Get last opened project path (resolving the bookmark)
  Future<String?> getLastProjectPath() async {
    final prefs = await SharedPreferences.getInstance();
    final lastJson = prefs.getString(_lastProjectKey);

    if (lastJson == null) {
      return null;
    }

    try {
      final bookmark = ProjectBookmark.fromJson(jsonDecode(lastJson));
      return await _resolveBookmark(bookmark.bookmarkData);
    } catch (e) {
      print('Error getting last project: $e');
      return null;
    }
  }

  // Clear recent projects
  Future<void> clearRecentProjects() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentProjectsKey);
    await prefs.remove(_lastProjectKey);
  }

  // Remove a project from recents (if it was deleted or moved)
  Future<void> removeRecentProject(String projectPath) async {
    final prefs = await SharedPreferences.getInstance();
    final recentJson = prefs.getString(_recentProjectsKey);

    if (recentJson == null) {
      return;
    }

    try {
      final List<dynamic> decoded = jsonDecode(recentJson);
      var bookmarks =
          decoded.map((json) => ProjectBookmark.fromJson(json)).toList();

      bookmarks.removeWhere((b) => b.path == projectPath);

      final bookmarksJson = bookmarks.map((b) => b.toJson()).toList();
      await prefs.setString(_recentProjectsKey, jsonEncode(bookmarksJson));

      // If this was the last project, clear it
      final lastJson = prefs.getString(_lastProjectKey);
      if (lastJson != null) {
        final lastBookmark = ProjectBookmark.fromJson(jsonDecode(lastJson));
        if (lastBookmark.path == projectPath) {
          await prefs.remove(_lastProjectKey);
        }
      }
    } catch (e) {
      print('Error removing recent project: $e');
    }
  }
}
