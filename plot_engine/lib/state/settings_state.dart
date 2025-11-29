import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Theme mode state
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString('theme_mode') ?? 'system';
    state = _themeModeFromString(themeModeString);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', _themeModeToString(mode));
  }

  ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
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
