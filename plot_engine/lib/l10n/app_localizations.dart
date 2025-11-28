import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'translations/en.dart';
import 'translations/zh.dart';
import 'translations/fr.dart';

const _languageKey = 'app_language';

enum AppLanguage {
  english('en', 'English'),
  chinese('zh', '中文'),
  french('fr', 'Français');

  final String code;
  final String displayName;

  const AppLanguage(this.code, this.displayName);

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}

class LocaleNotifier extends StateNotifier<AppLanguage> {
  LocaleNotifier() : super(AppLanguage.english) {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_languageKey);
    if (savedCode != null) {
      state = AppLanguage.fromCode(savedCode);
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language.code);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, AppLanguage>((ref) {
  return LocaleNotifier();
});

// Translation keys
class L10n {
  static final Map<String, Map<String, String>> _translations = {
    'en': en,
    'zh': zh,
    'fr': fr,
  };

  static String get(AppLanguage lang, String key) {
    return _translations[lang.code]?[key] ?? _translations['en']![key] ?? key;
  }
}

// Extension for easy access in widgets
extension LocalizationExtension on WidgetRef {
  String tr(String key) {
    final lang = watch(localeProvider);
    return L10n.get(lang, key);
  }
}
