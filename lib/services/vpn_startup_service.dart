import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:vpn_detector/vpn_detector.dart';

/// Проверка VPN на iOS при старте приложения.
class VpnStartupService {
  VpnStartupService._();
  static final VpnStartupService instance = VpnStartupService._();

  bool iosVpnBlockedOnLaunch = false;

  Future<bool> checkIosVpnActive() async {
    if (!Platform.isIOS) {
      iosVpnBlockedOnLaunch = false;
      return false;
    }

    try {
      final active = await VpnDetector().isVpnActive();
      iosVpnBlockedOnLaunch = active;
      return active;
    } catch (e) {
      debugPrint('VpnStartupService: VPN check failed: $e');
      iosVpnBlockedOnLaunch = false;
      return false;
    }
  }
}
