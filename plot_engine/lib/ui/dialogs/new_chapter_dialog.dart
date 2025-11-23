import 'package:flutter/material.dart';

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
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a chapter title';
            }
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Create'),
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
