import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/editor/editor_panel.dart';
import 'ui/sidebar_comments/sidebar_comments.dart';
import 'ui/knowledge_panel/knowledge_panel.dart';
import 'ui/toolbar/app_toolbar.dart';
import 'ui/footer/app_footer.dart';
import 'services/project_service.dart';
import 'services/save_service.dart';
import 'state/settings_state.dart';
import 'state/app_state.dart';

void main() {
  runApp(
    const ProviderScope(
      child: PlotEngineApp(),
    ),
  );
}

class PlotEngineApp extends ConsumerWidget {
  const PlotEngineApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'PlotEngine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFFFF6B00), // Bright orange
          selectionColor: Color(0x4DFF6B00), // Orange with 30% opacity
          selectionHandleColor: Color(0xFFFF6B00),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF00D4FF), // Bright cyan
          selectionColor: Color(0x4D00D4FF), // Cyan with 30% opacity
          selectionHandleColor: Color(0xFF00D4FF),
        ),
      ),
      themeMode: themeMode,
      home: const PlotEngineHome(),
    );
  }
}

class PlotEngineHome extends ConsumerStatefulWidget {
  const PlotEngineHome({super.key});

  @override
  ConsumerState<PlotEngineHome> createState() => _PlotEngineHomeState();
}

class _PlotEngineHomeState extends ConsumerState<PlotEngineHome> {
  @override
  void initState() {
    super.initState();
    // Auto-open last project on app start
    _loadLastProject();
  }

  Future<void> _loadLastProject() async {
    final projectService = ref.read(projectServiceProvider);
    final lastProjectPath = await projectService.getLastProjectPath();

    if (lastProjectPath != null) {
      final success = await projectService.openProject(lastProjectPath);
      if (!success && mounted) {
        // Project couldn't be opened (maybe deleted or moved)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open last project. It may have been moved or deleted.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyS):
            const SaveIntent(),
      },
      child: Actions(
        actions: {
          SaveIntent: CallbackAction<SaveIntent>(
            onInvoke: (intent) => _handleSave(context),
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: Column(
              children: [
                const AppToolbar(),
                Expanded(
                  child: Row(
                    children: [
                      // Main Editor Panel (60% width)
                      Expanded(
                        flex: 6,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                          ),
                          child: const EditorPanel(),
                        ),
                      ),
                      // AI Comments Sidebar (20% width)
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                          ),
                          child: const SidebarComments(),
                        ),
                      ),
                      // Knowledge Base Panel (20% width)
                      const Expanded(
                        flex: 2,
                        child: KnowledgePanel(),
                      ),
                    ],
                  ),
                ),
                const AppFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave(BuildContext context) async {
    final project = ref.read(projectProvider);
    if (project == null) return;

    // Use centralized save service
    await ref.read(saveServiceProvider).saveCurrentTab();
  }
}

// Intent for save action
class SaveIntent extends Intent {
  const SaveIntent();
}
