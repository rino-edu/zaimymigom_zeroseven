import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class CombatOnboardingLocalState {
  static const _firstOpenAtKey = 'combat_onboarding_first_open_at_iso';
  static const _fullyCompletedKey = 'combat_onboarding_fully_completed';
  static const _onboardingWasShownKey = 'combat_onboarding_was_shown';
  static const _lastKnownInstallTimeMsKey =
      'combat_onboarding_last_known_install_time_ms';
  static const _prefsInstallSessionIdKey =
      'combat_onboarding_prefs_install_session_id';

  static const _secureInstallSessionIdKey =
      'combat_onboarding_install_session_id';

  static const _secureStorage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Сверяет сессию установки; при переустановке (особенно iOS) сбрасывает флаги онбординга.
  ///
  /// Вызывать до [wasOnboardingShown] (например, в [CombatOnboardingGate]).
  Future<void> syncInstallSession() async {
    final prefs = await SharedPreferences.getInstance();
    await _syncInstallSessionBySecureId(prefs);
    await _syncInstallSessionByInstallFingerprint(prefs);
  }

  /// iOS: Keychain часто переживает удаление приложения, а UserDefaults — нет (и наоборот при iCloud).
  Future<void> _syncInstallSessionBySecureId(SharedPreferences prefs) async {
    if (kIsWeb) return;

    String? secureId;
    try {
      secureId = await _secureStorage.read(key: _secureInstallSessionIdKey);
    } catch (e) {
      debugPrint(
        'CombatOnboardingLocalState: secure session read failed: $e',
      );
      return;
    }

    final prefsId = prefs.getString(_prefsInstallSessionIdKey);
    final wasShown = prefs.getBool(_onboardingWasShownKey) ?? false;

    if (secureId == null || secureId.isEmpty) {
      final newId = const Uuid().v4();
      await _secureStorage.write(
        key: _secureInstallSessionIdKey,
        value: newId,
      );

      if (await _shouldResetOnNewSecureSession(prefs, wasShown: wasShown)) {
        debugPrint(
          'CombatOnboardingLocalState: new Keychain session, reset onboarding',
        );
        await _resetOnboardingFlags(prefs);
      }

      await prefs.setString(_prefsInstallSessionIdKey, newId);
      return;
    }

    if (prefsId == null || prefsId.isEmpty || prefsId != secureId) {
      debugPrint(
        'CombatOnboardingLocalState: prefs/Keychain session mismatch, '
        'reset onboarding (prefsId=$prefsId secureId=$secureId)',
      );
      await _resetOnboardingFlags(prefs);
      await prefs.setString(_prefsInstallSessionIdKey, secureId);
    }
  }

  /// Не сбрасываем при миграции на новую схему, если отпечаток установки тот же.
  Future<bool> _shouldResetOnNewSecureSession(
    SharedPreferences prefs, {
    required bool wasShown,
  }) async {
    final prefsId = prefs.getString(_prefsInstallSessionIdKey);
    if (!wasShown && (prefsId == null || prefsId.isEmpty)) {
      return false;
    }

    final storedMs = prefs.getInt(_lastKnownInstallTimeMsKey);
    final currentMs = await _currentInstallFingerprintMs();
    if (storedMs == null || currentMs == null) {
      return wasShown || (prefsId != null && prefsId.isNotEmpty);
    }
    return storedMs != currentMs;
  }

  /// Android: [PackageInfo.installTime]. iOS: [PackageInfo.updateTime] (дата бандла),
  /// т.к. installTime на iOS — дата создания Documents и восстанавливается из iCloud.
  Future<void> _syncInstallSessionByInstallFingerprint(
    SharedPreferences prefs,
  ) async {
    final currentMs = await _currentInstallFingerprintMs();
    if (currentMs == null) {
      debugPrint(
        'CombatOnboardingLocalState: install fingerprint unavailable',
      );
      return;
    }

    final storedMs = prefs.getInt(_lastKnownInstallTimeMsKey);

    if (storedMs == null) {
      await prefs.setInt(_lastKnownInstallTimeMsKey, currentMs);
      return;
    }

    if (storedMs == currentMs) return;

    debugPrint(
      'CombatOnboardingLocalState: install fingerprint changed '
      '(stored=$storedMs current=$currentMs), reset onboarding',
    );
    await _resetOnboardingFlags(prefs);
    await prefs.setInt(_lastKnownInstallTimeMsKey, currentMs);
  }

  Future<int?> _currentInstallFingerprintMs() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final DateTime? fingerprint = _isIOS
          ? (info.updateTime ?? info.installTime)
          : info.installTime;
      return fingerprint?.millisecondsSinceEpoch;
    } catch (e) {
      debugPrint(
        'CombatOnboardingLocalState: PackageInfo fingerprint failed: $e',
      );
      return null;
    }
  }

  bool get _isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> _resetOnboardingFlags(SharedPreferences prefs) async {
    await prefs.remove(_onboardingWasShownKey);
    await prefs.remove(_fullyCompletedKey);
    await prefs.remove(_firstOpenAtKey);
  }

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
