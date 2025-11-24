import 'package:flutter/material.dart';
import 'dart:io';
import '../../models/project.dart';
import '../../services/folder_picker_service.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/extensions/context_extensions.dart';

class OpenProjectDialog extends StatefulWidget {
  final List<Project> projects;
  final Function(String projectPath)? onDeleteProject;

  const OpenProjectDialog({
    super.key,
    required this.projects,
    this.onDeleteProject,
  });

  @override
  State<OpenProjectDialog> createState() => _OpenProjectDialogState();
}

class _OpenProjectDialogState extends State<OpenProjectDialog> {
  late List<Project> _projects;

  Future<String?> _browseForProject(BuildContext context) async {
    return await FolderPickerService.pickDirectory(
      dialogTitle: 'Select Project Folder',
    );
  }

  @override
  void initState() {
    super.initState();
    _projects = List.from(widget.projects);
  }

  Future<void> _openInFinder(String path) async {
    try {
      // Use macOS 'open' command to reveal the folder in Finder
      await Process.run('open', [path]);
    } catch (e) {
      // Silently fail if opening fails
      debugPrint('Failed to open folder in Finder: $e');
    }
  }

  Future<void> _deleteProject(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text(
          'Are you sure you want to delete "${project.name}"?\n\nThis will permanently delete all project files.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Call the deletion callback
      widget.onDeleteProject?.call(project.path);

      // Update local state to remove the project from the list
      setState(() {
        _projects.removeWhere((p) => p.path == project.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Open Project'),
      content: SizedBox(
        width: 500,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Browse button
            OutlinedButton.icon(
              onPressed: () async {
                final path = await _browseForProject(context);
                if (path != null && context.mounted) {
                  Navigator.of(context).pop(path);
                }
              },
              icon: const Icon(Icons.folder_open),
              label: const Text('Browse for Project...'),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Recent Projects',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            // Recent projects list
            Expanded(
              child: _projects.isEmpty
                  ? EmptyState(
                      icon: Icons.folder_open,
                      message: 'No recent projects',
                      subtitle: 'Use the Browse button above to open a project',
                    )
                  : ListView.builder(
                      itemCount: _projects.length,
                      itemBuilder: (context, index) {
                        final project = _projects[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.book),
                            title: Text(project.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  project.path,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Updated: ${_formatDate(project.updatedAt)}',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.folder_open),
                                  tooltip: 'Open in Finder',
                                  onPressed: () => _openInFinder(project.path),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: 'Delete Project',
                                  color: Colors.red[400],
                                  onPressed: () => _deleteProject(project),
                                ),
                              ],
                            ),
                            onTap: () => Navigator.of(context).pop(project.path),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
