import 'package:shared_preferences/shared_preferences.dart';

class CombatOnboardingLocalState {
  static const _firstOpenAtKey = 'combat_onboarding_first_open_at_iso';

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

  /// True только если это первый запуск (ключ отсутствует/пустой/битый).
  Future<bool> isFirstOpen() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_firstOpenAtKey);
    if (raw == null || raw.isEmpty) return true;
    return DateTime.tryParse(raw) == null;
  }
}

