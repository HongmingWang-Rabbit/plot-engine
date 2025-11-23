import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../models/project.dart';
import '../../services/folder_picker_service.dart';

class OpenProjectDialog extends StatelessWidget {
  final List<Project> projects;

  const OpenProjectDialog({
    super.key,
    required this.projects,
  });

  Future<String?> _browseForProject(BuildContext context) async {
    // Use custom picker on macOS for "New Folder" button support
    if (Platform.isMacOS) {
      return await FolderPickerService.pickDirectory();
    } else {
      return await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Project Folder',
      );
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
              child: projects.isEmpty
                  ? Center(
                      child: Text(
                        'No recent projects',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: projects.length,
                      itemBuilder: (context, index) {
                        final project = projects[index];
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
