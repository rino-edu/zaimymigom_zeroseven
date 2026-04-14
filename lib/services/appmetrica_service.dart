import 'package:appmetrica_plugin/appmetrica_plugin.dart';
import 'package:appmetrica_push_plugin/appmetrica_push_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vpn_detector/vpn_detector.dart';
import 'package:http/http.dart' as http;

/// Сервис для работы с AppMetrica
class AppMetricaService {
  static final String _apiKey = "c828e376-a236-497e-9d06-af7a0d0cbc9e"; // Замените на ваш API ключ
  static const String _vpnWereOpenedKey = 'vpn_were_opened';
  static const String _deviceIdHashCacheKey = 'appmetrica_device_id_hash';

  /// Инициализация AppMetrica
  Future<void> initialize() async {
    try {
      // Конфигурация AppMetrica
      final config = AppMetricaConfig(
        _apiKey,
        // Включаем логирование в debug режиме
        logs: kDebugMode,
        // Включаем crash reporting
        crashReporting: true,
        // Включаем location tracking (опционально)
        locationTracking: false,
        // Включаем session timeout (в секундах)
        sessionTimeout: 20,
        // Включаем first activation as update
        firstActivationAsUpdate: false,
      );

      // Инициализация AppMetrica
      await AppMetrica.activate(config);
      // Инициализация AppMetrica Push SDK
      await _initPush();
      if (kDebugMode) {
        print('AppMetrica initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing AppMetrica: $e');
      }
    }
  }

  /// Инициализация AppMetrica Push SDK
  Future<void> _initPush() async {
    try {
      debugPrint('AppMetricaService: инициализация Push SDK');

      // Инициализация Push SDK
      await AppMetricaPush.activate();
      debugPrint('AppMetricaService: Push SDK активирован');

      // Получение токена Firebase и настройка слушателя токенов
      AppMetricaPush.tokenStream.listen((tokens) {
        debugPrint('AppMetricaService: получены новые токены: $tokens');
      });
    } catch (e) {
      debugPrint('AppMetricaService: ошибка при инициализации Push SDK: $e');
    }
  }

  /// Отправка события
  static Future<void> reportEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      if (parameters != null) {
        // Конвертируем Map<String, dynamic> в Map<String, Object>
        final Map<String, Object> convertedParams = parameters.map(
          (key, value) => MapEntry(key, value as Object),
        );
        await AppMetrica.reportEventWithMap(eventName, convertedParams);
      } else {
        await AppMetrica.reportEvent(eventName);
      }
      if (kDebugMode) {
        print('AppMetrica event sent: $eventName with params: $parameters');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending AppMetrica event: $e');
      }
    }
  }

  /// Отправка экрана
  static Future<void> reportScreen(String screenName) async {
    try {
      await AppMetrica.reportEventWithMap(
        'screen_view',
        {'screen_name': screenName} as Map<String, Object>,
      );
      if (kDebugMode) {
        print('AppMetrica screen reported: $screenName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error reporting AppMetrica screen: $e');
      }
    }
  }

  /// Отправка пользовательского атрибута
  static Future<void> setUserProfileAttribute(String key, dynamic value) async {
    try {
      // Отправляем как событие с пользовательскими данными
      await AppMetrica.reportEventWithMap(
        'user_attribute',
        {'attribute_key': key, 'attribute_value': value.toString()}
            as Map<String, Object>,
      );
      if (kDebugMode) {
        print('AppMetrica user attribute set: $key = $value');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting AppMetrica user attribute: $e');
      }
    }
  }

  /// Отправка ошибки
  static Future<void> reportError(String error, {String? reason}) async {
    try {
      // Отправляем как событие с информацией об ошибке
      await AppMetrica.reportEventWithMap(
        'app_error',
        {'error': error, 'reason': reason ?? 'Unknown'} as Map<String, Object>,
      );
      if (kDebugMode) {
        print('AppMetrica error reported: $error, reason: $reason');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error reporting AppMetrica error: $e');
      }
    }
  }

  /// Получение AppMetrica Device ID (deviceIdHash)
  static Future<String> getDeviceIdHash() async {
    try {
      final params = await AppMetrica.requestStartupParams([
        AppMetricaStartupParams.deviceIdHashKey,
      ]);
      final deviceId = params.result?.deviceIdHash ?? "unknown";
      debugPrint("AppMetrica Device ID: $deviceId");
      return deviceId;
    } catch (e) {
      debugPrint("Ошибка при получении AppMetrica Device ID: $e");
      return "unknown";
    }
  }

  /// Получение deviceIdHash с кешированием в SharedPreferences.
  static Future<String> getCachedDeviceIdHash() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_deviceIdHashCacheKey);
    if (cached != null && cached.trim().isNotEmpty) return cached;

    final fresh = await getDeviceIdHash();
    if (fresh.trim().isNotEmpty && fresh != 'unknown') {
      await prefs.setString(_deviceIdHashCacheKey, fresh);
    }
    return fresh;
  }

  static String _formatGmtPlus3Now() {
    final dt = DateTime.now().toUtc().add(const Duration(hours: 3));
    String two(int v) => v.toString().padLeft(2, '0');
    // 24-часовой формат по умолчанию: yyyy-MM-dd HH:mm:ss (GMT+3)
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }

  static Future<String> _getLocationByIp() async {
    try {
      final response = await http
          .get(Uri.parse('https://ipinfo.io/json'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = response.body;
        final countryCodeMatch =
            RegExp(r'"country"\\s*:\\s*"([^"]+)"').firstMatch(data);
        if (countryCodeMatch != null) {
          return (countryCodeMatch.group(1) ?? 'unknown').toLowerCase();
        }
      }
    } catch (e) {
      debugPrint('AppMetricaService: location by ip failed: $e');
    }
    return 'unknown';
  }

  /// Отправка `vpn_status_on`/`vpn_status_off_after_on` при старте приложения.
  ///
  /// - Если VPN активен → всегда шлём `vpn_status_on`, и ставим `vpn_were_opened=true` (если не было).
  /// - Если VPN НЕ активен и `vpn_were_opened==true` → шлём `vpn_status_off_after_on` и сбрасываем флаг.
  static Future<void> reportVpnStatusOnLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final vpnWasOpened = prefs.getBool(_vpnWereOpenedKey) ?? false;

    bool isVpnActive = false;
    try {
      isVpnActive = await VpnDetector().isVpnActive();
    } catch (e) {
      debugPrint('AppMetricaService: VPN detector failed: $e');
      isVpnActive = false;
    }

    final appmetricaId = await getCachedDeviceIdHash();
    final location = await _getLocationByIp();
    final ts = _formatGmtPlus3Now();
    final data = '$appmetricaId, $location, $ts';

    if (isVpnActive) {
      await reportEvent('vpn_status_on', parameters: {'data': data});
      if (!vpnWasOpened) {
        await prefs.setBool(_vpnWereOpenedKey, true);
      }
      return;
    }

    if (vpnWasOpened) {
      await reportEvent(
        'vpn_status_off_after_on',
        parameters: {'data': data},
      );
      await prefs.setBool(_vpnWereOpenedKey, false);
    }
  }
}
