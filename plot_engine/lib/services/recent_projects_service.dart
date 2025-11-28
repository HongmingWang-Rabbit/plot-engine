import 'package:shared_preferences/shared_preferences.dart';
import 'package:macos_secure_bookmarks/macos_secure_bookmarks.dart';
import 'dart:convert';
import 'dart:io';
import '../core/utils/logger.dart';

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
      AppLogger.error('Error creating bookmark', e);
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
      // Start accessing the security-scoped resource
      await _secureBookmarks.startAccessingSecurityScopedResource(resolvedFile);
      return resolvedFile.path;
    } catch (e) {
      AppLogger.error('Error resolving bookmark', e);
      return null;
    }
  }

  // Get recent projects with their paths
  Future<List<String>> getRecentProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final recentJson = prefs.getString(_recentProjectsKey);

    AppLogger.debug('Loading recent projects', recentJson != null ? 'Found data' : 'No data');

    if (recentJson == null) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(recentJson);
      final bookmarks =
          decoded.map((json) => ProjectBookmark.fromJson(json)).toList();

      AppLogger.debug('Found bookmarks', bookmarks.length);

      // Try to resolve each bookmark and return valid paths
      final validPaths = <String>[];
      for (final bookmark in bookmarks) {
        AppLogger.debug('Trying to resolve bookmark', bookmark.path);
        final resolvedPath = await _resolveBookmark(bookmark.bookmarkData);
        if (resolvedPath != null) {
          AppLogger.debug('Resolved bookmark successfully', resolvedPath);
          validPaths.add(resolvedPath);
        } else {
          AppLogger.warn('Failed to resolve bookmark', bookmark.path);
          // Fallback: try using the stored path directly
          if (await Directory(bookmark.path).exists()) {
            AppLogger.info('Using fallback path', bookmark.path);
            validPaths.add(bookmark.path);
          }
        }
      }

      AppLogger.info('Loaded recent projects', validPaths.length);
      return validPaths;
    } catch (e) {
      AppLogger.error('Error loading recent projects', e);
      return [];
    }
  }

  // Add project to recent list
  Future<void> addRecentProject(String projectPath) async {
    final prefs = await SharedPreferences.getInstance();

    // Create bookmark for this path
    final bookmarkData = await _createBookmark(projectPath);
    if (bookmarkData == null) {
      AppLogger.warn('Could not create bookmark for project', projectPath);
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
        AppLogger.error('Error loading recent projects', e);
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

    AppLogger.debug('Loading last project', lastJson != null ? 'Found data' : 'No data');

    if (lastJson == null) {
      return null;
    }

    try {
      final bookmark = ProjectBookmark.fromJson(jsonDecode(lastJson));
      AppLogger.debug('Trying to resolve last project bookmark', bookmark.path);

      final resolvedPath = await _resolveBookmark(bookmark.bookmarkData);
      if (resolvedPath != null) {
        AppLogger.info('Resolved last project bookmark', resolvedPath);
        return resolvedPath;
      } else {
        AppLogger.warn('Failed to resolve last project bookmark', bookmark.path);
        // Fallback: try using the stored path directly
        if (await Directory(bookmark.path).exists()) {
          AppLogger.info('Using fallback path for last project', bookmark.path);
          return bookmark.path;
        }
      }
      return null;
    } catch (e) {
      AppLogger.error('Error getting last project', e);
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
      AppLogger.error('Error removing recent project', e);
    }
  }
}
