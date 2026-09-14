import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../services/app_mode_service.dart';
import '../../services/appmetrica_service.dart';
import '../../services/vpn_startup_service.dart';
import '../../utils/locale_keys.dart';
import '../app_mode_wrapper.dart';
import 'vpn_blocked_screen.dart';

/// Гейт старта: на iOS при isShowVpnScreen блокирует приложение при активном VPN,
/// иначе пропускает флоу и показывает мягкий попап-предупреждение.
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
    if (!_vpnBlocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeShowVpnWarningPopup();
      });
    }
  }

  void _maybeShowVpnWarningPopup() {
    if (!mounted) return;
    if (!VpnStartupService.instance.consumePendingVpnWarning()) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          title: Text(LocaleKeys.vpnDialogTitle.tr()),
          content: Text(LocaleKeys.vpnDialogDescription.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(LocaleKeys.vpnDialogOk.tr()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    try {
      final stillActive = await VpnStartupService.instance.checkIosVpnActive();
      if (stillActive) return;

      VpnStartupService.instance.iosVpnBlockedOnLaunch = false;

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
