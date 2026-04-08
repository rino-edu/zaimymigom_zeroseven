import 'package:flutter/material.dart';

class CombatOnboardingTheme {
  final Color backgroundColor;
  final Color titleTextColor;
  final Color bodyTextColor;
  final Color primaryButtonBgColor;
  final Color primaryButtonTextColor;
  final Color optionButtonBgColor;

  const CombatOnboardingTheme({
    required this.backgroundColor,
    required this.titleTextColor,
    required this.bodyTextColor,
    required this.primaryButtonBgColor,
    required this.primaryButtonTextColor,
    required this.optionButtonBgColor,
  });

  static CombatOnboardingTheme defaults() {
    return const CombatOnboardingTheme(
      backgroundColor: Color(0xFFFFFFFF),
      titleTextColor: Color(0xFF111827),
      bodyTextColor: Color(0xFF374151),
      primaryButtonBgColor: Color(0xFF2563EB),
      primaryButtonTextColor: Color(0xFFFFFFFF),
      optionButtonBgColor: Color(0xFFF3F4F6),
    );
  }

  factory CombatOnboardingTheme.fromMap(Map<String, dynamic>? map) {
    final d = CombatOnboardingTheme.defaults();
    if (map == null) return d;

    return CombatOnboardingTheme(
      backgroundColor:
          _parseHexColor(map['backgroundColor']?.toString()) ?? d.backgroundColor,
      titleTextColor:
          _parseHexColor(map['titleTextColor']?.toString()) ?? d.titleTextColor,
      bodyTextColor:
          _parseHexColor(map['bodyTextColor']?.toString()) ?? d.bodyTextColor,
      primaryButtonBgColor: _parseHexColor(map['primaryButtonBgColor']?.toString()) ??
          d.primaryButtonBgColor,
      primaryButtonTextColor:
          _parseHexColor(map['primaryButtonTextColor']?.toString()) ??
              d.primaryButtonTextColor,
      optionButtonBgColor:
          _parseHexColor(map['optionButtonBgColor']?.toString()) ??
              d.optionButtonBgColor,
    );
  }

  static Color? _parseHexColor(String? raw) {
    if (raw == null) return null;
    var value = raw.trim();
    if (value.startsWith('#')) value = value.substring(1);
    if (value.length != 6) return null;
    final parsed = int.tryParse(value, radix: 16);
    if (parsed == null) return null;
    return Color(0xFF000000 | parsed);
  }
}

