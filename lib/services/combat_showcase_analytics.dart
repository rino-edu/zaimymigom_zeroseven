import 'dart:async';

import 'package:flutter/widgets.dart';

import 'app_mode_service.dart';
import 'appmetrica_service.dart';
import 'firebase_analytics_service.dart';

/// Флаги одного запуска приложения: онбординг уже показывали, Loans в бою ещё не открывали.
class CombatShowcaseSession {
  CombatShowcaseSession._();

  static bool onboardingShowLogged = false;
  static bool loansScreenOpenedCombat = false;
  static bool _showcaseNotShownSent = false;

  static void markOnboardingShowLogged() {
    onboardingShowLogged = true;
  }

  static void markLoansScreenOpenedCombat() {
    loansScreenOpenedCombat = true;
  }

  /// Возвращает true, если событие `showcase_not_shown` ещё не отправляли и условия выполняются.
  static bool tryClaimNotShown() {
    if (!onboardingShowLogged || loansScreenOpenedCombat || _showcaseNotShownSent) {
      return false;
    }
    _showcaseNotShownSent = true;
    return true;
  }
}

/// События витрины займов (боевой режим): Firebase Analytics + AppMetrica.
class CombatShowcaseAnalytics {
  CombatShowcaseAnalytics._();

  static Future<void> reportShown() async {
    await FirebaseAnalyticsService.logShowcaseShown();
    await AppMetricaService.reportEvent('showcase_shown');
  }

  static Future<void> reportNotShownIfEligible() async {
    if (AppModeService().currentMode != AppMode.combat) return;
    if (!CombatShowcaseSession.tryClaimNotShown()) return;
    await FirebaseAnalyticsService.logShowcaseNotShown();
    await AppMetricaService.reportEvent('showcase_not_shown');
  }

  static Future<void> reportError({required String message}) async {
    final trimmed = FirebaseAnalyticsService.trimForGa(message);
    await FirebaseAnalyticsService.logShowcaseError(message: trimmed);
    await AppMetricaService.reportEvent(
      'showcase_error',
      parameters: {'message': trimmed},
    );
  }
}

/// Уход в фон после показа онбординга без открытия [LoansScreen] (с задержкой, чтобы отсечь краткое переключение приложений).
class CombatShowcaseLifecycleObserver extends WidgetsBindingObserver {
  CombatShowcaseLifecycleObserver._();

  static final CombatShowcaseLifecycleObserver instance =
      CombatShowcaseLifecycleObserver._();

  bool _registered = false;
  Timer? _pauseTimer;

  void registerIfNeeded() {
    if (_registered) return;
    _registered = true;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pauseTimer?.cancel();
      _pauseTimer = Timer(const Duration(seconds: 2), () {
        unawaited(CombatShowcaseAnalytics.reportNotShownIfEligible());
      });
    } else if (state == AppLifecycleState.resumed) {
      _pauseTimer?.cancel();
    }
  }
}
