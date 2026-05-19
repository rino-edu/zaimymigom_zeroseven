import 'package:firebase_analytics/firebase_analytics.dart';

/// Повод залогировать показ [LoansScreen] после гейта / онбординга (один раз за вход).
enum CombatLoansShowCaseReason {
  afterOnboardingFinish,
  afterOnboardingClose,
  withoutOnboarding,
}

/// События Firebase Analytics (GA4).
class FirebaseAnalyticsService {
  FirebaseAnalyticsService._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Лимит длины значения параметра для стабильной агрегации в GA4.
  static const int maxParamValueLength = 100;

  static String trimForGa(String value, [int max = maxParamValueLength]) {
    final t = value.trim();
    if (t.length <= max) return t;
    return t.substring(0, max);
  }

  static Future<void> logOnboardingShow() async {
    await _analytics.logEvent(name: 'onboarding_show');
  }

  static Future<void> logShowCaseOnboardingFinish() async {
    await _analytics.logEvent(name: 'show_case_onboarding_finish');
  }

  static Future<void> logShowCaseOnboardingClose() async {
    await _analytics.logEvent(name: 'show_case_onboarding_close');
  }

  static Future<void> logShowCaseOnboardingNone() async {
    await _analytics.logEvent(name: 'show_case_onboarding_none');
  }

  static Future<void> logOnboardingStart() async {
    await _analytics.logEvent(name: 'onboarding_start');
  }

  static Future<void> logOnboardingFinish() async {
    await _analytics.logEvent(name: 'onboarding_finish');
  }

  /// Событие `onboarding_page_{pageNumber}` (номер как в Firestore: page2 → 2).
  static Future<void> logOnboardingPageAnswer({
    required int pageNumber,
    required String questionAnswer,
  }) async {
    await _analytics.logEvent(
      name: 'onboarding_page_$pageNumber',
      parameters: {'question_answer': trimForGa(questionAnswer)},
    );
  }

  /// [pageNumber] — порядковый номер экрана в потоке от 1 до N (старт = 1, финал = N).
  static Future<void> logOnboardingClose({required int pageNumber}) async {
    await _analytics.logEvent(
      name: 'onboarding_close',
      parameters: {'page_number': pageNumber},
    );
  }

  static Future<void> logOfferOpen({
    required String link,
    required String name,
  }) async {
    await _analytics.logEvent(
      name: 'offer_open',
      parameters: {
        'link': trimForGa(link, 500),
        'name': trimForGa(name),
      },
    );
  }

  static Future<void> logShowcaseShown() async {
    await _analytics.logEvent(name: 'showcase_shown');
  }

  static Future<void> logShowcaseNotShown() async {
    await _analytics.logEvent(name: 'showcase_not_shown');
  }

  static Future<void> logShowcaseError({required String message}) async {
    await _analytics.logEvent(
      name: 'showcase_error',
      parameters: {'message': trimForGa(message)},
    );
  }

  static Future<void> logLoansShowCaseIfNeeded(
    CombatLoansShowCaseReason? reason,
  ) async {
    if (reason == null) return;
    switch (reason) {
      case CombatLoansShowCaseReason.afterOnboardingFinish:
        await logShowCaseOnboardingFinish();
      case CombatLoansShowCaseReason.afterOnboardingClose:
        await logShowCaseOnboardingClose();
      case CombatLoansShowCaseReason.withoutOnboarding:
        await logShowCaseOnboardingNone();
    }
  }
}
