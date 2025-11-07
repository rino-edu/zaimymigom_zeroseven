import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Модель личных данных пользователя
class UserProfile {
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? dateOfBirth;

  UserProfile({
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.dateOfBirth,
  });

  bool get isEmpty =>
      (firstName?.isEmpty ?? true) &&
      (lastName?.isEmpty ?? true) &&
      (email?.isEmpty ?? true) &&
      (phone?.isEmpty ?? true) &&
      (dateOfBirth?.isEmpty ?? true);

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? dateOfBirth,
  }) {
    return UserProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    );
  }
}

/// Сервис для работы с настройками приложения
class SettingsService extends ChangeNotifier {
  static const String _themeKey = 'app_theme';
  static const String _languageKey = 'app_language';
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _pinCodeKey = 'pin_code';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _securityEnabledKey = 'security_enabled';
  static const String _firstNameKey = 'first_name';
  static const String _lastNameKey = 'last_name';
  static const String _emailKey = 'email';
  static const String _phoneKey = 'phone';
  static const String _dateOfBirthKey = 'date_of_birth';

  ThemeMode _themeMode = ThemeMode.system;
  String? _languageCode;
  bool _onboardingCompleted = false;
  String? _pinCode;
  bool _biometricEnabled = false;
  bool _securityEnabled = false;
  UserProfile _userProfile = UserProfile();

  /// Singleton pattern
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  /// Текущий режим темы
  ThemeMode get themeMode => _themeMode;

  /// Текущий язык (null = системный)
  String? get languageCode => _languageCode;

  /// Онбординг завершен
  bool get onboardingCompleted => _onboardingCompleted;

  /// PIN-код установлен
  bool get hasPinCode => _pinCode != null && _pinCode!.isNotEmpty;

  /// Биометрия включена
  bool get biometricEnabled => _biometricEnabled;

  /// Безопасность включена
  bool get securityEnabled => _securityEnabled;

  /// Личные данные пользователя
  UserProfile get userProfile => _userProfile;

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

    // Загрузка настроек безопасности
    _pinCode = prefs.getString(_pinCodeKey);
    _biometricEnabled = prefs.getBool(_biometricEnabledKey) ?? false;
    _securityEnabled = prefs.getBool(_securityEnabledKey) ?? false;

    // Загрузка личных данных
    _userProfile = UserProfile(
      firstName: prefs.getString(_firstNameKey),
      lastName: prefs.getString(_lastNameKey),
      email: prefs.getString(_emailKey),
      phone: prefs.getString(_phoneKey),
      dateOfBirth: prefs.getString(_dateOfBirthKey),
    );

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

  /// Установить PIN-код
  Future<void> setPinCode(String? pinCode) async {
    _pinCode = pinCode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (pinCode != null && pinCode.isNotEmpty) {
      await prefs.setString(_pinCodeKey, pinCode);
      _securityEnabled = true;
      await prefs.setBool(_securityEnabledKey, true);
    } else {
      await prefs.remove(_pinCodeKey);
      _securityEnabled = false;
      _biometricEnabled = false;
      await prefs.setBool(_securityEnabledKey, false);
      await prefs.setBool(_biometricEnabledKey, false);
    }
    notifyListeners();
  }

  /// Проверить PIN-код
  bool verifyPinCode(String pinCode) {
    return _pinCode == pinCode;
  }

  /// Включить/выключить биометрию
  Future<void> setBiometricEnabled(bool enabled) async {
    _biometricEnabled = enabled;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
    if (enabled && !_securityEnabled) {
      _securityEnabled = true;
      await prefs.setBool(_securityEnabledKey, true);
    }
    notifyListeners();
  }

  /// Включить/выключить безопасность
  Future<void> setSecurityEnabled(bool enabled) async {
    _securityEnabled = enabled;
    if (!enabled) {
      _biometricEnabled = false;
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_securityEnabledKey, enabled);
    if (!enabled) {
      await prefs.setBool(_biometricEnabledKey, false);
    }
    notifyListeners();
  }

  /// Сохранить личные данные
  Future<void> saveUserProfile(UserProfile profile) async {
    _userProfile = profile;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (profile.firstName != null) {
      await prefs.setString(_firstNameKey, profile.firstName!);
    } else {
      await prefs.remove(_firstNameKey);
    }
    if (profile.lastName != null) {
      await prefs.setString(_lastNameKey, profile.lastName!);
    } else {
      await prefs.remove(_lastNameKey);
    }
    if (profile.email != null) {
      await prefs.setString(_emailKey, profile.email!);
    } else {
      await prefs.remove(_emailKey);
    }
    if (profile.phone != null) {
      await prefs.setString(_phoneKey, profile.phone!);
    } else {
      await prefs.remove(_phoneKey);
    }
    if (profile.dateOfBirth != null) {
      await prefs.setString(_dateOfBirthKey, profile.dateOfBirth!);
    } else {
      await prefs.remove(_dateOfBirthKey);
    }
    notifyListeners();
  }

  /// Сброс настроек к значениям по умолчанию
  Future<void> resetSettings() async {
    _themeMode = ThemeMode.system;
    _languageCode = null;
    // Не сбрасываем _onboardingCompleted чтобы онбординг не показывался снова
    // Не сбрасываем безопасность и личные данные при сбросе настроек
    
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeKey);
    await prefs.remove(_languageKey);
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
