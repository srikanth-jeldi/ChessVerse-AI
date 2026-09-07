import 'dart:ui';

import 'app_preferences.dart';

class AppLanguage {
  const AppLanguage(this.code, this.nativeName, this.englishName);

  final String code;
  final String nativeName;
  final String englishName;

  String get displayName => '$nativeName · $englishName';
}

class AppLanguageController {
  AppLanguageController._();

  static const String systemCode = 'system';
  static const AppPreferences _preferences = AppPreferences();

  /// Languages offered by the language centre. AI coaching accepts any locale
  /// from this catalogue and the app safely falls back to English for static
  /// copy that has not yet been translated.
  static const List<AppLanguage> supported = <AppLanguage>[
    AppLanguage(systemCode, 'Device language', 'Automatic'),
    AppLanguage('en', 'English', 'English'),
    AppLanguage('te', 'తెలుగు', 'Telugu'),
    AppLanguage('hi', 'हिन्दी', 'Hindi'),
    AppLanguage('ta', 'தமிழ்', 'Tamil'),
    AppLanguage('kn', 'ಕನ್ನಡ', 'Kannada'),
    AppLanguage('ml', 'മലയാളം', 'Malayalam'),
    AppLanguage('mr', 'मराठी', 'Marathi'),
    AppLanguage('bn', 'বাংলা', 'Bengali'),
    AppLanguage('gu', 'ગુজરાતી', 'Gujarati'),
    AppLanguage('pa', 'ਪੰਜਾਬੀ', 'Punjabi'),
    AppLanguage('ur', 'اردو', 'Urdu'),
    AppLanguage('ar', 'العربية', 'Arabic'),
    AppLanguage('es', 'Español', 'Spanish'),
    AppLanguage('fr', 'Français', 'French'),
    AppLanguage('de', 'Deutsch', 'German'),
    AppLanguage('it', 'Italiano', 'Italian'),
    AppLanguage('pt', 'Português', 'Portuguese'),
    AppLanguage('ru', 'Русский', 'Russian'),
    AppLanguage('uk', 'Українська', 'Ukrainian'),
    AppLanguage('tr', 'Türkçe', 'Turkish'),
    AppLanguage('fa', 'فارسی', 'Persian'),
    AppLanguage('zh', '中文', 'Chinese'),
    AppLanguage('ja', '日本語', 'Japanese'),
    AppLanguage('ko', '한국어', 'Korean'),
    AppLanguage('id', 'Bahasa Indonesia', 'Indonesian'),
    AppLanguage('ms', 'Bahasa Melayu', 'Malay'),
    AppLanguage('th', 'ไทย', 'Thai'),
    AppLanguage('vi', 'Tiếng Việt', 'Vietnamese'),
    AppLanguage('pl', 'Polski', 'Polish'),
    AppLanguage('nl', 'Nederlands', 'Dutch'),
    AppLanguage('sv', 'Svenska', 'Swedish'),
    AppLanguage('el', 'Ελληνικά', 'Greek'),
    AppLanguage('he', 'עברית', 'Hebrew'),
    AppLanguage('sw', 'Kiswahili', 'Swahili'),
  ];

  static Future<String> selectedCode() =>
      _preferences.readString('language', fallback: systemCode);

  static Future<void> select(String code) =>
      _preferences.writeString('language', code);

  static Future<String> effectiveCode() async {
    final String selected = await selectedCode();
    if (selected != systemCode) return selected;
    final String device = PlatformDispatcher.instance.locale.languageCode;
    return supported.any((AppLanguage item) => item.code == device)
        ? device
        : 'en';
  }

  static AppLanguage byCode(String code) => supported.firstWhere(
        (AppLanguage item) => item.code == code,
        orElse: () => supported[1],
      );
}
