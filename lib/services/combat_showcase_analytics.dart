import 'dart:async';

import 'package:flutter/widgets.dart';

import '../features/combat_onboarding/services/combat_onboarding_local_state.dart';
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

/// Lifecycle: kill онбординга (abandon без resume) и аналитика showcase_not_shown.
class CombatShowcaseLifecycleObserver extends WidgetsBindingObserver {
  CombatShowcaseLifecycleObserver._();

  static final CombatShowcaseLifecycleObserver instance =
      CombatShowcaseLifecycleObserver._();

  bool _registered = false;
  Timer? _pauseTimer;
  final _localState = CombatOnboardingLocalState();

  void registerIfNeeded() {
    if (_registered) return;
    _registered = true;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // iOS: при kill из карусели часто приходит только inactive, без paused.
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_onAppBackgrounded());
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _pauseTimer?.cancel();
      _pauseTimer = Timer(const Duration(seconds: 2), () {
        unawaited(CombatShowcaseAnalytics.reportNotShownIfEligible());
      });
    } else if (state == AppLifecycleState.resumed) {
      _pauseTimer?.cancel();
      unawaited(_localState.clearOnboardingAbandoned());
    }
  }

  /// Уход в фон во время онбординга: при kill без resume флаг останется до cold start.
  Future<void> _onAppBackgrounded() async {
    if (AppModeService().currentMode != AppMode.combat) return;
    if (CombatShowcaseSession.loansScreenOpenedCombat) return;
    if (!await _localState.isOnboardingFlowActive()) return;
    if (await _localState.isCombatOnboardingFullyCompleted()) return;
    await _localState.markOnboardingAbandoned();
  }
}
