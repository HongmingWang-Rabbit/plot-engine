import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/app_state.dart';
import '../../state/tab_state.dart';
import '../../services/project_service.dart';
import '../dialogs/new_project_dialog.dart';
import '../dialogs/new_chapter_dialog.dart';
import '../dialogs/open_project_dialog.dart';
import '../dialogs/settings_dialog.dart';

class AppToolbar extends ConsumerWidget {
  const AppToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectProvider);
    final currentChapter = ref.watch(currentChapterProvider);
    final chapters = ref.watch(chaptersProvider);
    final projectService = ref.read(projectServiceProvider);
    final entityHighlightEnabled = ref.watch(entityHighlightProvider);

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          // App Title
          Text(
            'PlotEngine',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 32),
          // New Project Button
          _ToolbarButton(
            icon: Icons.create_new_folder,
            label: 'New Project',
            onPressed: () => _handleNewProject(context, projectService),
          ),
          const SizedBox(width: 8),
          // Template Project Button
          _ToolbarButton(
            icon: Icons.auto_awesome,
            label: 'Try Template',
            onPressed: () => _handleTemplateProject(context, projectService),
          ),
          const SizedBox(width: 8),
          // Open Project Button
          _ToolbarButton(
            icon: Icons.folder_open,
            label: 'Open Project',
            onPressed: () => _handleOpenProject(context, projectService, ref),
          ),
          const SizedBox(width: 8),
          // New Chapter Button
          _ToolbarButton(
            icon: Icons.add,
            label: 'New Chapter',
            onPressed: project != null
                ? () => _handleNewChapter(context, projectService)
                : null,
          ),
          const SizedBox(width: 16),
          // Entity Highlight Toggle
          _ToolbarToggleButton(
            icon: entityHighlightEnabled ? Icons.highlight : Icons.highlight_off,
            label: entityHighlightEnabled ? 'Hide Highlights' : 'Show Highlights',
            isActive: entityHighlightEnabled,
            onPressed: () {
              ref.read(entityHighlightProvider.notifier).toggle();
            },
          ),
          const Spacer(),
          // Chapter Dropdown
          if (project != null && chapters.isNotEmpty)
            PopupMenuButton(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.book, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      currentChapter?.title ?? 'Select Chapter',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, size: 20),
                  ],
                ),
              ),
              itemBuilder: (context) => chapters.map((chapter) {
                return PopupMenuItem(
                  value: chapter,
                  child: Text(chapter.title),
                );
              }).toList(),
              onSelected: (chapter) {
                // Open chapter in preview mode
                ref.read(tabStateProvider.notifier).openPreview(chapter);
                // Also update current chapter for backward compatibility
                projectService.setCurrentChapter(chapter);
              },
            ),
          if (project != null)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                project.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          const SizedBox(width: 8),
          // Settings Button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _handleSettings(context),
            tooltip: 'Settings',
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Future<void> _handleNewProject(
    BuildContext context,
    ProjectService service,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const NewProjectDialog(),
    );

    if (result != null && context.mounted) {
      final name = result['name'] as String;
      final customPath = result['path'] as String?;

      try {
        await service.createProject(name, customPath: customPath);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Project "$name" created successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error creating project: $e')));
        }
      }
    }
  }

  Future<void> _handleOpenProject(
    BuildContext context,
    ProjectService service,
    WidgetRef ref,
  ) async {
    try {
      final projects = await service.getRecentProjects();
      if (!context.mounted) return;

      final selectedPath = await showDialog<String>(
        context: context,
        builder: (context) => OpenProjectDialog(
          projects: projects,
          onDeleteProject: (projectPath) async {
            // Delete the project
            await service.deleteProject(projectPath);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Project deleted successfully')),
              );
            }
          },
        ),
      );

      if (selectedPath != null && context.mounted) {
        final success = await service.openProject(selectedPath);
        if (context.mounted) {
          if (success) {
            final project = ref.read(projectProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Project "${project?.name ?? 'Project'}" opened'),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error opening project')),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handleNewChapter(
    BuildContext context,
    ProjectService service,
  ) async {
    final title = await showDialog<String>(
      context: context,
      builder: (context) => const NewChapterDialog(),
    );

    if (title != null && context.mounted) {
      try {
        await service.createChapter(title);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Chapter "$title" created')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error creating chapter: $e')));
        }
      }
    }
  }

  Future<void> _handleTemplateProject(
    BuildContext context,
    ProjectService service,
  ) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Template Project'),
        content: const Text(
          'This will create a sample project with example chapters and entities to help you get started with PlotEngine.\n\n'
          'You can explore features like:\n'
          '• Entity recognition and highlighting\n'
          '• Hover tooltips for entity details\n'
          '• Click interactions to create/edit entities\n\n'
          'Would you like to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Create Template'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await service.createTemplateProject();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Template project created! Explore the sample chapters to learn about entity features.'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating template project: $e')),
          );
        }
      }
    }
  }

  void _handleSettings(BuildContext context) {
    showDialog(context: context, builder: (context) => const SettingsDialog());
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

class _ToolbarToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onPressed;

  const _ToolbarToggleButton({
    required this.icon,
    required this.label,
    required this.isActive,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: isActive
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
        foregroundColor: isActive
          ? Theme.of(context).colorScheme.onPrimaryContainer
          : null,
      ),
    );
  }
}
