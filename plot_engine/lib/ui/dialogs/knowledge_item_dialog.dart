import 'package:flutter/material.dart';
import '../../models/knowledge_item.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/dialog_actions.dart' as core;

class KnowledgeItemDialog extends StatefulWidget {
  final String type;
  final KnowledgeItem? item;

  const KnowledgeItemDialog({
    super.key,
    required this.type,
    this.item,
  });

  @override
  State<KnowledgeItemDialog> createState() => _KnowledgeItemDialogState();
}

class _KnowledgeItemDialogState extends State<KnowledgeItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _descriptionController = TextEditingController(text: widget.item?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String get _title {
    final action = widget.item == null ? 'Add' : 'Edit';
    final typeLabel = widget.type[0].toUpperCase() + widget.type.substring(1);
    return '$action $typeLabel';
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
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter description',
                ),
                maxLines: 3,
                validator: Validators.required,
              ),
            ],
          ),
        ),
      ),
      actions: [
        core.DialogActions(
          onConfirm: _submit,
          confirmLabel: widget.item == null ? 'Add' : 'Save',
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final item = widget.item?.copyWith(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
          ) ??
          KnowledgeItem(
            id: '${now.millisecondsSinceEpoch}',
            name: _nameController.text.trim(),
            type: widget.type,
            description: _descriptionController.text.trim(),
          );

      Navigator.of(context).pop(item);
    }
  }
}
