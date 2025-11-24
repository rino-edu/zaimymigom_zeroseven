import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Сервис для работы с App Tracking Transparency (ATT)
/// Запрашивает разрешение на отслеживание пользователей для рекламы и аналитики
class ATTService {
  static ATTService? _instance;
  static ATTService get instance => _instance ??= ATTService._();
  
  ATTService._();

  /// Статус разрешения на отслеживание
  TrackingStatus? _trackingStatus;
  
  /// Получить текущий статус разрешения
  TrackingStatus? get trackingStatus => _trackingStatus;

  /// Инициализация сервиса ATT
  /// Проверяет статус разрешения и запрашивает его при необходимости
  Future<void> initialize() async {
    try {
      // Проверяем, поддерживается ли ATT на текущей платформе
      if (!Platform.isIOS) {
        //debugPrint('ATT: Поддерживается только на iOS');
        return;
      }

      // Получаем текущий статус разрешения
      await _checkTrackingStatus();
      
      //debugPrint('ATT: Инициализация завершена. Статус: $_trackingStatus');
    } catch (e) {
      //debugPrint('ATT: Ошибка инициализации: $e');
    }
  }

  /// Запросить ATT на первом запуске после установки
  /// Диалог iOS показывается только если статус notDetermined и устройство iOS 14.5+
  Future<void> requestIfFirstLaunch() async {
    if (!Platform.isIOS) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      const key = 'att_prompt_shown';
      final alreadyShown = prefs.getBool(key) ?? false;

      await _checkTrackingStatus();

      if (!alreadyShown && _trackingStatus == TrackingStatus.notDetermined) {
        // Небольшая задержка, чтобы дождаться первого фрейма и активного состояния
        await Future.delayed(const Duration(milliseconds: 300));
        final result = await requestTrackingPermission();
        //debugPrint('ATT: Диалог показан на первом запуске, результат: $result');
        await prefs.setBool(key, true);
      } else {
        //debugPrint('ATT: Диалог уже показывался или статус не требует показа');
      }
    } catch (e) {
      //debugPrint('ATT: Ошибка при попытке показа на первом запуске: $e');
    }
  }

  /// Проверка текущего статуса разрешения на отслеживание
  Future<void> _checkTrackingStatus() async {
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      _trackingStatus = status;
      //debugPrint('ATT: Текущий статус разрешения: $status');
    } catch (e) {
      //debugPrint('ATT: Ошибка проверки статуса: $e');
    }
  }

  /// Запрос разрешения на отслеживание
  /// Показывает системный диалог с запросом разрешения
  Future<TrackingStatus> requestTrackingPermission() async {
    try {
      if (!Platform.isIOS) {
        //debugPrint('ATT: Запрос разрешения поддерживается только на iOS');
        return TrackingStatus.notSupported;
      }

      //debugPrint('ATT: Запрашиваем разрешение на отслеживание...');
      
      final status = await AppTrackingTransparency.requestTrackingAuthorization();
      _trackingStatus = status;
      
      //debugPrint('ATT: Результат запроса разрешения: $status');
      
      // Логируем результат для аналитики
      _logTrackingPermissionResult(status);
      
      return status;
    } catch (e) {
      //debugPrint('ATT: Ошибка запроса разрешения: $e');
      return TrackingStatus.denied;
    }
  }

  /// Логирование результата запроса разрешения для аналитики
  void _logTrackingPermissionResult(TrackingStatus status) {
    String statusString;
    switch (status) {
      case TrackingStatus.authorized:
        statusString = 'authorized';
        break;
      case TrackingStatus.denied:
        statusString = 'denied';
        break;
      case TrackingStatus.restricted:
        statusString = 'restricted';
        break;
      case TrackingStatus.notDetermined:
        statusString = 'not_determined';
        break;
      case TrackingStatus.notSupported:
        statusString = 'not_supported';
        break;
    }
    
    //debugPrint('ATT: Разрешение на отслеживание: $statusString');
    
    // Здесь можно отправить событие в аналитику
    // FirebaseAnalytics.instance.logEvent(
    //   name: 'att_permission_result',
    //   parameters: {'status': statusString},
    // );
  }

  /// Проверяет, разрешено ли отслеживание
  bool get isTrackingAuthorized {
    return _trackingStatus == TrackingStatus.authorized;
  }

  /// Проверяет, нужно ли запрашивать разрешение
  bool get shouldRequestPermission {
    return _trackingStatus == null || _trackingStatus == TrackingStatus.notDetermined;
  }

  /// Получить ID рекламного объявления (IDFA)
  /// Доступен только при разрешенном отслеживании
  Future<String?> getAdvertisingId() async {
    try {
      if (!Platform.isIOS) {
        return null;
      }

      if (!isTrackingAuthorized) {
        //debugPrint('ATT: IDFA недоступен - отслеживание не разрешено');
        return null;
      }

      final idfa = await AppTrackingTransparency.getAdvertisingIdentifier();
      //debugPrint('ATT: IDFA получен: ${idfa.isNotEmpty ? '${idfa.substring(0, 8)}...' : 'пустой'}');
      return idfa;
    } catch (e) {
      //debugPrint('ATT: Ошибка получения IDFA: $e');
      return null;
    }
  }

  /// Получить статус разрешения в виде строки для логирования
  String get statusString {
    if (_trackingStatus == null) return 'неизвестно';
    
    switch (_trackingStatus!) {
      case TrackingStatus.authorized:
        return 'разрешено';
      case TrackingStatus.denied:
        return 'отклонено';
      case TrackingStatus.restricted:
        return 'ограничено';
      case TrackingStatus.notDetermined:
        return 'не определено';
      case TrackingStatus.notSupported:
        return 'не поддерживается';
    }
  }
}