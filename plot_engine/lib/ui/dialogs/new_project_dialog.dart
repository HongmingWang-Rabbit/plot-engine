import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/folder_picker_service.dart';
import '../../core/constants/ui_constants.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/dialog_actions.dart' as core;
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../state/settings_state.dart';

class NewProjectDialog extends ConsumerStatefulWidget {
  const NewProjectDialog({super.key});

  @override
  ConsumerState<NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends ConsumerState<NewProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedPath;
  StorageMode _storageMode = StorageMode.local;

  @override
  void initState() {
    super.initState();
    // Use default save location as initial path on desktop
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!kIsWeb) {
        final defaultPath = ref.read(defaultSaveLocationProvider);
        if (defaultPath != null && _selectedPath == null) {
          setState(() {
            _selectedPath = defaultPath;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectLocation() async {
    final selectedDirectory = await FolderPickerService.pickDirectory(
      dialogTitle: ref.tr('select_project_folder'),
    );

    if (selectedDirectory != null) {
      setState(() {
        _selectedPath = selectedDirectory;
      });
    }
  }

  bool get _isLoggedIn => ref.watch(authUserProvider) != null;
  bool get _showStorageOptions => !kIsWeb && _isLoggedIn;

  String _getDisplayPath() {
    if (_selectedPath == null) {
      return ref.tr('default_location');
    }
    return _selectedPath!;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(ref.tr('create_new_project')),
      content: SizedBox(
        width: UIConstants.dialogWidth,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: ref.tr('project_name'),
                  hintText: ref.tr('my_novel'),
                ),
                validator: Validators.required,
                onFieldSubmitted: (_) => _submit(),
              ),
              // Storage type selection (desktop only, when logged in)
              if (_showStorageOptions) ...[
                const SizedBox(height: 24),
                Text(
                  ref.tr('storage_type'),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                SegmentedButton<StorageMode>(
                  segments: [
                    ButtonSegment(
                      value: StorageMode.local,
                      label: Text(ref.tr('local_storage')),
                      icon: const Icon(Icons.folder, size: 18),
                    ),
                    ButtonSegment(
                      value: StorageMode.cloud,
                      label: Text(ref.tr('cloud_storage')),
                      icon: const Icon(Icons.cloud, size: 18),
                    ),
                  ],
                  selected: {_storageMode},
                  onSelectionChanged: (selected) {
                    setState(() {
                      _storageMode = selected.first;
                    });
                  },
                ),
              ],
              // Local storage path selection (only for local storage)
              if (!kIsWeb && _storageMode == StorageMode.local) ...[
                const SizedBox(height: 24),
                Text(
                  ref.tr('project_location'),
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
                  label: Text(ref.tr('choose_location')),
                ),
              ],
              // Cloud storage info
              if (_storageMode == StorageMode.cloud) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_done,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ref.tr('cloud_storage_info'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
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
      Navigator.of(context).pop({
        'name': _nameController.text.trim(),
        'path': _selectedPath,
        'storageMode': _storageMode,
      });
    }
  }
}
