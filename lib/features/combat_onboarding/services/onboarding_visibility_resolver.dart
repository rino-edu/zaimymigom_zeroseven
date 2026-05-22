import 'package:flutter/foundation.dart';

import '../../../models/firebase_settings.dart';
import '../../../models/onboarding_source.dart';
import '../../../services/varioqub_service.dart';

/// Результат решения о показе боевого онбординга.
class OnboardingVisibilityDecision {
  final bool showOnboarding;
  final OnboardingSource requestedSource;
  final OnboardingSource effectiveSource;
  final bool varioqubFallbackToServer;

  const OnboardingVisibilityDecision({
    required this.showOnboarding,
    required this.requestedSource,
    required this.effectiveSource,
    this.varioqubFallbackToServer = false,
  });
}

/// Определяет, показывать ли боевой онбординг, с учётом [onboardingSource].
class OnboardingVisibilityResolver {
  final VarioqubService _varioqubService;

  OnboardingVisibilityResolver({VarioqubService? varioqubService})
      : _varioqubService = varioqubService ?? VarioqubService();

  /// [settings] — `settings/general` с сервера или Firestore.
  Future<OnboardingVisibilityDecision> resolve(
    FirebaseSettings? settings,
  ) async {
    final serverShow = settings?.showOnboarding ?? false;
    final requestedSource =
        settings?.onboardingSource ?? OnboardingSource.server;

    // Master OFF: онбординг выключен независимо от источника.
    if (!serverShow) {
      if (kDebugMode) {
        debugPrint(
          'OnboardingVisibilityResolver: master OFF (server showOnboarding=false)',
        );
      }
      return OnboardingVisibilityDecision(
        showOnboarding: false,
        requestedSource: requestedSource,
        effectiveSource: OnboardingSource.server,
      );
    }

    if (requestedSource == OnboardingSource.server) {
      if (kDebugMode) {
        debugPrint(
          'OnboardingVisibilityResolver: source=server → show=true',
        );
      }
      return OnboardingVisibilityDecision(
        showOnboarding: true,
        requestedSource: requestedSource,
        effectiveSource: OnboardingSource.server,
      );
    }

    final varioqubShow = await _varioqubService.tryGetShowOnboarding();
    if (varioqubShow != null) {
      if (kDebugMode) {
        debugPrint(
          'OnboardingVisibilityResolver: source=varioqub → show=$varioqubShow',
        );
      }
      return OnboardingVisibilityDecision(
        showOnboarding: varioqubShow,
        requestedSource: requestedSource,
        effectiveSource: OnboardingSource.varioqub,
      );
    }

    if (kDebugMode) {
      debugPrint(
        'OnboardingVisibilityResolver: varioqub unavailable, fallback server '
        'showOnboarding=$serverShow',
      );
    }
    return OnboardingVisibilityDecision(
      showOnboarding: serverShow,
      requestedSource: requestedSource,
      effectiveSource: OnboardingSource.server,
      varioqubFallbackToServer: true,
    );
  }
}
