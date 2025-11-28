import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/entity_metadata.dart';
import '../../models/entity_type.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/dialog_actions.dart' as core;
import '../../l10n/app_localizations.dart';

class EntityMetadataDialog extends ConsumerStatefulWidget {
  final EntityType type;
  final EntityMetadata? entity;

  const EntityMetadataDialog({
    super.key,
    required this.type,
    this.entity,
  });

  @override
  ConsumerState<EntityMetadataDialog> createState() => _EntityMetadataDialogState();
}

class _EntityMetadataDialogState extends ConsumerState<EntityMetadataDialog> {
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
    final action = widget.entity == null ? ref.tr('add_entity') : ref.tr('edit_entity');
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
                decoration: InputDecoration(
                  labelText: ref.tr('name'),
                  hintText: ref.tr('enter_name'),
                ),
                validator: Validators.required,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _summaryController,
                decoration: InputDecoration(
                  labelText: ref.tr('summary'),
                  hintText: ref.tr('brief_summary_hint'),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              Text(
                ref.tr('click_entity_hint'),
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
          confirmLabel: widget.entity == null ? ref.tr('add') : ref.tr('save'),
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
