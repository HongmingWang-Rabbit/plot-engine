import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/app_state.dart';
import '../../state/status_state.dart';
import '../../l10n/app_localizations.dart';
import '../../services/base_project_service.dart';
import '../dialogs/new_project_dialog.dart';
import '../dialogs/open_project_dialog.dart';
import '../dialogs/settings_dialog.dart';
import '../dialogs/billing_dashboard_dialog.dart';

class AppToolbar extends ConsumerWidget {
  const AppToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectProvider);
    final projectService = ref.read(projectServiceProvider);
    final entityHighlightEnabled = ref.watch(entityHighlightProvider);
    final authUser = ref.watch(authUserProvider);

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
            ref.tr('app_title'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 32),
          // New Project Button
          _ToolbarButton(
            icon: Icons.create_new_folder,
            label: ref.tr('new_project'),
            onPressed: () => _handleNewProject(context, projectService, ref),
          ),
          const SizedBox(width: 8),
          // Template Project Button
          _ToolbarButton(
            icon: Icons.auto_awesome,
            label: ref.tr('try_template'),
            onPressed: () => _handleTemplateProject(context, projectService, ref),
          ),
          const SizedBox(width: 8),
          // Open Project Button
          _ToolbarButton(
            icon: Icons.folder_open,
            label: ref.tr('open_project'),
            onPressed: () => _handleOpenProject(context, projectService, ref),
          ),
          const SizedBox(width: 16),
          // Entity Highlight Toggle
          _ToolbarToggleButton(
            icon: entityHighlightEnabled ? Icons.highlight : Icons.highlight_off,
            label: entityHighlightEnabled ? ref.tr('hide_highlights') : ref.tr('show_highlights'),
            isActive: entityHighlightEnabled,
            onPressed: () {
              ref.read(entityHighlightProvider.notifier).toggle();
            },
          ),
          const Spacer(),
          if (project != null) ...[
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
            IconButton(
              icon: const Icon(Icons.edit, size: 16),
              onPressed: () => _handleEditProject(context, ref),
              tooltip: ref.tr('edit_project_name'),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
          const SizedBox(width: 16),
          // Credits Balance Display
          if (authUser != null) _CreditsDisplay(),
          const SizedBox(width: 8),
          // User Profile Button
          if (authUser != null)
            PopupMenuButton<String>(
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: CircleAvatar(
                  radius: 16,
                  backgroundImage: authUser.photoUrl != null
                      ? NetworkImage(authUser.photoUrl!)
                      : null,
                  child: authUser.photoUrl == null
                      ? const Icon(Icons.person, size: 20)
                      : null,
                ),
              ),
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authUser.displayName ?? ref.tr('user'),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authUser.email ?? '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'signout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout, size: 18),
                      const SizedBox(width: 8),
                      Text(ref.tr('sign_out')),
                    ],
                  ),
                ),
              ],
              onSelected: (value) async {
                if (value == 'signout') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(ref.tr('sign_out')),
                      content: Text(ref.tr('sign_out_confirm')),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(ref.tr('cancel')),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(ref.tr('sign_out')),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    await ref.read(authUserProvider.notifier).signOut();
                  }
                }
              },
              tooltip: authUser.displayName ?? 'User Profile',
            ),
          const SizedBox(width: 8),
          // Settings Button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _handleSettings(context),
            tooltip: ref.tr('settings'),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Future<void> _handleNewProject(
    BuildContext context,
    BaseProjectService service,
    WidgetRef ref,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const NewProjectDialog(),
    );

    if (result != null && context.mounted) {
      final name = result['name'] as String;
      final customPath = result['path'] as String?;

      final statusNotifier = ref.read(statusProvider.notifier);
      statusNotifier.showLoading('Creating project "$name"...');
      ref.read(projectLoadingProvider.notifier).setLoading(true);

      try {
        await service.createProject(name, customPath: customPath);
        statusNotifier.showSuccess('Project "$name" created');
      } catch (e) {
        statusNotifier.showError('Error creating project: $e');
      } finally {
        ref.read(projectLoadingProvider.notifier).setLoading(false);
      }
    }
  }

  Future<void> _handleOpenProject(
    BuildContext context,
    BaseProjectService service,
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
            try {
              // Delete the project
              await service.deleteProject(projectPath);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Project deleted successfully')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting project: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      );

      if (selectedPath != null && context.mounted) {
        final statusNotifier = ref.read(statusProvider.notifier);
        statusNotifier.showLoading('Opening project...');

        final success = await service.openProject(selectedPath);
        if (success) {
          final project = ref.read(projectProvider);
          statusNotifier.showSuccess('Project "${project?.name ?? 'Project'}" opened');
        } else {
          statusNotifier.showError('Error opening project');
        }
      }
    } catch (e) {
      ref.read(statusProvider.notifier).showError('Error: $e');
    }
  }

  Future<void> _handleTemplateProject(
    BuildContext context,
    BaseProjectService service,
    WidgetRef ref,
  ) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ref.tr('create_template_project')),
        content: Text(ref.tr('template_description')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(ref.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(ref.tr('create_template')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final statusNotifier = ref.read(statusProvider.notifier);
      statusNotifier.showLoading('Creating template project...');
      ref.read(projectLoadingProvider.notifier).setLoading(true);

      try {
        await service.createTemplateProject();
        statusNotifier.showSuccess('Template project created');
      } catch (e) {
        statusNotifier.showError('Error creating template project: $e');
      } finally {
        ref.read(projectLoadingProvider.notifier).setLoading(false);
      }
    }
  }

  void _handleSettings(BuildContext context) {
    showDialog(context: context, builder: (context) => const SettingsDialog());
  }

  Future<void> _handleEditProject(BuildContext context, WidgetRef ref) async {
    final project = ref.read(projectProvider);
    if (project == null) return;

    final controller = TextEditingController(text: project.name);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ref.tr('edit_project_name_title')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: ref.tr('project_name'),
            hintText: ref.tr('enter_project_name'),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.of(context).pop(value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(ref.tr('cancel')),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.of(context).pop(value);
              }
            },
            child: Text(ref.tr('save')),
          ),
        ],
      ),
    );

    if (newName != null && newName != project.name && context.mounted) {
      try {
        // Update the project with new name
        final updatedProject = project.copyWith(
          name: newName,
          updatedAt: DateTime.now(),
        );
        ref.read(projectProvider.notifier).updateProject(updatedProject);
        await ref.read(projectServiceProvider).saveProject();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Project renamed to "$newName"')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error renaming project: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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

class _CreditsDisplay extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditsAsync = ref.watch(creditsBalanceNotifierProvider);

    if (creditsAsync == null) {
      return const SizedBox(
        width: 80,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final balance = creditsAsync;
    final isLow = balance < 1.0;

    return InkWell(
      onTap: () => _showBillingDialog(context, ref),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isLow
              ? Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.5)
              : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 16,
              color: isLow
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              '\$${balance.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isLow
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            if (isLow) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.warning_amber,
                size: 14,
                color: Theme.of(context).colorScheme.error,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showBillingDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const BillingDashboardDialog(),
    );
  }
}

