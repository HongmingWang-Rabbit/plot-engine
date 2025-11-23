import 'package:flutter/material.dart';
import '../../models/knowledge_item.dart';

class KnowledgePanel extends StatefulWidget {
  const KnowledgePanel({super.key});

  @override
  State<KnowledgePanel> createState() => _KnowledgePanelState();
}

class _KnowledgePanelState extends State<KnowledgePanel> {
  String _selectedTab = 'characters';

  // Mock data
  final List<KnowledgeItem> _mockCharacters = [
    KnowledgeItem(
      id: '1',
      name: 'Sarah Connor',
      type: 'character',
      description: 'Protagonist. Strong-willed detective with a troubled past.',
      appearances: ['ch1', 'ch2'],
    ),
    KnowledgeItem(
      id: '2',
      name: 'James Miller',
      type: 'character',
      description: 'Mysterious stranger who knows too much.',
      appearances: ['ch1'],
    ),
  ];

  final List<KnowledgeItem> _mockLocations = [
    KnowledgeItem(
      id: '3',
      name: 'Riverside Cafe',
      type: 'location',
      description: 'A cozy cafe by the river where key meetings happen.',
      appearances: ['ch1', 'ch2'],
    ),
    KnowledgeItem(
      id: '4',
      name: 'Old Library',
      type: 'location',
      description: 'Abandoned library holding ancient secrets.',
      appearances: ['ch2'],
    ),
  ];

  final List<KnowledgeItem> _mockObjects = [
    KnowledgeItem(
      id: '5',
      name: 'Golden Locket',
      type: 'object',
      description: 'Mysterious locket with unknown origins.',
      appearances: ['ch1'],
    ),
  ];

  final List<KnowledgeItem> _mockEvents = [
    KnowledgeItem(
      id: '6',
      name: 'The Festival',
      type: 'event',
      description: 'Annual town festival where the incident occurred.',
      appearances: ['ch1'],
    ),
  ];

  List<KnowledgeItem> _getItemsForTab() {
    switch (_selectedTab) {
      case 'characters':
        return _mockCharacters;
      case 'locations':
        return _mockLocations;
      case 'objects':
        return _mockObjects;
      case 'events':
        return _mockEvents;
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
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
                _buildTab('characters', Icons.person),
                _buildTab('locations', Icons.place),
                _buildTab('objects', Icons.category),
                _buildTab('events', Icons.event),
              ],
            ),
          ),
          // Content
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _getItemsForTab().length,
              itemBuilder: (context, index) {
                return _KnowledgeCard(item: _getItemsForTab()[index]);
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
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}

class _KnowledgeCard extends StatelessWidget {
  final KnowledgeItem item;

  const _KnowledgeCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
