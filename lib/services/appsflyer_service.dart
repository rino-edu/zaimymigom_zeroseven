import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';

class AppsFlyerService {
  static AppsflyerSdk? _appsflyerSdk;

  static Future<void> initialize(String devKey) async {
    try {
      final options = AppsFlyerOptions(afDevKey: devKey, showDebug: kDebugMode);
      _appsflyerSdk = AppsflyerSdk(options);
      await _appsflyerSdk!.initSdk();
      debugPrint('[AppsFlyer] SDK успешно инициализирован');
    } catch (e, s) {
      debugPrint('[AppsFlyer] Ошибка инициализации: $e\n$s');
    }
  }
}
