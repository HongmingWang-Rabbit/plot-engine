import 'dart:io' show Directory, Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../utils/responsive.dart';
import '../config/app_themes.dart';
import '../core/utils/logger.dart';

/// Preference keys - centralized to avoid magic strings
class _PrefKeys {
  static const String appTheme = 'app_theme';
  static const String themeMode = 'theme_mode';
  static const String knowledgePanelVisible = 'knowledge_panel_visible';
  static const String aiSidebarVisible = 'ai_sidebar_visible';
  static const String aiBackgroundAnalysis = 'ai_background_analysis';
  static const String defaultSaveLocation = 'default_save_location';
}

/// Default folder name for projects
const String _defaultProjectsFolder = 'PlotEngine';

// Theme state - now supports custom themes including Halloween
class AppThemeNotifier extends StateNotifier<AppTheme> {
  AppThemeNotifier() : super(AppTheme.light) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check for new theme setting first
      final themeString = prefs.getString(_PrefKeys.appTheme);

      if (themeString != null) {
        state = _themeFromString(themeString);
      } else {
        // Migrate from old theme_mode setting
        final oldThemeMode = prefs.getString(_PrefKeys.themeMode);
        if (oldThemeMode == 'dark') {
          state = AppTheme.dark;
          await prefs.setString(_PrefKeys.appTheme, 'dark');
        } else if (oldThemeMode == 'light') {
          state = AppTheme.light;
          await prefs.setString(_PrefKeys.appTheme, 'light');
        }
        // If oldThemeMode is 'system' or null, keep default light theme
      }
    } catch (e) {
      // If anything fails, default to light theme
      state = AppTheme.light;
      AppLogger.error('Error loading theme', e);
    }
  }

  Future<void> setTheme(AppTheme theme) async {
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_PrefKeys.appTheme, _themeToString(theme));
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
  return PanelVisibilityNotifier(_PrefKeys.knowledgePanelVisible);
});

// AI sidebar visibility
final aiSidebarVisibleProvider = StateNotifierProvider<PanelVisibilityNotifier, bool>((ref) {
  return PanelVisibilityNotifier(_PrefKeys.aiSidebarVisible);
});

// Background AI analysis toggle
class AIAnalysisToggleNotifier extends StateNotifier<bool> {
  AIAnalysisToggleNotifier() : super(true) {
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_PrefKeys.aiBackgroundAnalysis);
    if (enabled != null) {
      state = enabled;
    }
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_PrefKeys.aiBackgroundAnalysis, state);
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_PrefKeys.aiBackgroundAnalysis, state);
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

// Default save location for desktop projects
class DefaultSaveLocationNotifier extends StateNotifier<String?> {
  DefaultSaveLocationNotifier() : super(null) {
    _loadSetting();
  }

  /// Get the platform-appropriate default save path
  /// On Windows, uses user's home folder to avoid OneDrive issues with Documents
  /// On macOS/Linux, uses the Documents folder
  Future<String> _getPlatformDefaultPath() async {
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        return p.join(userProfile, _defaultProjectsFolder);
      }
    }
    // Fallback: use Documents folder (safe on macOS/Linux, may have issues on Windows)
    final documentsDir = await getApplicationDocumentsDirectory();
    return documentsDir.path;
  }

  Future<void> _loadSetting() async {
    if (kIsWeb) return; // Not applicable for web

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPath = prefs.getString(_PrefKeys.defaultSaveLocation);

      if (savedPath != null && savedPath.isNotEmpty) {
        // Verify the saved path still exists
        final savedDir = Directory(savedPath);
        if (await savedDir.exists()) {
          state = savedPath;
          return;
        }
      }

      // Get platform-appropriate default path
      var defaultPath = await _getPlatformDefaultPath();

      // Create the default directory if it doesn't exist
      final defaultDir = Directory(defaultPath);
      if (!await defaultDir.exists()) {
        try {
          await defaultDir.create(recursive: true);
        } catch (e) {
          AppLogger.warn('Could not create default save location', {'path': defaultPath, 'error': e});
          // Fall back to documents directory
          final documentsDir = await getApplicationDocumentsDirectory();
          defaultPath = documentsDir.path;
        }
      }

      state = defaultPath;
    } catch (e) {
      AppLogger.error('Error loading default save location', e);
    }
  }

  Future<void> setLocation(String path) async {
    state = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_PrefKeys.defaultSaveLocation, path);
  }

  Future<void> resetToDefault() async {
    try {
      var defaultPath = await _getPlatformDefaultPath();

      // Create the default directory if it doesn't exist
      final defaultDir = Directory(defaultPath);
      if (!await defaultDir.exists()) {
        await defaultDir.create(recursive: true);
      }

      await setLocation(defaultPath);
    } catch (e) {
      AppLogger.error('Error resetting to default location', e);
    }
  }
}

final defaultSaveLocationProvider = StateNotifierProvider<DefaultSaveLocationNotifier, String?>((ref) {
  return DefaultSaveLocationNotifier();
});

// Storage mode enum for per-project storage selection (local vs cloud)
// Note: This is used for per-project selection, not a global setting
enum StorageMode { local, cloud }
