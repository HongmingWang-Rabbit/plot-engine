import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RecentProjectsService {
  static const String _recentProjectsKey = 'recent_projects';
  static const String _lastProjectKey = 'last_project_path';
  static const int _maxRecentProjects = 10;

  // Get recent projects list
  Future<List<String>> getRecentProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final recentJson = prefs.getString(_recentProjectsKey);

    if (recentJson == null) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(recentJson);
      return decoded.cast<String>();
    } catch (e) {
      print('Error loading recent projects: $e');
      return [];
    }
  }

  // Add project to recent list
  Future<void> addRecentProject(String projectPath) async {
    final prefs = await SharedPreferences.getInstance();
    var recentProjects = await getRecentProjects();

    // Remove if already exists (we'll add it to the front)
    recentProjects.remove(projectPath);

    // Add to front
    recentProjects.insert(0, projectPath);

    // Keep only max items
    if (recentProjects.length > _maxRecentProjects) {
      recentProjects = recentProjects.sublist(0, _maxRecentProjects);
    }

    // Save
    await prefs.setString(_recentProjectsKey, jsonEncode(recentProjects));

    // Also save as last opened
    await prefs.setString(_lastProjectKey, projectPath);
  }

  // Get last opened project
  Future<String?> getLastProjectPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastProjectKey);
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
    var recentProjects = await getRecentProjects();
    recentProjects.remove(projectPath);
    await prefs.setString(_recentProjectsKey, jsonEncode(recentProjects));

    // If this was the last project, clear it
    final lastPath = await getLastProjectPath();
    if (lastPath == projectPath) {
      await prefs.remove(_lastProjectKey);
    }
  }
}
