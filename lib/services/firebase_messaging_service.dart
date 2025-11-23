import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Глобальный обработчик фоновых сообщений (обязателен: top-level)
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
/*    //print(
      '[FCM][BG] title=${message.notification?.title} data=${message.data}',
    );*/
  }
}

/// Сервис инициализации Firebase Cloud Messaging
class FirebaseMessagingService {
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // iOS/Android 13+: запрос разрешений
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        //print('[FCM] Permission: ${settings.authorizationStatus}');
      }

      // Регистрация фонового обработчика
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Подписка на сообщения в форграунде
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
/*          //print(
            '[FCM][FG] title=${message.notification?.title} body=${message.notification?.body} data=${message.data}',
          );*/
        }
      });

      // Обработка нажатия при открытии из свернутого состояния
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          //print('[FCM][OPENED] data=${message.data}');
        }
      });

      // Получение (и лог) текущего токена
      try {
        final token = await _messaging.getToken();
        if (kDebugMode) {
          developer.log('[FCM] Token: $token');
        }
      } catch (e) {
        if (kDebugMode) {
          developer.log('[FCM] Failed to get token: $e');
        }
        // Продолжаем инициализацию даже если не удалось получить токен
      }

      // Подписка на обновление токена (ротация)
      _messaging.onTokenRefresh.listen((newToken) {
        if (kDebugMode) {
          //print('[FCM] Token refreshed: $newToken');
        }
      });

      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        //print('[FCM] Initialization failed: $e');
      }
      // Не помечаем как инициализированное, чтобы можно было повторить попытку
      // Но не пробрасываем исключение, чтобы приложение не крашилось
    }
  }
}
