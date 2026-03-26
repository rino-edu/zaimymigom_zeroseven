import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Тут нельзя трогать UI. Оставляем минимальную обработку.
  if (kDebugMode) {
    debugPrint('FCM(background): messageId=${message.messageId}');
  }
}

class FCMService {
  FCMService._internal();

  static final FCMService instance = FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;
  StreamSubscription<String>? _onTokenRefreshSub;

  bool _initialized = false;

  Future<void> initialize({
    void Function(RemoteMessage message)? onForegroundMessage,
    void Function(RemoteMessage message)? onMessageOpenedApp,
    void Function(RemoteMessage message)? onInitialMessage,
    void Function(String token)? onToken,
    void Function(String token)? onTokenRefresh,
  }) async {
    if (_initialized) return;
    _initialized = true;

    await _requestPermissions();

    await _ensureIosPresentationOptions();

    await _initToken(
      onToken: onToken,
      onTokenRefresh: onTokenRefresh,
    );

    _listenForegroundMessages(onForegroundMessage);
    _listenMessageOpenedApp(onMessageOpenedApp);
    await _handleInitialMessage(onInitialMessage);
  }

  Future<void> dispose() async {
    await _onMessageSub?.cancel();
    await _onMessageOpenedAppSub?.cancel();
    await _onTokenRefreshSub?.cancel();
    _onMessageSub = null;
    _onMessageOpenedAppSub = null;
    _onTokenRefreshSub = null;
    _initialized = false;
  }

  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    if (kDebugMode) {
      debugPrint('FCM: permission=${settings.authorizationStatus}');
    }
  }

  Future<void> _ensureIosPresentationOptions() async {
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _initToken({
    void Function(String token)? onToken,
    void Function(String token)? onTokenRefresh,
  }) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        if (kDebugMode) {
          debugPrint('FCM: token=$token');
        }
        onToken?.call(token);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM: getToken error: $e');
      }
    }

    _onTokenRefreshSub = _messaging.onTokenRefresh.listen((token) {
      if (kDebugMode) {
        debugPrint('FCM: token refreshed=$token');
      }
      onTokenRefresh?.call(token);
    });
  }

  void _listenForegroundMessages(
    void Function(RemoteMessage message)? onForegroundMessage,
  ) {
    _onMessageSub = FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode) {
        debugPrint('FCM(foreground): messageId=${message.messageId}');
      }
      onForegroundMessage?.call(message);
    });
  }

  void _listenMessageOpenedApp(
    void Function(RemoteMessage message)? onMessageOpenedApp,
  ) {
    _onMessageOpenedAppSub = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) {
        if (kDebugMode) {
          debugPrint('FCM(opened): messageId=${message.messageId}');
        }
        onMessageOpenedApp?.call(message);
      },
    );
  }

  Future<void> _handleInitialMessage(
    void Function(RemoteMessage message)? onInitialMessage,
  ) async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage == null) return;

    if (kDebugMode) {
      debugPrint('FCM(initial): messageId=${initialMessage.messageId}');
    }
    onInitialMessage?.call(initialMessage);
  }
}

