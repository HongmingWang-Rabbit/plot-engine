import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/editor/editor_panel.dart';
import 'ui/sidebar_comments/sidebar_comments.dart';
import 'ui/knowledge_panel/knowledge_panel.dart';
import 'ui/toolbar/app_toolbar.dart';

void main() {
  runApp(
    const ProviderScope(
      child: PlotEngineApp(),
    ),
  );
}

class PlotEngineApp extends StatelessWidget {
  const PlotEngineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlotEngine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const PlotEngineHome(),
    );
  }
}

class PlotEngineHome extends StatelessWidget {
  const PlotEngineHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        ],
      ),
    );
  }
}
