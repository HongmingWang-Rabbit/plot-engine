import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/knowledge_item.dart';
import '../../state/app_state.dart';
import '../../services/project_service.dart';
import '../dialogs/knowledge_item_dialog.dart';

class KnowledgePanel extends ConsumerStatefulWidget {
  const KnowledgePanel({super.key});

  @override
  ConsumerState<KnowledgePanel> createState() => _KnowledgePanelState();
}

class _KnowledgePanelState extends ConsumerState<KnowledgePanel> {
  String _selectedTab = 'character';

  List<KnowledgeItem> _getItemsForTab() {
    final items = ref.watch(knowledgeBaseProvider);
    return items.where((item) => item.type == _selectedTab).toList();
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectProvider);
    final items = _getItemsForTab();

    return Container(
      color: Theme.of(context).colorScheme.surface,
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
                const Icon(Icons.library_books, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Knowledge Base',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                if (project != null)
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: () => _handleAddItem(),
                    tooltip: 'Add item',
                  ),
              ],
            ),
          ),
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                _buildTab('character', Icons.person),
                _buildTab('location', Icons.place),
                _buildTab('object', Icons.category),
                _buildTab('event', Icons.event),
              ],
            ),
          ),
          // Content
          Expanded(
            child: project == null
                ? Center(
                    child: Text(
                      'Open a project to manage knowledge base',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                    ),
                  )
                : items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getIconForType(_selectedTab),
                              size: 48,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No ${_selectedTab}s yet',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _handleAddItem,
                              icon: const Icon(Icons.add),
                              label: Text('Add ${_selectedTab}'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return _KnowledgeCard(
                            item: items[index],
                            onEdit: () => _handleEditItem(items[index]),
                            onDelete: () => _handleDeleteItem(items[index]),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String tab, IconData icon) {
    final isSelected = _selectedTab == tab;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'character':
        return Icons.person;
      case 'location':
        return Icons.place;
      case 'object':
        return Icons.category;
      case 'event':
        return Icons.event;
      default:
        return Icons.info;
    }
  }

  Future<void> _handleAddItem() async {
    final item = await showDialog<KnowledgeItem>(
      context: context,
      builder: (context) => KnowledgeItemDialog(type: _selectedTab),
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

  Future<void> _handleEditItem(KnowledgeItem item) async {
    final updatedItem = await showDialog<KnowledgeItem>(
      context: context,
      builder: (context) => KnowledgeItemDialog(
        type: item.type,
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

class _KnowledgeCard extends StatelessWidget {
  final KnowledgeItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _KnowledgeCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 16),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Edit',
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, size: 16),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Delete',
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (item.appearances.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: item.appearances.map((chapter) {
                  return Chip(
                    label: Text(
                      chapter.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
