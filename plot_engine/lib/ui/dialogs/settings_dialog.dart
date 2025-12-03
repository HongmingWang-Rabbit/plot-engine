import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/settings_state.dart';
import '../../config/app_themes.dart';
import '../../l10n/app_localizations.dart';

class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  @override
  Widget build(BuildContext context) {
    final appTheme = ref.watch(appThemeProvider);
    final currentLanguage = ref.watch(localeProvider);

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
                  ref.tr('settings_title'),
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
                    ref.tr('appearance'),
                    [
                      _buildSettingItem(
                        context,
                        ref.tr('language'),
                        '',
                        DropdownButton<AppLanguage>(
                          value: currentLanguage,
                          items: AppLanguage.values
                              .map((lang) => DropdownMenuItem(
                                    value: lang,
                                    child: Text(lang.displayName),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              ref.read(localeProvider.notifier).setLanguage(value);
                            }
                          },
                        ),
                      ),
                      _buildSettingItem(
                        context,
                        ref.tr('theme'),
                        '',
                        DropdownButton<AppTheme>(
                          value: appTheme,
                          items: AppTheme.values
                              .map((theme) => DropdownMenuItem(
                                    value: theme,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          AppThemes.getThemeIcon(theme),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(AppThemes.getThemeName(theme)),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              ref.read(appThemeProvider.notifier).setTheme(value);
                            }
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
                  child: Text(ref.tr('close')),
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
