import 'package:flutter/material.dart';

import '../../services/app_mode_service.dart';
import '../../services/appmetrica_service.dart';
import '../../services/vpn_startup_service.dart';
import '../app_mode_wrapper.dart';
import 'vpn_blocked_screen.dart';

/// Гейт старта: на iOS блокирует приложение при активном VPN.
class AppStartupGate extends StatefulWidget {
  const AppStartupGate({super.key});

  @override
  State<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<AppStartupGate> {
  late bool _vpnBlocked;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _vpnBlocked = VpnStartupService.instance.iosVpnBlockedOnLaunch;
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    try {
      final stillActive = await VpnStartupService.instance.checkIosVpnActive();
      if (stillActive) return;

      final appModeService = AppModeService();
      appModeService.resetMode();
      await appModeService.determineAppMode();
      await AppMetricaService.reportVpnStatusOnLaunch();

      if (!mounted) return;
      setState(() => _vpnBlocked = false);
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_vpnBlocked) {
      return VpnBlockedScreen(
        onRefresh: _onRefresh,
        isRefreshing: _isRefreshing,
      );
    }

    return const AppModeWrapper();
  }
}
