import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/combat_onboarding/services/combat_settings_resolver.dart';
import '../../services/app_mode_service.dart';
import '../../services/appmetrica_service.dart';
import '../../services/combat_showcase_analytics.dart';
import '../../services/firebase_analytics_service.dart';
import '../../services/web_link_service.dart';
import 'loans_screen.dart';
import '../webview/webview_screen.dart';

/// Точка входа витрины: нативная ([LoansScreen]) или веб ([WebViewScreen])
/// в зависимости от `nativeVitrina` / `showCaseLink` из settings.
class ShowcaseScreen extends StatefulWidget {
  final bool withScaffold;

  /// Если задан — логируем `show_case_onboarding_*` и пишем aff_sub10.
  final CombatLoansShowCaseReason? showCaseOnboardingReason;

  /// WebView без AppBar (вкладка MainScreen уже даёт свой AppBar).
  final bool embedInParent;

  const ShowcaseScreen({
    super.key,
    this.withScaffold = true,
    this.showCaseOnboardingReason,
    this.embedInParent = false,
  });

  @override
  State<ShowcaseScreen> createState() => _ShowcaseScreenState();
}

class _ShowcaseScreenState extends State<ShowcaseScreen> {
  final _settingsResolver = CombatSettingsResolver();
  final _webLinkService = WebLinkService();
  final _appModeService = AppModeService();

  Widget? _resolved;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _saveOnboardingReason(CombatLoansShowCaseReason reason) async {
    final String sub10Value;
    switch (reason) {
      case CombatLoansShowCaseReason.afterOnboardingFinish:
        sub10Value = 'onboarding_finish';
      case CombatLoansShowCaseReason.afterOnboardingClose:
        sub10Value = 'onboarding_close';
      case CombatLoansShowCaseReason.withoutOnboarding:
        sub10Value = 'onboarding_none';
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(WebLinkService.prefSub10Key, sub10Value);
      debugPrint('ShowcaseScreen: Сохранён aff_sub10=$sub10Value');
    } catch (e) {
      debugPrint('ShowcaseScreen: Ошибка при сохранении aff_sub10: $e');
    }
  }

  void _reportShowCaseAnalytics(CombatLoansShowCaseReason reason) {
    FirebaseAnalyticsService.logLoansShowCaseIfNeeded(reason);
    switch (reason) {
      case CombatLoansShowCaseReason.afterOnboardingFinish:
        AppMetricaService.reportEvent('show_case_onboarding_finish');
      case CombatLoansShowCaseReason.afterOnboardingClose:
        AppMetricaService.reportEvent('show_case_onboarding_close');
      case CombatLoansShowCaseReason.withoutOnboarding:
        AppMetricaService.reportEvent('show_case_onboarding_none');
    }
  }

  Future<void> _resolve() async {
    final isCombat = _appModeService.currentMode == AppMode.combat;
    final showCaseReason = widget.showCaseOnboardingReason;

    final settings = await _settingsResolver.resolveSettings();
    final useNative = settings?.nativeVitrina ?? true;

    debugPrint(
      'ShowcaseScreen: nativeVitrina=$useNative, '
      'showCaseLink=${settings?.showCaseLink}',
    );

    if (!mounted) return;

    if (useNative) {
      setState(() {
        _resolved = LoansScreen(
          withScaffold: widget.withScaffold,
          showCaseOnboardingReason: widget.showCaseOnboardingReason,
        );
      });
      return;
    }

    // Веб-витрина: aff_sub10 до модификации ссылки
    if (showCaseReason != null) {
      await _saveOnboardingReason(showCaseReason);
      _reportShowCaseAnalytics(showCaseReason);
    }

    if (isCombat) {
      CombatShowcaseSession.markLoansScreenOpenedCombat();
    }

    final url = await _webLinkService.generateModifiedShowCaseLink(
      settings?.showCaseLink,
    );

    if (isCombat) {
      CombatShowcaseAnalytics.reportShown();
      AppMetricaService.reportScreen('loans_combat_mode_webview');
    } else {
      AppMetricaService.reportScreen('loans_non_combat_mode_webview');
    }

    if (!mounted) return;

    final offer = WebViewScreen.showcasePlaceholderOffer(link: url);
    setState(() {
      _resolved = WebViewScreen(
        offer: offer,
        url_link: url,
        isRootShowcase: !widget.embedInParent,
        withAppBar: !widget.embedInParent,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return _resolved ??
        const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
  }
}
