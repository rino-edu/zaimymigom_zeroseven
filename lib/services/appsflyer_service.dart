import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class AppsFlyerService {
  static AppsflyerSdk? _appsflyerSdk;

  static Future<void> initialize(String devKey) async {
    try {
      final String trimmedKey = devKey.trim();
      if (trimmedKey.isEmpty) {
        debugPrint('[AppsFlyer] Пропускаю инициализацию: пустой devKey');
        return;
      }
      if (!(Platform.isAndroid || Platform.isIOS)) {
        debugPrint('[AppsFlyer] Платформа не поддерживается, пропускаю init');
        return;
      }

      final AppsFlyerOptions options = AppsFlyerOptions(
        afDevKey: trimmedKey,
        showDebug: kDebugMode,
      );
      _appsflyerSdk = AppsflyerSdk(options);
      await _appsflyerSdk!.initSdk();
      debugPrint('[AppsFlyer] SDK успешно инициализирован');
    } catch (e) {
      // Часто на Android при некорректной связке или раннем вызове бывает FormatException: Invalid envelope
      debugPrint('[AppsFlyer] Ошибка инициализации: $e');
    }
  }

  static Future<String> getAppsFlyerUID() async {
    try {
      if (_appsflyerSdk == null) {
        return 'af_uid_uninitialized';
      }
      String? uid = await _appsflyerSdk!.getAppsFlyerUID();
      return uid ?? 'af_uid_error';
    } catch (e) {
      debugPrint('[AppsFlyer] Ошибка при получении AppsFlyerUID: $e');
      return 'af_uid_error';
    }
  }
}
