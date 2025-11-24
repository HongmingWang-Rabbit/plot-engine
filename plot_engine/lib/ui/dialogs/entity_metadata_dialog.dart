import 'package:flutter/material.dart';
import '../../models/entity_metadata.dart';
import '../../models/entity_type.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/dialog_actions.dart' as core;

class EntityMetadataDialog extends StatefulWidget {
  final EntityType type;
  final EntityMetadata? entity;

  const EntityMetadataDialog({
    super.key,
    required this.type,
    this.entity,
  });

  @override
  State<EntityMetadataDialog> createState() => _EntityMetadataDialogState();
}

class _EntityMetadataDialogState extends State<EntityMetadataDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _summaryController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.entity?.name ?? '');
    _summaryController = TextEditingController(text: widget.entity?.summary ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  String get _title {
    final action = widget.entity == null ? 'Add' : 'Edit';
    return '$action ${widget.type.displayName}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_title),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter name',
                ),
                validator: Validators.required,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _summaryController,
                decoration: const InputDecoration(
                  labelText: 'Summary',
                  hintText: 'Brief summary shown in tooltips',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              Text(
                'Click on the entity name in your text to edit the full description.',
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
        core.DialogActions(
          onConfirm: _submit,
          confirmLabel: widget.entity == null ? 'Add' : 'Save',
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final entity = widget.entity?.copyWith(
            name: _nameController.text.trim(),
            summary: _summaryController.text.trim(),
          ) ??
          EntityMetadata(
            name: _nameController.text.trim(),
            type: widget.type,
            summary: _summaryController.text.trim(),
            description: '', // Empty description - filled in entity detail screen
          );

      Navigator.of(context).pop(entity);
    }
  }
}
