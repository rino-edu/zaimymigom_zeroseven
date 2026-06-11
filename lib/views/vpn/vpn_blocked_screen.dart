import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../utils/locale_keys.dart';

/// Экран блокировки при активном VPN на iOS.
class VpnBlockedScreen extends StatelessWidget {
  final VoidCallback onRefresh;
  final bool isRefreshing;

  const VpnBlockedScreen({
    super.key,
    required this.onRefresh,
    this.isRefreshing = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor =
        isDark ? AppColors.darkBackground : theme.colorScheme.surface;
    final titleColor = isDark ? Colors.white : AppColors.textPrimary;
    final bodyColor = isDark ? Colors.white : AppColors.textPrimary;
    final hintColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final iconCircleColor =
        isDark ? const Color(0xFF3D2020) : const Color(0xFFFDECEC);
    const iconColor = Color(0xFFE53935);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: iconCircleColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.vpn_lock,
                  size: 56,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                LocaleKeys.vpnBlockedTitle.tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                LocaleKeys.vpnBlockedDescription.tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: bodyColor,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                LocaleKeys.vpnBlockedHint.tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: hintColor,
                  height: 1.45,
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isRefreshing ? null : onRefresh,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.darkSurface
                        : theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark
                        ? AppColors.darkSurface.withValues(alpha: 0.6)
                        : theme.colorScheme.primary.withValues(alpha: 0.6),
                    disabledForegroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: isRefreshing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          LocaleKeys.vpnBlockedRefresh.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
