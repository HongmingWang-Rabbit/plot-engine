import 'package:flutter/material.dart';
import '../models/entity_type.dart';
import '../models/entity_metadata.dart';

class EntityCreationDialog extends StatefulWidget {
  final String entityName;
  final Function(EntityMetadata) onSave;

  const EntityCreationDialog({
    super.key,
    required this.entityName,
    required this.onSave,
  });

  @override
  State<EntityCreationDialog> createState() => _EntityCreationDialogState();
}

class _EntityCreationDialogState extends State<EntityCreationDialog> {
  late TextEditingController _nameController;
  late TextEditingController _summaryController;
  EntityType _selectedType = EntityType.character;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.entityName);
    _summaryController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }

    final metadata = EntityMetadata(
      name: _nameController.text,
      type: _selectedType,
      summary: _summaryController.text,
      description: '', // Empty description - will be filled in text editor
    );

    widget.onSave(metadata);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Entity'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<EntityType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: [
                  EntityType.character,
                  EntityType.location,
                  EntityType.object,
                  EntityType.event,
                ].map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _summaryController,
                decoration: const InputDecoration(
                  labelText: 'Summary',
                  border: OutlineInputBorder(),
                  hintText: 'Brief summary shown in tooltips',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              Text(
                'Click on the entity name in your text to open it and edit the full description.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
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
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
