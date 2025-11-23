import 'package:flutter/material.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/dialog_actions.dart' as core;

class NewChapterDialog extends StatefulWidget {
  const NewChapterDialog({super.key});

  @override
  State<NewChapterDialog> createState() => _NewChapterDialogState();
}

class _NewChapterDialogState extends State<NewChapterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Chapter'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _titleController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Chapter Title',
            hintText: 'Chapter 1: The Beginning',
          ),
          validator: Validators.required,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        core.DialogActions(
          onConfirm: _submit,
          confirmLabel: 'Create',
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_titleController.text.trim());
    }
  }
}
