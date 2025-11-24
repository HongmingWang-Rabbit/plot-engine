import 'package:flutter/material.dart';
import '../models/entity_metadata.dart';

class EntityDetailScreen extends StatefulWidget {
  final EntityMetadata metadata;
  final Function(EntityMetadata)? onSave;

  const EntityDetailScreen({
    super.key,
    required this.metadata,
    this.onSave,
  });

  @override
  State<EntityDetailScreen> createState() => _EntityDetailScreenState();
}

class _EntityDetailScreenState extends State<EntityDetailScreen> {
  late TextEditingController _nameController;
  late TextEditingController _summaryController;
  late TextEditingController _descriptionController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.metadata.name);
    _summaryController = TextEditingController(text: widget.metadata.summary);
    _descriptionController = TextEditingController(text: widget.metadata.description);
  }

  @override
  void didUpdateWidget(EntityDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controllers when metadata changes
    if (oldWidget.metadata.id != widget.metadata.id) {
      _nameController.text = widget.metadata.name;
      _summaryController.text = widget.metadata.summary;
      _descriptionController.text = widget.metadata.description;
      // Reset editing state when switching entities
      _isEditing = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _summaryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    final updatedMetadata = widget.metadata.copyWith(
      name: _nameController.text,
      summary: _summaryController.text,
      description: _descriptionController.text,
    );

    widget.onSave?.call(updatedMetadata);
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Entity' : 'Entity Details'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _save,
              tooltip: 'Save',
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              tooltip: 'Edit',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(
                'Name',
                _nameController,
                1,
              ),
              const SizedBox(height: 16),
              _buildTypeChip(),
              const SizedBox(height: 24),
              _buildInfoCard(
                'Summary',
                _summaryController,
                3,
              ),
              const SizedBox(height: 24),
              _buildInfoCard(
                'Description',
                _descriptionController,
                10,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, TextEditingController controller, int maxLines) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            if (_isEditing)
              TextField(
                controller: controller,
                maxLines: maxLines,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              )
            else
              Text(
                controller.text.isEmpty ? 'No ${label.toLowerCase()} provided' : controller.text,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip() {
    return Row(
      children: [
        Text(
          'Type:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(width: 8),
        Chip(
          label: Text(widget.metadata.type.displayName),
          backgroundColor: _getTypeColor(),
        ),
      ],
    );
  }

  Color _getTypeColor() {
    switch (widget.metadata.type.name) {
      case 'character':
        return Colors.blue.shade100;
      case 'location':
        return Colors.green.shade100;
      case 'object':
        return Colors.orange.shade100;
      case 'event':
        return Colors.purple.shade100;
      case 'custom':
        return Colors.teal.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
}
