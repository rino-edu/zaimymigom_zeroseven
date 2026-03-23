import 'package:appmetrica_plugin/appmetrica_plugin.dart';
import 'package:flutter/foundation.dart';

/// Сервис для работы с AppMetrica
class AppMetricaService {
  static const String _apiKey =
      '578c188a-a177-4fef-a1e1-673f1345de0a'; // Замените на ваш API ключ

  /// Инициализация AppMetrica
  static Future<void> initialize() async {
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

      if (kDebugMode) {
        print('AppMetrica initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing AppMetrica: $e');
      }
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
}
