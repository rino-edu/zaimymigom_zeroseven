import 'dart:async';

import 'package:flutter/material.dart';

import '../models/combat_onboarding_theme.dart';

class CombatOnboardingLoadingScreen extends StatefulWidget {
  final String title;
  final int durationSeconds;
  final CombatOnboardingTheme theme;
  final void Function(BuildContext context) onDone;

  const CombatOnboardingLoadingScreen({
    super.key,
    required this.title,
    required this.durationSeconds,
    required this.theme,
    required this.onDone,
  });

  @override
  State<CombatOnboardingLoadingScreen> createState() =>
      _CombatOnboardingLoadingScreenState();
}

class _CombatOnboardingLoadingScreenState
    extends State<CombatOnboardingLoadingScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final seconds = widget.durationSeconds <= 0 ? 1 : widget.durationSeconds;
    debugPrint(
      'CombatOnboardingLoadingScreen: init title="${widget.title}" durationSeconds=$seconds',
    );
    _timer = Timer(Duration(seconds: seconds), () {
      if (!mounted) return;
      debugPrint(
        'CombatOnboardingLoadingScreen: done title="${widget.title}"',
      );
      widget.onDone(context);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: widget.theme.backgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: widget.theme.titleTextColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 24),
                  CircularProgressIndicator(
                    color: widget.theme.primaryButtonBgColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

