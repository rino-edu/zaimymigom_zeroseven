import 'dart:async';

import 'package:appmetrica_plugin/appmetrica_plugin.dart';
import 'package:appmetrica_push_plugin/appmetrica_push_plugin.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vpn_detector/vpn_detector.dart';
import 'package:http/http.dart' as http;

import 'pending_push_open_channel.dart';

/// Сервис для работы с AppMetrica
class AppMetricaService {
  static final String _apiKey = "c828e376-a236-497e-9d06-af7a0d0cbc9e"; // Замените на ваш API ключ
  static const String _vpnWereOpenedKey = 'vpn_were_opened';
  static const String _deviceIdHashCacheKey = 'appmetrica_device_id_hash';
  static const Duration _pushOpenDedupWindow = Duration(seconds: 3);

  static StreamSubscription? _pushClickSub;
  static StreamSubscription? _fcmOpenedSub;
  static String? _lastPushOpenKey;
  static DateTime? _lastPushOpenAt;
  static bool _pushClickListenerAttached = false;
  static bool _fcmPushOpenTrackingAttached = false;
  static bool _coldStartPushOpenHandled = false;

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

      _attachPushClickListener();
      await _handleColdStartPushOpen();

      // Получение токена Firebase и настройка слушателя токенов
      AppMetricaPush.tokenStream.listen((tokens) {
        debugPrint('AppMetricaService: получены новые токены: $tokens');
      });
    } catch (e) {
      debugPrint('AppMetricaService: ошибка при инициализации Push SDK: $e');
    }
  }

  /// FCM fallback для открытия push. Вызывать после инициализации FCM.
  static Future<void> setupPushOpenTracking() async {
    if (_fcmPushOpenTrackingAttached) return;
    _fcmPushOpenTrackingAttached = true;

    _fcmOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      reportPushOpen(
        payload: _fcmPayload(message),
        messageId: message.messageId,
      );
    });

    try {
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        await reportPushOpen(
          payload: _fcmPayload(initialMessage),
          messageId: initialMessage.messageId,
        );
      }
    } catch (e) {
      debugPrint('AppMetricaService: getInitialMessage error: $e');
    }
  }

  static void _attachPushClickListener() {
    if (_pushClickListenerAttached) return;
    _pushClickListenerAttached = true;

    _pushClickSub = AppMetricaPush.pushClickStream.listen((info) {
      reportPushOpen(payload: info.payload);
    });
  }

  static Future<void> _handleColdStartPushOpen() async {
    if (_coldStartPushOpenHandled) return;
    _coldStartPushOpenHandled = true;

    try {
      final pending = await PendingPushOpenChannel.consumeLaunchPush();
      if (pending != null) {
        await reportPushOpen(payload: pending.payload);
        return;
      }
    } catch (e) {
      debugPrint('AppMetricaService: pending push open error: $e');
    }

    try {
      final launchInfo = await AppMetricaPush.getLaunchPushInfo();
      final launchPayload = launchInfo.payload?.trim();
      if (launchPayload != null && launchPayload.isNotEmpty) {
        await reportPushOpen(payload: launchPayload);
      }
    } catch (e) {
      debugPrint('AppMetricaService: getLaunchPushInfo error: $e');
    }
  }

  /// Событие открытия push-уведомления (тап пользователя).
  static Future<void> reportPushOpen({
    String? payload,
    String? messageId,
  }) async {
    final normalizedPayload = payload?.trim();
    final normalizedMessageId = messageId?.trim();
    final dedupKey =
        '${normalizedPayload ?? ''}|${normalizedMessageId ?? ''}';
    final now = DateTime.now();

    if (_lastPushOpenKey == dedupKey &&
        _lastPushOpenAt != null &&
        now.difference(_lastPushOpenAt!) < _pushOpenDedupWindow) {
      return;
    }

    _lastPushOpenKey = dedupKey;
    _lastPushOpenAt = now;

    final parameters = <String, dynamic>{};
    if (normalizedPayload != null && normalizedPayload.isNotEmpty) {
      parameters['payload'] = normalizedPayload;
    }
    if (normalizedMessageId != null && normalizedMessageId.isNotEmpty) {
      parameters['message_id'] = normalizedMessageId;
    }

    await reportEvent(
      'push_open',
      parameters: parameters.isEmpty ? null : parameters,
    );
    await PendingPushOpenChannel.clear();
  }

  static String? _fcmPayload(RemoteMessage message) {
    final dataPayload = message.data['payload'] ?? message.data['yamp'];
    if (dataPayload != null && dataPayload.toString().trim().isNotEmpty) {
      return dataPayload.toString();
    }
    return message.notification?.title;
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

  /// Определение страны пользователя по IP
  static Future<String?> _getUserCountryByIp() async {
    try {
      final response = await http
          .get(Uri.parse('https://ipinfo.io/json'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = response.body;
        // Простое извлечение кода страны из JSON ipinfo.io
        final countryCodeMatch = RegExp(
          r'"country"\s*:\s*"([^"]+)"',
        ).firstMatch(data);
        if (countryCodeMatch != null) {
          final countryCode = countryCodeMatch.group(1);
          print('   ✅ User country detected: $countryCode');
          return countryCode;
        }
      }

      print('   ❌ Failed to detect country from IP');
      return null;
    } catch (e) {
      print('   ❌ Country detection failed: $e');
      return null;
    }
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
    final location = await _getUserCountryByIp();
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
