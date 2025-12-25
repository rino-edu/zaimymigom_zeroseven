import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Сервис для работы с Firebase Crashlytics
class FirebaseCrashlyticsService {
  // Синглтон
  static final FirebaseCrashlyticsService _instance =
      FirebaseCrashlyticsService._internal();
  factory FirebaseCrashlyticsService() => _instance;
  FirebaseCrashlyticsService._internal();

  // Экземпляр Firebase Crashlytics
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  // Инициализация
  Future<void> init() async {
    debugPrint('FirebaseCrashlyticsService: инициализация');

    // Включаем сбор данных краша
    await _crashlytics.setCrashlyticsCollectionEnabled(true);

    // Устанавливаем кастомный обработчик ошибок Flutter
    FlutterError.onError = _crashlytics.recordFlutterError;

    // Устанавливаем кастомный обработчик ошибок Dart
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return true;
    };

    debugPrint('FirebaseCrashlyticsService: инициализация завершена');
  }

  // Установка пользовательского идентификатора
  Future<void> setUserId(String userId) async {
    try {
      await _crashlytics.setUserIdentifier(userId);
      debugPrint('FirebaseCrashlyticsService: установлен userId: $userId');
    } catch (e) {
      debugPrint('FirebaseCrashlyticsService: ошибка при установке userId: $e');
    }
  }

  // Установка пользовательских ключей
  Future<void> setCustomKey(String key, dynamic value) async {
    try {
      if (value is String) {
        await _crashlytics.setCustomKey(key, value);
      } else if (value is bool) {
        await _crashlytics.setCustomKey(key, value);
      } else if (value is int) {
        await _crashlytics.setCustomKey(key, value);
      } else if (value is double) {
        await _crashlytics.setCustomKey(key, value);
      } else {
        await _crashlytics.setCustomKey(key, value.toString());
      }
      debugPrint('FirebaseCrashlyticsService: установлен ключ $key: $value');
    } catch (e) {
      debugPrint(
        'FirebaseCrashlyticsService: ошибка при установке ключа $key: $e',
      );
    }
  }

  // Логирование сообщения
  Future<void> log(String message) async {
    try {
      await _crashlytics.log(message);
      debugPrint(
        'FirebaseCrashlyticsService: залогировано сообщение: $message',
      );
    } catch (e) {
      debugPrint(
        'FirebaseCrashlyticsService: ошибка при логировании сообщения: $e',
      );
    }
  }

  // Запись ошибки
  Future<void> recordError(
    dynamic exception,
    StackTrace stack, {
    bool fatal = false,
  }) async {
    try {
      await _crashlytics.recordError(exception, stack, fatal: fatal);
      debugPrint('FirebaseCrashlyticsService: записана ошибка: $exception');
    } catch (e) {
      debugPrint('FirebaseCrashlyticsService: ошибка при записи ошибки: $e');
    }
  }
}
