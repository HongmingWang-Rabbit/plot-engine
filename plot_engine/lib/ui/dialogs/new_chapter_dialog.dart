import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/dialog_actions.dart' as core;
import '../../l10n/app_localizations.dart';

class NewChapterDialog extends ConsumerStatefulWidget {
  const NewChapterDialog({super.key});

  @override
  ConsumerState<NewChapterDialog> createState() => _NewChapterDialogState();
}

class _NewChapterDialogState extends ConsumerState<NewChapterDialog> {
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
      title: Text(ref.tr('new_chapter')),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _titleController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: ref.tr('chapter_title'),
            hintText: ref.tr('chapter_hint'),
          ),
          validator: Validators.required,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        core.DialogActions(
          onConfirm: _submit,
          confirmLabel: ref.tr('create'),
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
