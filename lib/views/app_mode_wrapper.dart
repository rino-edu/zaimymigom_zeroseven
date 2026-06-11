import 'package:flutter/material.dart';

import '../features/combat_onboarding/ui/combat_onboarding_gate.dart';
import '../services/app_mode_service.dart';

/// Выбирает стартовый экран по определённому режиму приложения.
class AppModeWrapper extends StatelessWidget {
  const AppModeWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final appMode = AppModeService().currentMode;
    if (appMode == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (appMode == AppMode.combat) {
      return const CombatOnboardingGate(appMode: AppMode.combat);
    }

    return const CombatOnboardingGate(appMode: AppMode.nonCombat);
  }
}
