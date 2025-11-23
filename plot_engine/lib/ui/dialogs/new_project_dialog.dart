import 'package:flutter/material.dart';
import '../../services/folder_picker_service.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/dialog_actions.dart' as core;

class NewProjectDialog extends StatefulWidget {
  const NewProjectDialog({super.key});

  @override
  State<NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<NewProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedPath;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectLocation() async {
    final selectedDirectory = await FolderPickerService.pickDirectory(
      dialogTitle: 'Select Project Location',
    );

    if (selectedDirectory != null) {
      setState(() {
        _selectedPath = selectedDirectory;
      });
    }
  }


  String _getDisplayPath() {
    if (_selectedPath == null) {
      return 'Default location (~/Documents/PlotEngine)';
    }
    return _selectedPath!;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Project'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Project Name',
                  hintText: 'My Novel',
                ),
                validator: Validators.required,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              Text(
                'Project Location',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.folder,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getDisplayPath(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _selectedPath == null
                                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _selectLocation,
                icon: const Icon(Icons.folder_open, size: 18),
                label: const Text('Choose Location'),
              ),
            ],
          ),
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
      Navigator.of(context).pop({
        'name': _nameController.text.trim(),
        'path': _selectedPath,
      });
    }
  }
}
