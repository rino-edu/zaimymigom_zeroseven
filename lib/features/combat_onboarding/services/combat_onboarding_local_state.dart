import 'package:shared_preferences/shared_preferences.dart';

class CombatOnboardingLocalState {
  static const _firstOpenAtKey = 'combat_onboarding_first_open_at_iso';
  static const _fullyCompletedKey = 'combat_onboarding_fully_completed';
  static const _onboardingWasShownKey = 'combat_onboarding_was_shown';

  /// Возвращает дату первого открытия.
  /// Если ключа нет — сохраняет текущий момент и возвращает его.
  Future<DateTime> getOrSetFirstOpenDate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_firstOpenAtKey);
    if (raw != null && raw.isNotEmpty) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed;
    }

    final now = DateTime.now();
    await prefs.setString(_firstOpenAtKey, now.toIso8601String());
    return now;
  }

  /// Боевой онбординг уже показывали пользователю (экран потока с контентом).
  Future<bool> wasOnboardingShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingWasShownKey) ?? false;
  }

  Future<void> setOnboardingWasShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingWasShownKey, true);
  }

  /// True только если это первый запуск (ключ отсутствует/пустой/битый).
  Future<bool> isFirstOpen() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_firstOpenAtKey);
    if (raw == null || raw.isEmpty) return true;
    return DateTime.tryParse(raw) == null;
  }

  /// Боевой онбординг доведён до конца (после animation2 и успешной записи).
  Future<bool> isCombatOnboardingFullyCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_fullyCompletedKey) ?? false;
  }

  Future<void> setCombatOnboardingFullyCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_fullyCompletedKey, true);
  }
}

