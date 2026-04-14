import 'package:flutter/material.dart';

import '../../../services/app_mode_service.dart';
import '../../../services/firebase_analytics_service.dart';
import '../../../views/home/main_screen.dart';
import '../../../views/loans/loans_screen.dart';
import '../services/combat_onboarding_local_state.dart';
import '../services/combat_onboarding_user_writer.dart';
import '../services/combat_settings_resolver.dart';
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
  final _userWriter = CombatOnboardingUserWriter();

  Widget? _resolved;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
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

    // combat
    if (!isFirstOpen) {
      if (!mounted) return;
      // Повторный запуск — show_case_onboarding_none не отправляем.
      setState(() => _resolved = const LoansScreen());
      return;
    }

    final settings = await _settingsResolver.resolveSettings();
    final showOnboarding = settings?.showOnboarding ?? false;

    if (!showOnboarding) {
      await _userWriter.writeNotShownIfFirstOpen(isFirstOpen: true);
      if (!mounted) return;
      setState(
        () => _resolved = const LoansScreen(
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

