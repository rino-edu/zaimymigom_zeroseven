import 'package:flutter/foundation.dart';
import 'post_info.dart';
import 'ssl_checker.dart';
import 'health_checker.dart';

class DeviceDataService {
  static final DeviceDataService _instance = DeviceDataService._internal();
  factory DeviceDataService() => _instance;
  DeviceDataService._internal();

  final UserDataManager _userDataManager = UserDataManager();
  bool _isInitialized = false;

  /// Инициализация сервиса
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _userDataManager.initialize();
      _isInitialized = true;
      debugPrint('[DeviceDataService] Инициализация завершена успешно');
    } catch (e) {
      debugPrint('[DeviceDataService] Ошибка инициализации: $e');
      rethrow;
    }
  }

  /// Отправка данных об устройстве на сервер
  Future<void> sendDeviceData() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      debugPrint(
        '[DeviceDataService] 🚀 Начинаем отправку данных об устройстве...',
      );

      // Проверяем здоровье сервера
      final healthDiagnosis = await HealthChecker.diagnoseServerHealth();
      debugPrint(
        '[DeviceDataService] 📊 Диагностика здоровья сервера: $healthDiagnosis',
      );

      await _userDataManager.sendDataToServer();
      debugPrint(
        '[DeviceDataService] ✅ Данные об устройстве успешно отправлены',
      );
    } catch (e) {
      debugPrint('[DeviceDataService] ❌ Ошибка отправки данных: $e');
      rethrow;
    }
  }

  /// Полная инициализация и отправка данных
  Future<void> postInfo() async {
    try {
      debugPrint(
        '[DeviceDataService] 🔄 Начинаем полную инициализацию и отправку данных...',
      );

      // Проверяем здоровье сервера перед началом
      final healthCheck = await HealthChecker.checkServerHealth();
      debugPrint(
        '[DeviceDataService] 🏥 Проверка здоровья сервера: ${healthCheck['message']}',
      );

      await _userDataManager.postInfo();
      debugPrint('[DeviceDataService] ✅ postInfo выполнен успешно');
    } catch (e) {
      debugPrint('[DeviceDataService] ❌ Ошибка в postInfo: $e');

      // Специальная обработка SSL ошибок
      if (e.toString().contains('CERTIFICATE_VERIFY_FAILED') ||
          e.toString().contains('HandshakeException')) {
        debugPrint(
          '[DeviceDataService] 🔒 Обнаружена SSL ошибка. '
          'Сертификат сервера истек или недействителен.',
        );
        debugPrint(
          '[DeviceDataService] 💡 Рекомендация: обратитесь к администратору сервера '
          'для обновления SSL сертификата.',
        );

        // Запускаем диагностику сервера в фоновом режиме
        if (kDebugMode) {
          SSLChecker.diagnoseServer().then((diagnosis) {
            debugPrint(
              '[DeviceDataService] 🔍 Диагностика сервера: $diagnosis',
            );
          });
        }
      }

      rethrow;
    }
  }

  /// Проверка статуса инициализации
  bool get isInitialized => _isInitialized;
}
