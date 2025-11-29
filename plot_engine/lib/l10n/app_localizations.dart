import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'translations/en.dart';
import 'translations/zh.dart';
import 'translations/zh_TW.dart';
import 'translations/fr.dart';
import 'translations/ja.dart';
import 'translations/ko.dart';
import 'translations/es.dart';
import 'translations/de.dart';
import 'translations/pt.dart';
import 'translations/ru.dart';
import 'translations/ar.dart';
import 'translations/it.dart';

const _languageKey = 'app_language';

enum AppLanguage {
  english('en', 'English'),
  chinese('zh', '中文'),
  chineseTraditional('zh-TW', '繁體中文'),
  french('fr', 'Français'),
  japanese('ja', '日本語'),
  korean('ko', '한국어'),
  spanish('es', 'Español'),
  german('de', 'Deutsch'),
  portuguese('pt', 'Português'),
  russian('ru', 'Русский'),
  arabic('ar', 'العربية'),
  italian('it', 'Italiano');

  final String code;
  final String displayName;

  const AppLanguage(this.code, this.displayName);

  /// Get the locale code to send to the AI API
  /// Maps our app language codes to the backend locale codes
  String get apiLocaleCode {
    switch (this) {
      case AppLanguage.english:
        return 'en';
      case AppLanguage.chinese:
        return 'cn';
      case AppLanguage.chineseTraditional:
        return 'tw';
      case AppLanguage.french:
        return 'fr';
      case AppLanguage.japanese:
        return 'ja';
      case AppLanguage.korean:
        return 'ko';
      case AppLanguage.spanish:
        return 'es';
      case AppLanguage.german:
        return 'de';
      case AppLanguage.portuguese:
        return 'pt';
      case AppLanguage.russian:
        return 'ru';
      case AppLanguage.arabic:
        return 'ar';
      case AppLanguage.italian:
        return 'it';
    }
  }

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}

class LocaleNotifier extends StateNotifier<AppLanguage> {
  LocaleNotifier() : super(_detectSystemLanguage()) {
    _loadSavedLanguage();
  }

  /// Detect the system language and map it to AppLanguage
  static AppLanguage _detectSystemLanguage() {
    final locale = ui.PlatformDispatcher.instance.locale;
    final languageCode = locale.languageCode;
    final countryCode = locale.countryCode;

    // Handle Chinese variants
    if (languageCode == 'zh') {
      // Traditional Chinese regions: Taiwan, Hong Kong, Macau
      if (countryCode == 'TW' || countryCode == 'HK' || countryCode == 'MO') {
        return AppLanguage.chineseTraditional;
      }
      // Default to Simplified Chinese
      return AppLanguage.chinese;
    }

    // Map language codes to AppLanguage
    switch (languageCode) {
      case 'en':
        return AppLanguage.english;
      case 'fr':
        return AppLanguage.french;
      case 'ja':
        return AppLanguage.japanese;
      case 'ko':
        return AppLanguage.korean;
      case 'es':
        return AppLanguage.spanish;
      case 'de':
        return AppLanguage.german;
      case 'pt':
        return AppLanguage.portuguese;
      case 'ru':
        return AppLanguage.russian;
      case 'ar':
        return AppLanguage.arabic;
      case 'it':
        return AppLanguage.italian;
      default:
        return AppLanguage.english;
    }
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_languageKey);
    if (savedCode != null) {
      // User has previously selected a language, use that
      state = AppLanguage.fromCode(savedCode);
    }
    // If no saved preference, keep the auto-detected system language
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
    'zh-TW': zhTW,
    'fr': fr,
    'ja': ja,
    'ko': ko,
    'es': es,
    'de': de,
    'pt': pt,
    'ru': ru,
    'ar': ar,
    'it': it,
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
