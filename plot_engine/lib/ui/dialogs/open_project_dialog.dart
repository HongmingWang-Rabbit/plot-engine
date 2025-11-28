import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../models/project.dart';
import '../../services/folder_picker_service.dart';
import '../../core/widgets/empty_state.dart';
import '../../l10n/app_localizations.dart';

class OpenProjectDialog extends ConsumerStatefulWidget {
  final List<Project> projects;
  final Function(String projectPath)? onDeleteProject;

  const OpenProjectDialog({
    super.key,
    required this.projects,
    this.onDeleteProject,
  });

  @override
  ConsumerState<OpenProjectDialog> createState() => _OpenProjectDialogState();
}

class _OpenProjectDialogState extends ConsumerState<OpenProjectDialog> {
  late List<Project> _projects;

  Future<String?> _browseForProject(BuildContext context) async {
    return await FolderPickerService.pickDirectory(
      dialogTitle: ref.tr('select_project_folder'),
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
        title: Text(ref.tr('delete_project')),
        content: Text(
          '${ref.tr('delete_project_confirm').replaceAll('this project', '"${project.name}"')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(ref.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(ref.tr('delete')),
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
      title: Text(ref.tr('open_project_title')),
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
              label: Text(ref.tr('browse_project')),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              ref.tr('recent_projects'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            // Recent projects list
            Expanded(
              child: _projects.isEmpty
                  ? EmptyState(
                      icon: Icons.folder_open,
                      message: ref.tr('no_recent_projects'),
                      subtitle: ref.tr('use_browse_hint'),
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
                                  '${ref.tr('updated')}: ${_formatDate(project.updatedAt)}',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.folder_open),
                                  tooltip: ref.tr('open_in_finder'),
                                  onPressed: () => _openInFinder(project.path),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: ref.tr('delete_project'),
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
          child: Text(ref.tr('cancel')),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
