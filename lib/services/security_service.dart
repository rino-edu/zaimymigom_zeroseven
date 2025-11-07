import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

/// Сервис для работы с биометрической аутентификацией
class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Доступна ли биометрия на устройстве
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// Получить доступные типы биометрии
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Провести биометрическую аутентификацию
  Future<bool> authenticate({
    String localizedReason = 'Пожалуйста, подтвердите свою личность',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
    bool biometricOnly = true,
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: biometricOnly,
        ),
      );
    } on PlatformException {
      // Обработка ошибок платформы
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Проверить, поддерживается ли биометрия
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// Получить тип биометрии в виде строки
  String getBiometricTypeString(List<BiometricType> types) {
    if (types.isEmpty) return '';
    if (types.contains(BiometricType.face)) return 'Face ID';
    if (types.contains(BiometricType.fingerprint)) return 'Fingerprint';
    if (types.contains(BiometricType.iris)) return 'Iris';
    if (types.contains(BiometricType.strong)) return 'Strong';
    if (types.contains(BiometricType.weak)) return 'Weak';
    return 'Biometric';
  }
}

