import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../models/project.dart';
import '../../services/folder_picker_service.dart';
import '../../core/constants/ui_constants.dart';
import '../../core/widgets/empty_state.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../state/settings_state.dart';
import '../../core/utils/logger.dart';

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

class _OpenProjectDialogState extends ConsumerState<OpenProjectDialog>
    with SingleTickerProviderStateMixin {
  late List<Project> _localProjects;
  List<Project> _cloudProjects = [];
  bool _isLoadingCloud = false;
  TabController? _tabController;

  bool get _isLoggedIn => ref.watch(authUserProvider) != null;
  bool get _showTabs => !kIsWeb && _isLoggedIn;

  Future<String?> _browseForProject(BuildContext context) async {
    return await FolderPickerService.pickDirectory(
      dialogTitle: ref.tr('select_project_folder'),
    );
  }

  @override
  void initState() {
    super.initState();
    _localProjects = List.from(widget.projects);

    // Initialize tab controller after first frame when we know if user is logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_showTabs) {
        _tabController = TabController(length: 2, vsync: this);
        _tabController!.addListener(() {
          if (_tabController!.index == 1 && _cloudProjects.isEmpty && !_isLoadingCloud) {
            _loadCloudProjects();
          }
        });
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadCloudProjects() async {
    setState(() {
      _isLoadingCloud = true;
    });

    try {
      final cloudService = ref.read(cloudProjectServiceProvider);
      final projects = await cloudService.listProjects();
      if (mounted) {
        setState(() {
          _cloudProjects = projects;
          _isLoadingCloud = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCloud = false;
        });
      }
      AppLogger.error('Error loading cloud projects', e);
    }
  }

  Future<void> _openInFinder(String path) async {
    try {
      if (Platform.isWindows) {
        await Process.run('explorer', [path]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [path]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [path]);
      }
    } catch (e) {
      AppLogger.debug('Failed to open folder', e);
    }
  }

  Future<void> _deleteProject(Project project, {bool isCloud = false}) async {
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
      if (isCloud) {
        try {
          final cloudService = ref.read(cloudProjectServiceProvider);
          await cloudService.deleteProject(project.path);
          setState(() {
            _cloudProjects.removeWhere((p) => p.path == project.path);
          });
        } catch (e) {
          AppLogger.error('Error deleting cloud project', e);
        }
      } else {
        widget.onDeleteProject?.call(project.path);
        setState(() {
          _localProjects.removeWhere((p) => p.path == project.path);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-check if we should show tabs (in case auth state changed)
    final showTabs = _showTabs && _tabController != null;

    return AlertDialog(
      title: Text(ref.tr('open_project_title')),
      content: SizedBox(
        width: UIConstants.dialogWidth,
        height: UIConstants.dialogHeightMedium,
        child: showTabs ? _buildTabbedContent() : _buildLocalOnlyContent(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(ref.tr('cancel')),
        ),
      ],
    );
  }

  Widget _buildTabbedContent() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.folder, size: 18),
              text: ref.tr('local_storage'),
            ),
            Tab(
              icon: const Icon(Icons.cloud, size: 18),
              text: ref.tr('cloud_storage'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildLocalProjectsTab(),
              _buildCloudProjectsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocalOnlyContent() {
    return _buildLocalProjectsTab();
  }

  Widget _buildLocalProjectsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Browse button
        OutlinedButton.icon(
          onPressed: () async {
            final path = await _browseForProject(context);
            if (path != null && context.mounted) {
              Navigator.of(context).pop({'path': path, 'isCloud': false});
            }
          },
          icon: const Icon(Icons.folder_open),
          label: Text(ref.tr('browse_project')),
        ),
        const SizedBox(height: 16),
        Text(
          ref.tr('recent_projects'),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _localProjects.isEmpty
              ? EmptyState(
                  icon: Icons.folder_open,
                  message: ref.tr('no_recent_projects'),
                  subtitle: ref.tr('use_browse_hint'),
                )
              : ListView.builder(
                  itemCount: _localProjects.length,
                  itemBuilder: (context, index) {
                    final project = _localProjects[index];
                    return _buildProjectCard(project, isCloud: false);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCloudProjectsTab() {
    if (_isLoadingCloud) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Refresh button
        OutlinedButton.icon(
          onPressed: _loadCloudProjects,
          icon: const Icon(Icons.refresh),
          label: Text(ref.tr('refresh')),
        ),
        const SizedBox(height: 16),
        Text(
          ref.tr('cloud_projects'),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _cloudProjects.isEmpty
              ? EmptyState(
                  icon: Icons.cloud_off,
                  message: ref.tr('no_cloud_projects'),
                  subtitle: ref.tr('create_cloud_project_hint'),
                )
              : ListView.builder(
                  itemCount: _cloudProjects.length,
                  itemBuilder: (context, index) {
                    final project = _cloudProjects[index];
                    return _buildProjectCard(project, isCloud: true);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProjectCard(Project project, {required bool isCloud}) {
    return Card(
      child: ListTile(
        leading: Icon(isCloud ? Icons.cloud : Icons.book),
        title: Text(project.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isCloud)
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
            if (!isCloud)
              IconButton(
                icon: const Icon(Icons.folder_open),
                tooltip: ref.tr('open_in_finder'),
                onPressed: () => _openInFinder(project.path),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: ref.tr('delete_project'),
              color: Colors.red[400],
              onPressed: () => _deleteProject(project, isCloud: isCloud),
            ),
          ],
        ),
        onTap: () => Navigator.of(context).pop({
          'path': project.path,
          'isCloud': isCloud,
        }),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
