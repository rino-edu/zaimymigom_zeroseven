import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Сервис для работы с настройками приложения
class SettingsService extends ChangeNotifier {
  static const String _themeKey = 'app_theme';
  static const String _languageKey = 'app_language';
  // Удалены ключи, связанные с уведомлениями и тихими часами
  static const String _onboardingCompletedKey = 'onboarding_completed';

  ThemeMode _themeMode = ThemeMode.system;
  String? _languageCode;
  // Убраны поля уведомлений и тихих часов
  bool _onboardingCompleted = false;

  /// Singleton pattern
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  /// Текущий режим темы
  ThemeMode get themeMode => _themeMode;

  /// Текущий язык (null = системный)
  String? get languageCode => _languageCode;

  // Геттеры уведомлений и тихих часов удалены

  /// Онбординг завершен
  bool get onboardingCompleted => _onboardingCompleted;

  /// Загрузка настроек при старте приложения
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Загрузка темы
    final themeString = prefs.getString(_themeKey);
    if (themeString != null) {
      _themeMode = _themeModeFromString(themeString);
    }

    // Загрузка языка
    _languageCode = prefs.getString(_languageKey);

    // Удалена загрузка уведомлений и тихих часов

    // Загрузка статуса онбординга
    _onboardingCompleted = prefs.getBool(_onboardingCompletedKey) ?? false;

    notifyListeners();
  }

  /// Изменить тему
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _themeModeToString(mode));
  }

  /// Изменить язык
  Future<void> setLanguage(String? languageCode) async {
    _languageCode = languageCode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (languageCode != null) {
      await prefs.setString(_languageKey, languageCode);
    } else {
      await prefs.remove(_languageKey);
    }
  }

  // Методы уведомлений и тихих часов удалены

  /// Отметить онбординг как завершенный
  Future<void> completeOnboarding() async {
    _onboardingCompleted = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
  }

  /// Сброс настроек к значениям по умолчанию
  Future<void> resetSettings() async {
    _themeMode = ThemeMode.system;
    _languageCode = null;
    // Удалены поля уведомлений и тихих часов
    // Не сбрасываем _onboardingCompleted чтобы онбординг не показывался снова
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeKey);
    await prefs.remove(_languageKey);
    // Удалены ключи уведомлений и тихих часов
    // Не удаляем _onboardingCompletedKey
  }

  /// Преобразование ThemeMode в строку
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

  /// Преобразование строки в ThemeMode
  ThemeMode _themeModeFromString(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}
