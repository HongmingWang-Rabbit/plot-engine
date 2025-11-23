import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../models/knowledge_item.dart';
import '../../models/knowledge_tab.dart';
import '../../models/chapter.dart';
import '../../state/app_state.dart';
import '../../state/tab_state.dart';
import '../../services/project_service.dart';
import '../../core/utils/icon_mapper.dart';
import '../../core/widgets/chapter_card.dart';
import '../../core/widgets/knowledge_card.dart';
import '../dialogs/knowledge_item_dialog.dart';

class KnowledgePanel extends ConsumerStatefulWidget {
  const KnowledgePanel({super.key});

  @override
  ConsumerState<KnowledgePanel> createState() => _KnowledgePanelState();
}

class _KnowledgePanelState extends ConsumerState<KnowledgePanel> {
  String _selectedTabId = 'chapters';

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectProvider);
    final tabs = project?.knowledgeTabs ?? KnowledgeTab.defaultTabs();

    // Ensure selected tab exists
    if (!tabs.any((t) => t.id == _selectedTabId)) {
      _selectedTabId = tabs.first.id;
    }

    final selectedTab = tabs.firstWhere((t) => t.id == _selectedTabId);

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          // Vertical Sidebar
          Container(
            width: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Column(
              children: [
                // Tabs
                ...tabs.map((tab) => _buildVerticalTab(tab)),
                const Spacer(),
                // Add tab button
                if (project != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: () => _handleAddTab(),
                      tooltip: 'Add custom tab',
                    ),
                  ),
              ],
            ),
          ),
          // Content Area
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildHeaderIcon(selectedTab, project),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selectedTab.name,
                          style: Theme.of(context).textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (selectedTab.isDeletable)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => _handleEditTab(selectedTab),
                          tooltip: 'Edit tab',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      if (project != null && selectedTab.id != 'chapters')
                        IconButton(
                          icon: const Icon(Icons.add, size: 20),
                          onPressed: () => _handleAddItem(selectedTab),
                          tooltip: 'Add item',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: selectedTab.id == 'chapters'
                      ? _buildChaptersList()
                      : _buildKnowledgeList(selectedTab),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalTab(KnowledgeTab tab) {
    final isSelected = _selectedTabId == tab.id;
    final project = ref.watch(projectProvider);

    return InkWell(
      onTap: () => setState(() => _selectedTabId = tab.id),
      onSecondaryTap: tab.isDeletable ? () => _showTabContextMenu(tab) : null,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Center(
          child: _buildTabIcon(tab, project, isSelected),
        ),
      ),
    );
  }

  Widget _buildTabIcon(KnowledgeTab tab, project, bool isSelected) {
    if (tab.hasCustomIcon && project != null) {
      final iconPath = '${project.path}/${tab.customIconPath}';
      final iconFile = File(iconPath);

      if (iconFile.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.file(
            iconFile,
            width: 32,
            height: 32,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                IconMapper.fromString(tab.icon),
                size: 24,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              );
            },
          ),
        );
      }
    }

    return Icon(
      IconMapper.fromString(tab.icon),
      size: 24,
      color: isSelected
          ? Theme.of(context).colorScheme.onPrimaryContainer
          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
    );
  }

  Widget _buildHeaderIcon(KnowledgeTab tab, project) {
    if (tab.hasCustomIcon && project != null) {
      final iconPath = '${project.path}/${tab.customIconPath}';
      final iconFile = File(iconPath);

      if (iconFile.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.file(
            iconFile,
            width: 20,
            height: 20,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(IconMapper.fromString(tab.icon), size: 20);
            },
          ),
        );
      }
    }

    return Icon(IconMapper.fromString(tab.icon), size: 20);
  }

  Widget _buildChaptersList() {
    final project = ref.watch(projectProvider);
    final chapters = ref.watch(chaptersProvider);
    final currentChapter = ref.watch(currentChapterProvider);

    if (project == null) {
      return _buildEmptyState('Open a project to see chapters', Icons.menu_book);
    }

    if (chapters.isEmpty) {
      return _buildEmptyState('No chapters yet\nClick "New Chapter" to start', Icons.menu_book);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        final isSelected = currentChapter?.id == chapter.id;
        return ChapterCard(
          chapter: chapter,
          isSelected: isSelected,
          onTap: () {
            // Open chapter in preview mode
            ref.read(tabStateProvider.notifier).openPreview(chapter);
            // Also update current chapter for backward compatibility
            ref.read(projectServiceProvider).setCurrentChapter(chapter);
          },
        );
      },
    );
  }

  Widget _buildKnowledgeList(KnowledgeTab tab) {
    final project = ref.watch(projectProvider);
    final items = ref.watch(knowledgeBaseProvider);
    final tabItems = items.where((item) => item.type == tab.id).toList();

    if (project == null) {
      return _buildEmptyState('Open a project to manage ${tab.name.toLowerCase()}', IconMapper.fromString(tab.icon));
    }

    if (tabItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              IconMapper.fromString(tab.icon),
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No ${tab.name.toLowerCase()} yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _handleAddItem(tab),
              icon: const Icon(Icons.add),
              label: Text('Add ${tab.name.toLowerCase().replaceAll(RegExp(r's$'), '')}'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: tabItems.length,
      itemBuilder: (context, index) {
        return KnowledgeCard(
          item: tabItems[index],
          onEdit: () => _handleEditItem(tabItems[index], tab),
          onDelete: () => _handleDeleteItem(tabItems[index]),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }

  void _showTabContextMenu(KnowledgeTab tab) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(0, 100, 200, 0),
      items: [
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
          onTap: () => Future.delayed(Duration.zero, () => _handleEditTab(tab)),
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ),
          onTap: () => Future.delayed(Duration.zero, () => _handleDeleteTab(tab)),
        ),
      ],
    );
  }

  Future<void> _handleAddTab() async {
    final project = ref.read(projectProvider);
    if (project == null) return;

    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) => _TabDialog(projectPath: project.path),
    );

    if (result != null && mounted) {
      final newTab = KnowledgeTab(
        id: result['id']!,
        name: result['name']!,
        icon: result['icon']!,
        customIconPath: result['customIconPath'],
        order: project.knowledgeTabs.length,
      );

      final updatedProject = project.copyWith(
        knowledgeTabs: [...project.knowledgeTabs, newTab],
        updatedAt: DateTime.now(),
      );

      ref.read(projectProvider.notifier).updateProject(updatedProject);
      await ref.read(projectServiceProvider).saveProject();

      setState(() {
        _selectedTabId = newTab.id;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${newTab.name} tab added')),
        );
      }
    }
  }

  Future<void> _handleEditTab(KnowledgeTab tab) async {
    final project = ref.read(projectProvider);
    if (project == null) return;

    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) => _TabDialog(tab: tab, projectPath: project.path),
    );

    if (result != null && mounted) {
      final updatedTab = tab.copyWith(
        name: result['name'],
        icon: result['icon'],
        customIconPath: result['customIconPath'],
      );

      final updatedTabs = project.knowledgeTabs.map((t) {
        return t.id == tab.id ? updatedTab : t;
      }).toList();

      final updatedProject = project.copyWith(
        knowledgeTabs: updatedTabs,
        updatedAt: DateTime.now(),
      );

      ref.read(projectProvider.notifier).updateProject(updatedProject);
      await ref.read(projectServiceProvider).saveProject();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${updatedTab.name} tab updated')),
        );
      }
    }
  }

  Future<void> _handleDeleteTab(KnowledgeTab tab) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tab'),
        content: Text(
          'Are you sure you want to delete "${tab.name}"?\n\nAll items in this tab will also be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final project = ref.read(projectProvider);
      if (project == null) return;

      // Delete all items in this tab
      final items = ref.read(knowledgeBaseProvider);
      final tabItems = items.where((item) => item.type == tab.id);
      for (final item in tabItems) {
        await ref.read(projectServiceProvider).deleteKnowledgeItem(item.id);
      }

      // Remove tab
      final updatedTabs = project.knowledgeTabs.where((t) => t.id != tab.id).toList();
      final updatedProject = project.copyWith(
        knowledgeTabs: updatedTabs,
        updatedAt: DateTime.now(),
      );

      ref.read(projectProvider.notifier).updateProject(updatedProject);
      await ref.read(projectServiceProvider).saveProject();

      // Switch to chapters tab
      setState(() {
        _selectedTabId = 'chapters';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tab.name} tab deleted')),
        );
      }
    }
  }

  Future<void> _handleAddItem(KnowledgeTab tab) async {
    final item = await showDialog<KnowledgeItem>(
      context: context,
      builder: (context) => KnowledgeItemDialog(type: tab.id),
    );

    if (item != null && mounted) {
      try {
        await ref.read(projectServiceProvider).addKnowledgeItem(item);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${item.name} added successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding item: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleEditItem(KnowledgeItem item, KnowledgeTab tab) async {
    final updatedItem = await showDialog<KnowledgeItem>(
      context: context,
      builder: (context) => KnowledgeItemDialog(
        type: tab.id,
        item: item,
      ),
    );

    if (updatedItem != null && mounted) {
      try {
        await ref.read(projectServiceProvider).updateKnowledgeItem(updatedItem);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${updatedItem.name} updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating item: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleDeleteItem(KnowledgeItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(projectServiceProvider).deleteKnowledgeItem(item.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${item.name} deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting item: $e')),
          );
        }
      }
    }
  }
}

class _TabDialog extends StatefulWidget {
  final KnowledgeTab? tab;
  final String projectPath;

  const _TabDialog({this.tab, required this.projectPath});

  @override
  State<_TabDialog> createState() => _TabDialogState();
}

class _TabDialogState extends State<_TabDialog> {
  late final TextEditingController _nameController;
  String _selectedIcon = 'label';
  String? _customIconPath; // Relative path
  File? _customIconFile;

  final List<Map<String, String>> _availableIcons = [
    {'name': 'label', 'label': 'Default'},
    {'name': 'person', 'label': 'Person'},
    {'name': 'place', 'label': 'Place'},
    {'name': 'category', 'label': 'Object'},
    {'name': 'event', 'label': 'Event'},
    {'name': 'groups', 'label': 'Groups'},
    {'name': 'timeline', 'label': 'Timeline'},
    {'name': 'inventory', 'label': 'Inventory'},
    {'name': 'auto_awesome', 'label': 'Magic'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tab?.name ?? '');
    _selectedIcon = widget.tab?.icon ?? 'label';
    _customIconPath = widget.tab?.customIconPath;

    // Load existing custom icon if present
    if (_customIconPath != null) {
      final iconFile = File('${widget.projectPath}/$_customIconPath');
      if (iconFile.existsSync()) {
        _customIconFile = iconFile;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomIcon() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final sourcePath = result.files.single.path!;
      final sourceFile = File(sourcePath);
      final extension = sourcePath.split('.').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'tab_icon_$timestamp.$extension';

      // Create icons directory in project
      final iconsDir = Directory('${widget.projectPath}/icons');
      if (!await iconsDir.exists()) {
        await iconsDir.create(recursive: true);
      }

      // Copy file to project
      final destPath = '${widget.projectPath}/icons/$fileName';
      await sourceFile.copy(destPath);

      setState(() {
        _customIconPath = 'icons/$fileName';
        _customIconFile = File(destPath);
      });
    }
  }

  void _clearCustomIcon() {
    setState(() {
      _customIconPath = null;
      _customIconFile = null;
    });
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.tab == null ? 'Add Custom Tab' : 'Edit Tab'),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Tab Name',
                  hintText: 'e.g., Factions, Timelines, Notes',
                ),
              ),
              const SizedBox(height: 24),
              // Custom Image Section
              Row(
                children: [
                  Text(
                    'Custom Icon',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(width: 8),
                  if (_customIconFile != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: _clearCustomIcon,
                      tooltip: 'Remove custom icon',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (_customIconFile != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.file(
                          _customIconFile!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Custom image selected',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: _pickCustomIcon,
                  icon: const Icon(Icons.image, size: 18),
                  label: const Text('Choose Image from Computer'),
                ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Or choose preset icon',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableIcons.map((iconData) {
                  final isSelected = _selectedIcon == iconData['name'] && _customIconFile == null;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedIcon = iconData['name']!;
                        _clearCustomIcon();
                      });
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).dividerColor,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            IconMapper.fromString(iconData['name']!),
                            size: 24,
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            iconData['label']!,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontSize: 8,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.onPrimaryContainer
                                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a tab name')),
              );
              return;
            }

            // Generate ID from name (lowercase, replace spaces with underscores)
            final id = widget.tab?.id ?? name.toLowerCase().replaceAll(' ', '_');

            Navigator.of(context).pop({
              'id': id,
              'name': name,
              'icon': _selectedIcon,
              'customIconPath': _customIconPath,
            });
          },
          child: Text(widget.tab == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}
