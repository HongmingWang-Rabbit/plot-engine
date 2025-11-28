import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/editor/editor_panel.dart';
import 'ui/sidebar_comments/sidebar_comments.dart';
import 'ui/knowledge_panel/knowledge_panel.dart';
import 'ui/toolbar/app_toolbar.dart';
import 'ui/footer/app_footer.dart';
import 'ui/auth/login_screen.dart';
import 'ui/auth/auth_success_screen.dart';
import 'ui/auth/auth_error_screen.dart';
import 'services/save_service.dart';
import 'state/settings_state.dart';
import 'state/app_state.dart';
import 'config/env_config.dart';
import 'utils/web_url_helper.dart' if (dart.library.io) 'utils/web_url_helper_stub.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.init();

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
    final authUser = ref.watch(authUserProvider);

    // For web, check current URL for OAuth callbacks
    Widget initialScreen;
    if (kIsWeb) {
      final currentUrl = getCurrentUrl();

      if (currentUrl?.path == '/auth/success') {
        final token = currentUrl?.queryParameters['token'];
        initialScreen = AuthSuccessScreen(token: token);
      } else if (currentUrl?.path == '/auth/error') {
        final error = currentUrl?.queryParameters['error'];
        final message = currentUrl?.queryParameters['message'];
        initialScreen = AuthErrorScreen(error: error, message: message);
      } else {
        initialScreen = authUser == null ? const LoginScreen() : const PlotEngineHome();
      }
    } else {
      initialScreen = authUser == null ? const LoginScreen() : const PlotEngineHome();
    }

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
      home: initialScreen,
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLastProject();
    });
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
    final isProjectLoading = ref.watch(projectLoadingProvider);

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
                  child: Stack(
                    children: [
                      // Main content
                      Row(
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
                      // Loading overlay
                      if (isProjectLoading)
                        Container(
                          color: Theme.of(context).colorScheme.surface,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 24),
                                Text(
                                  'Loading project...',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'This may take a moment',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
