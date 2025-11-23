import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/settings_state.dart';

class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.settings,
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Settings Content
            Expanded(
              child: ListView(
                children: [
                  _buildSettingsSection(
                    context,
                    'Editor',
                    [
                      _buildSettingItem(
                        context,
                        'Auto-save interval',
                        'Automatically save changes every 5 seconds',
                        Switch(
                          value: true,
                          onChanged: (value) {
                            // TODO: Implement auto-save toggle
                          },
                        ),
                      ),
                      _buildSettingItem(
                        context,
                        'Font size',
                        'Default font size for editor',
                        DropdownButton<int>(
                          value: 16,
                          items: [12, 14, 16, 18, 20, 24]
                              .map((size) => DropdownMenuItem(
                                    value: size,
                                    child: Text('$size pt'),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            // TODO: Implement font size change
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSettingsSection(
                    context,
                    'Appearance',
                    [
                      _buildSettingItem(
                        context,
                        'Theme',
                        'Choose light, dark, or system theme',
                        DropdownButton<ThemeMode>(
                          value: themeMode,
                          items: const [
                            DropdownMenuItem(
                              value: ThemeMode.light,
                              child: Text('Light'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.dark,
                              child: Text('Dark'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.system,
                              child: Text('System'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              ref.read(themeModeProvider.notifier).setThemeMode(value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSettingsSection(
                    context,
                    'Projects',
                    [
                      _buildSettingItem(
                        context,
                        'Auto-open last project',
                        'Automatically open the last project on startup',
                        Switch(
                          value: true,
                          onChanged: (value) {
                            // TODO: Implement auto-open toggle
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Footer
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    String title,
    List<Widget> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    String title,
    String description,
    Widget control,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          control,
        ],
      ),
    );
  }
}
