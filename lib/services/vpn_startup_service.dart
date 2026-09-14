import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:vpn_detector/vpn_detector.dart';

/// Проверка VPN на iOS при старте приложения.
class VpnStartupService {
  VpnStartupService._();
  static final VpnStartupService instance = VpnStartupService._();

  /// Непропускаемый VpnBlockedScreen (iOS + VPN + isShowVpnScreen).
  bool iosVpnBlockedOnLaunch = false;

  /// Показать мягкий попап-предупреждение (VPN есть, но экран блокировки выключен).
  bool pendingVpnWarningPopup = false;

  /// Попап уже показали в этой сессии (чтобы не дублировать на MainScreen).
  bool vpnWarningPopupShown = false;

  Future<bool> checkIosVpnActive() async {
    if (!Platform.isIOS) {
      iosVpnBlockedOnLaunch = false;
      return false;
    }

    try {
      final active = await VpnDetector().isVpnActive();
      return active;
    } catch (e) {
      debugPrint('VpnStartupService: VPN check failed: $e');
      return false;
    }
  }

  /// Применяет политику [isShowVpnScreen] к факту активного VPN на iOS.
  void applyLaunchPolicy({
    required bool iosVpnActive,
    required bool isShowVpnScreen,
  }) {
    if (!iosVpnActive) {
      iosVpnBlockedOnLaunch = false;
      pendingVpnWarningPopup = false;
      return;
    }

    if (isShowVpnScreen) {
      iosVpnBlockedOnLaunch = true;
      pendingVpnWarningPopup = false;
      debugPrint(
        'VpnStartupService: VPN active → blocking screen (isShowVpnScreen=true)',
      );
    } else {
      iosVpnBlockedOnLaunch = false;
      pendingVpnWarningPopup = true;
      debugPrint(
        'VpnStartupService: VPN active → warning popup only (isShowVpnScreen=false)',
      );
    }
  }

  bool consumePendingVpnWarning() {
    if (!pendingVpnWarningPopup || vpnWarningPopupShown) return false;
    pendingVpnWarningPopup = false;
    vpnWarningPopupShown = true;
    return true;
  }
}
