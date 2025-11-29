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
import 'state/settings_state.dart'; // includes panel visibility & AI analysis toggle providers
import 'state/app_state.dart';
import 'config/env_config.dart';
import 'utils/web_url_helper.dart' if (dart.library.io) 'utils/web_url_helper_stub.dart';
import 'utils/responsive.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Add error handling for debugging
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
    debugPrint('Stack: ${details.stack}');
  };

  try {
    await EnvConfig.init();
    debugPrint('EnvConfig initialized');
  } catch (e) {
    debugPrint('EnvConfig.init() error: $e');
  }

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
    debugPrint('PlotEngineApp.build() called');

    final themeMode = ref.watch(themeModeProvider);
    final authUser = ref.watch(authUserProvider);
    debugPrint('authUser: $authUser');

    // For web, check current URL for OAuth callbacks
    Widget initialScreen;
    if (kIsWeb) {
      final currentUrl = getCurrentUrl();
      debugPrint('currentUrl: $currentUrl');

      // Check for token in query params (backend may redirect to /?token=... or /auth/success?token=...)
      final token = currentUrl?.queryParameters['token'];

      if (currentUrl?.path == '/auth/success' || (token != null && token.isNotEmpty)) {
        debugPrint('Found token, showing AuthSuccessScreen');
        initialScreen = AuthSuccessScreen(token: token);
      } else if (currentUrl?.path == '/auth/error') {
        final error = currentUrl?.queryParameters['error'];
        final message = currentUrl?.queryParameters['message'];
        initialScreen = AuthErrorScreen(error: error, message: message);
      } else {
        initialScreen = authUser == null ? const LoginScreen() : const PlotEngineHome();
        debugPrint('initialScreen: ${authUser == null ? "LoginScreen" : "PlotEngineHome"}');
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
    final viewport = Responsive.getViewportSize(context);

    // Update viewport provider for other widgets to use
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(viewportProvider.notifier).update(viewport);
    });

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
                      // Responsive main content
                      _buildResponsiveContent(context, viewport),
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
                // Show footer on tablet and desktop, bottom nav on mobile
                if (viewport.isMobile)
                  _buildMobileBottomNav(context)
                else
                  const AppFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveContent(BuildContext context, ViewportSize viewport) {
    if (viewport.isMobile) {
      return _buildMobileLayout(context);
    } else if (viewport.isTablet) {
      return _buildTabletLayout(context);
    } else {
      return _buildDesktopLayout(context);
    }
  }

  /// Mobile layout: Single panel with bottom navigation
  Widget _buildMobileLayout(BuildContext context) {
    final activePanel = ref.watch(mobilePanelProvider);

    return switch (activePanel) {
      MobilePanel.editor => const EditorPanel(),
      MobilePanel.aiSidebar => const SidebarComments(),
      MobilePanel.knowledge => const KnowledgePanel(),
    };
  }

  /// Tablet layout: Editor + one sidebar (toggle between AI and Knowledge)
  Widget _buildTabletLayout(BuildContext context) {
    final aiVisible = ref.watch(aiSidebarVisibleProvider);
    final knowledgeVisible = ref.watch(knowledgePanelVisibleProvider);

    return Row(
      children: [
        // Editor panel always visible
        Expanded(
          flex: 7,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: const EditorPanel(),
          ),
        ),
        // Show one sidebar at a time on tablet
        if (aiVisible)
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: const SidebarComments(),
            ),
          )
        else if (knowledgeVisible)
          const Expanded(
            flex: 3,
            child: KnowledgePanel(),
          )
        else
          // Collapsed buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CollapsedPanelButton(
                icon: Icons.auto_awesome,
                tooltip: 'AI Assistant',
                onPressed: () {
                  ref.read(aiSidebarVisibleProvider.notifier).setVisibility(true);
                  ref.read(knowledgePanelVisibleProvider.notifier).setVisibility(false);
                },
              ),
              _CollapsedPanelButton(
                icon: Icons.library_books,
                tooltip: 'Knowledge Base',
                onPressed: () {
                  ref.read(knowledgePanelVisibleProvider.notifier).setVisibility(true);
                  ref.read(aiSidebarVisibleProvider.notifier).setVisibility(false);
                },
              ),
            ],
          ),
      ],
    );
  }

  /// Desktop layout: Full 3-panel layout
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Main Editor Panel
        Expanded(
          flex: 6,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: const EditorPanel(),
          ),
        ),
        // AI Comments Sidebar
        if (ref.watch(aiSidebarVisibleProvider))
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: const SidebarComments(),
            ),
          )
        else
          _CollapsedPanelButton(
            icon: Icons.auto_awesome,
            tooltip: 'AI Assistant',
            onPressed: () => ref.read(aiSidebarVisibleProvider.notifier).toggle(),
          ),
        // Knowledge Base Panel
        if (ref.watch(knowledgePanelVisibleProvider))
          const Expanded(
            flex: 2,
            child: KnowledgePanel(),
          )
        else
          _CollapsedPanelButton(
            icon: Icons.library_books,
            tooltip: 'Knowledge Base',
            onPressed: () => ref.read(knowledgePanelVisibleProvider.notifier).toggle(),
          ),
      ],
    );
  }

  /// Mobile bottom navigation bar
  Widget _buildMobileBottomNav(BuildContext context) {
    final activePanel = ref.watch(mobilePanelProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _MobileNavItem(
                icon: Icons.edit_document,
                label: 'Editor',
                isActive: activePanel == MobilePanel.editor,
                onTap: () => ref.read(mobilePanelProvider.notifier).setPanel(MobilePanel.editor),
              ),
              _MobileNavItem(
                icon: Icons.auto_awesome,
                label: 'AI',
                isActive: activePanel == MobilePanel.aiSidebar,
                onTap: () => ref.read(mobilePanelProvider.notifier).setPanel(MobilePanel.aiSidebar),
              ),
              _MobileNavItem(
                icon: Icons.library_books,
                label: 'Knowledge',
                isActive: activePanel == MobilePanel.knowledge,
                onTap: () => ref.read(mobilePanelProvider.notifier).setPanel(MobilePanel.knowledge),
              ),
            ],
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

/// Collapsed panel expand button
class _CollapsedPanelButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _CollapsedPanelButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Tooltip(
            message: tooltip,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.chevron_left,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          RotatedBox(
            quarterTurns: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    tooltip,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mobile bottom navigation item
class _MobileNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _MobileNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = colorScheme.primary;
    final inactiveColor = colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isActive ? activeColor : inactiveColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
