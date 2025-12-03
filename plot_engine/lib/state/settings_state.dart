import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/responsive.dart';
import '../config/app_themes.dart';

// Theme state - now supports custom themes including Halloween
class AppThemeNotifier extends StateNotifier<AppTheme> {
  AppThemeNotifier() : super(AppTheme.light) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check for new theme setting first
      final themeString = prefs.getString('app_theme');
      
      if (themeString != null) {
        state = _themeFromString(themeString);
      } else {
        // Migrate from old theme_mode setting
        final oldThemeMode = prefs.getString('theme_mode');
        if (oldThemeMode == 'dark') {
          state = AppTheme.dark;
          await prefs.setString('app_theme', 'dark');
        } else if (oldThemeMode == 'light') {
          state = AppTheme.light;
          await prefs.setString('app_theme', 'light');
        }
        // If oldThemeMode is 'system' or null, keep default light theme
      }
    } catch (e) {
      // If anything fails, default to light theme
      state = AppTheme.light;
      debugPrint('Error loading theme: $e');
    }
  }

  Future<void> setTheme(AppTheme theme) async {
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', _themeToString(theme));
  }

  AppTheme _themeFromString(String value) {
    switch (value) {
      case 'light':
        return AppTheme.light;
      case 'dark':
        return AppTheme.dark;
      case 'halloween':
        return AppTheme.halloween;
      default:
        return AppTheme.light;
    }
  }

  String _themeToString(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return 'light';
      case AppTheme.dark:
        return 'dark';
      case AppTheme.halloween:
        return 'halloween';
    }
  }
}

final appThemeProvider = StateNotifierProvider<AppThemeNotifier, AppTheme>((ref) {
  return AppThemeNotifier();
});

// Legacy theme mode provider for backward compatibility
final themeModeProvider = Provider<ThemeMode>((ref) {
  final appTheme = ref.watch(appThemeProvider);
  // Halloween theme uses dark mode base
  return appTheme == AppTheme.light ? ThemeMode.light : ThemeMode.dark;
});

// Panel visibility states
class PanelVisibilityNotifier extends StateNotifier<bool> {
  final String _prefKey;

  PanelVisibilityNotifier(this._prefKey, {bool defaultValue = true}) : super(defaultValue) {
    _loadVisibility();
  }

  Future<void> _loadVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    final isVisible = prefs.getBool(_prefKey);
    if (isVisible != null) {
      state = isVisible;
    }
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, state);
  }

  Future<void> setVisibility(bool visible) async {
    state = visible;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, state);
  }
}

// Knowledge panel visibility
final knowledgePanelVisibleProvider = StateNotifierProvider<PanelVisibilityNotifier, bool>((ref) {
  return PanelVisibilityNotifier('knowledge_panel_visible');
});

// AI sidebar visibility
final aiSidebarVisibleProvider = StateNotifierProvider<PanelVisibilityNotifier, bool>((ref) {
  return PanelVisibilityNotifier('ai_sidebar_visible');
});

// Background AI analysis toggle
class AIAnalysisToggleNotifier extends StateNotifier<bool> {
  AIAnalysisToggleNotifier() : super(true) {
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('ai_background_analysis');
    if (enabled != null) {
      state = enabled;
    }
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ai_background_analysis', state);
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ai_background_analysis', state);
  }
}

final aiBackgroundAnalysisProvider = StateNotifierProvider<AIAnalysisToggleNotifier, bool>((ref) {
  return AIAnalysisToggleNotifier();
});

// Current viewport size provider - updated via ResponsiveWrapper
class ViewportNotifier extends StateNotifier<ViewportSize> {
  ViewportNotifier() : super(ViewportSize.desktop);

  void update(ViewportSize size) {
    if (state != size) {
      state = size;
    }
  }
}

final viewportProvider = StateNotifierProvider<ViewportNotifier, ViewportSize>((ref) {
  return ViewportNotifier();
});

// Active mobile panel for mobile navigation
enum MobilePanel { editor, aiSidebar, knowledge }

class MobilePanelNotifier extends StateNotifier<MobilePanel> {
  MobilePanelNotifier() : super(MobilePanel.editor);

  void setPanel(MobilePanel panel) {
    state = panel;
  }
}

final mobilePanelProvider = StateNotifierProvider<MobilePanelNotifier, MobilePanel>((ref) {
  return MobilePanelNotifier();
});
