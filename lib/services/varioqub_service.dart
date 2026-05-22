import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:varioqub_plugin/varioqub_plugin.dart';

/// Обёртка над Varioqub SDK: инициализация и чтение флага `showOnboarding`.
class VarioqubService {
  static final VarioqubService _instance = VarioqubService._internal();
  factory VarioqubService() => _instance;
  VarioqubService._internal();

  /// ID проекта AppMetrica: `appmetrica.XXXXXX` (Настройки → ID приложения).
  /// Замените на ID вашего приложения в интерфейсе AppMetrica.
  static const String clientId = 'appmetrica.4796974';

  static const String showOnboardingFlagKey = 'showOnboarding';

  bool _initialized = false;
  bool _configActivated = false;

  bool get isAvailable => _initialized && _configActivated;

  /// Инициализация после AppMetrica: defaults → activateConfig → fetch в фоне.
  Future<void> initialize() async {
    try {
      await Varioqub.initVarioqubWithAppMetricaAdapter(
        VarioqubSettings(
          clientId,
          logs: kDebugMode,
        ),
      );

      await Varioqub.setDefaults({
        showOnboardingFlagKey: 'false',
      });

      await Varioqub.activateConfig();
      _initialized = true;
      _configActivated = true;

      if (kDebugMode) {
        debugPrint('VarioqubService: initialized, config activated');
      }

      unawaited(_fetchConfigInBackground());
    } on PlatformException catch (e, st) {
      _initialized = false;
      _configActivated = false;
      debugPrint('VarioqubService: init failed: $e\n$st');
    } catch (e, st) {
      _initialized = false;
      _configActivated = false;
      debugPrint('VarioqubService: init failed: $e\n$st');
    }
  }

  Future<void> _fetchConfigInBackground() async {
    try {
      final status = await Varioqub.fetchConfig();
      if (status.status == 0) {
        if (kDebugMode) {
          debugPrint('VarioqubService: fetchConfig OK (next session)');
        }
      } else if (kDebugMode) {
        debugPrint(
          'VarioqubService: fetchConfig error status=${status.status} '
          '${status.error}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('VarioqubService: fetchConfig failed: $e');
      }
    }
  }

  /// Читает флаг `showOnboarding` из активной конфигурации Varioqub.
  ///
  /// Возвращает `null`, если SDK недоступен или значение не распознано.
  Future<bool?> tryGetShowOnboarding() async {
    if (!isAvailable) {
      if (kDebugMode) {
        debugPrint(
          'VarioqubService: unavailable (init=$_initialized activated=$_configActivated)',
        );
      }
      return null;
    }

    try {
      final raw = await Varioqub.getString(showOnboardingFlagKey, '');
      final parsed = _parseShowOnboardingString(raw);
      if (parsed == null) {
        if (kDebugMode) {
          debugPrint(
            'VarioqubService: flag "$showOnboardingFlagKey" empty or invalid: "$raw"',
          );
        }
        return null;
      }
      if (kDebugMode) {
        debugPrint(
          'VarioqubService: $showOnboardingFlagKey="$raw" → $parsed',
        );
      }
      return parsed;
    } on PlatformException catch (e) {
      debugPrint('VarioqubService: getString failed: $e');
      return null;
    } catch (e) {
      debugPrint('VarioqubService: getString failed: $e');
      return null;
    }
  }

  /// `"true"` / `"false"` (без учёта регистра) → bool; иначе `null`.
  static bool? _parseShowOnboardingString(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    switch (normalized) {
      case 'true':
        return true;
      case 'false':
        return false;
      default:
        return null;
    }
  }
}
