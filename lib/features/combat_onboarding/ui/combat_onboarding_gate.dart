import 'package:flutter/material.dart';

import '../../../services/app_mode_service.dart';
import '../../../services/combat_showcase_analytics.dart';
import '../../../services/firebase_analytics_service.dart';
import '../../../views/home/main_screen.dart';
import '../../../views/loans/showcase_screen.dart';
import '../services/combat_onboarding_local_state.dart';
import '../services/combat_onboarding_user_writer.dart';
import '../services/combat_settings_resolver.dart';
import '../services/onboarding_visibility_resolver.dart';
import 'combat_onboarding_flow_screen.dart';

/// Решает, показывать ли боевой онбординг на старте.
class CombatOnboardingGate extends StatefulWidget {
  final AppMode appMode;

  const CombatOnboardingGate({super.key, required this.appMode});

  @override
  State<CombatOnboardingGate> createState() => _CombatOnboardingGateState();
}

class _CombatOnboardingGateState extends State<CombatOnboardingGate> {
  final _localState = CombatOnboardingLocalState();
  final _settingsResolver = CombatSettingsResolver();
  final _visibilityResolver = OnboardingVisibilityResolver();
  final _userWriter = CombatOnboardingUserWriter();

  Widget? _resolved;

  @override
  void initState() {
    super.initState();
    if (widget.appMode == AppMode.combat) {
      CombatShowcaseLifecycleObserver.instance.registerIfNeeded();
    }
    _resolve();
  }

  Future<void> _resolve() async {
    await _localState.syncInstallSession();

    if (widget.appMode == AppMode.combat) {
      await _localState.processOnboardingAbandonOnLaunch();
    }

    final isFirstOpen = await _localState.isFirstOpen();
    // фиксируем firstOpenDate как можно раньше
    if (isFirstOpen) {
      await _localState.getOrSetFirstOpenDate();
    }

    if (widget.appMode != AppMode.combat) {
      await _userWriter.writeNotShownIfFirstOpen(isFirstOpen: isFirstOpen);
      if (!mounted) return;
      setState(() => _resolved = const MainScreen());
      return;
    }

    // combat: онбординг только если его ещё не показывали (не привязано к первому запуску приложения).
    if (await _localState.wasOnboardingShown()) {
      if (!mounted) return;
      setState(() => _resolved = const ShowcaseScreen());
      return;
    }

    final settings = await _settingsResolver.resolveSettings();
    final visibility = await _visibilityResolver.resolve(settings);

    if (!visibility.showOnboarding) {
      await _userWriter.writeNotShownIfFirstOpen(isFirstOpen: isFirstOpen);
      if (!mounted) return;
      setState(
        () => _resolved = const ShowcaseScreen(
          showCaseOnboardingReason:
              CombatLoansShowCaseReason.withoutOnboarding,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _resolved = const CombatOnboardingFlowScreen());
  }

  @override
  Widget build(BuildContext context) {
    return _resolved ??
        const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
  }
}
