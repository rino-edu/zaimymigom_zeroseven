import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../constants/app_colors.dart';
import '../../../services/combat_showcase_analytics.dart';
import '../../../services/firebase_analytics_service.dart';
import '../../../services/appmetrica_service.dart';
import '../../../views/loans/loans_screen.dart';
import '../models/combat_onboarding_config.dart';
import '../models/combat_onboarding_theme.dart';
import '../services/combat_onboarding_firestore_service.dart';
import '../services/combat_onboarding_local_state.dart';
import '../services/combat_onboarding_user_writer.dart';
import '../services/combat_settings_resolver.dart';
import '../services/leadgid_application_api_service.dart';
import 'combat_onboarding_consent_webview_screen.dart';
import 'combat_onboarding_loading_screen.dart';


class CombatOnboardingFlowScreen extends StatefulWidget {
  const CombatOnboardingFlowScreen({super.key});

  @override
  State<CombatOnboardingFlowScreen> createState() =>
      _CombatOnboardingFlowScreenState();
}

class _CombatOnboardingFlowScreenState extends State<CombatOnboardingFlowScreen> {
  final _pageController = PageController();
  final _firestoreService = CombatOnboardingFirestoreService();
  final _userWriter = CombatOnboardingUserWriter();
  final _settingsResolver = CombatSettingsResolver();
  final _leadgidApi = LeadgidApplicationApiService();

  CombatOnboardingConfig? _config;

  bool _loggedOnboardingShow = false;
  int _currentIndex = 0;
  final Map<String, String> _answers = {};

  final _phoneController = TextEditingController(text: '+7');
  final _phoneFocusNode = FocusNode();
  String? _phoneErrorText;
  bool _consentChecked = false;
  bool _phoneValid = false;

  @override
  void initState() {
    super.initState();
    _load();
    _phoneController.addListener(_onPhoneChanged);
    _phoneFocusNode.addListener(_onPhoneFocusChanged);
  }

  @override
  void dispose() {
    _phoneController
      ..removeListener(_onPhoneChanged)
      ..dispose();
    _phoneFocusNode
      ..removeListener(_onPhoneFocusChanged)
      ..dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final cfg = await _firestoreService.fetchConfigWithOneRetry();
      if (!mounted) return;
      setState(() {
        _config = cfg;
      });
      _logOnboardingShowOnce();
    } catch (e) {
      if (!mounted) return;
      // После 1 ретрая (уже внутри fetchConfigWithOneRetry) — уходим на LoansScreen.
      await _goLoans(
        showCaseReason: CombatLoansShowCaseReason.afterOnboardingClose,
      );
    }
  }

  Future<void> _goLoans({CombatLoansShowCaseReason? showCaseReason}) async {
    if (!mounted) return;
    await CombatOnboardingLocalState().endOnboardingFlow();
    CombatShowcaseSession.markLoansScreenOpenedCombat();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LoansScreen(showCaseOnboardingReason: showCaseReason),
      ),
    );
  }

  void _logOnboardingShowOnce() {
    if (_loggedOnboardingShow) return;
    _loggedOnboardingShow = true;
    unawaited(CombatOnboardingLocalState().setOnboardingWasShown());
    CombatShowcaseSession.markOnboardingShowLogged();
    FirebaseAnalyticsService.logOnboardingShow();
    AppMetricaService.reportEvent('onboarding_show');
  }

  void _onPhoneChanged() {
    final text = _phoneController.text;
    if (!text.startsWith('+7')) {
      // Принудительно держим префикс +7
      final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
      final rest = digits.startsWith('7') ? digits.substring(1) : digits;
      final next = '+7$rest';
      _phoneController.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
      return;
    }

    final normalized = _normalizeRuPhone(text);
    final isValid = normalized != null;
    if (_phoneValid != isValid) {
      setState(() {
        _phoneValid = isValid;
      });
    }

    // Если номер стал валидным — убираем ошибку сразу.
    if (isValid && _phoneErrorText != null) {
      setState(() {
        _phoneErrorText = null;
      });
    }
  }

  void _onPhoneFocusChanged() {
    if (_phoneFocusNode.hasFocus) return;

    final text = _phoneController.text.trim();
    // Пустой/только +7 — не считаем ошибкой, просто не даём продолжить.
    if (text.isEmpty || text == '+7') {
      if (_phoneErrorText != null) {
        setState(() => _phoneErrorText = null);
      }
      return;
    }

    final error = _ruPhoneValidationError(text);
    if (_phoneErrorText != error) {
      setState(() => _phoneErrorText = error);
    }
  }

  String? _normalizeRuPhone(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    // Ожидаем 11 цифр, начиная с 7.
    if (digits.length != 11) return null;
    if (!digits.startsWith('7')) return null;
    return '+$digits';
  }

  String? _ruPhoneValidationError(String input) {
    if (!input.startsWith('+7')) {
      return 'Номер телефона должен начинаться с +7';
    }
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (!digits.startsWith('7')) {
      return 'Номер телефона должен быть российским (+7)';
    }
    if (digits.length < 11) {
      return 'Введите номер полностью: должно быть 11 цифр';
    }
    if (digits.length > 11) {
      return 'Слишком длинный номер: должно быть 11 цифр';
    }
    return null;
  }

  bool get _isFinalPage {
    final cfg = _config;
    if (cfg == null) return false;
    return _currentIndex == cfg.totalPagesForLastOnbord - 1;
  }

  Future<void> _closeOnboarding() async {
    final cfg = _config;
    if (cfg == null) {
      await _goLoans(
        showCaseReason: CombatLoansShowCaseReason.afterOnboardingClose,
      );
      return;
    }

    final analyticsPageNumber = _currentIndex + 1;
    await FirebaseAnalyticsService.logOnboardingClose(
      pageNumber: analyticsPageNumber,
    );
    await AppMetricaService.reportEvent(
      'onboarding_close',
      parameters: {'page_number': analyticsPageNumber},
    );

    final current = _currentIndex + 1;
    final total = cfg.totalPagesForLastOnbord;
    final last = '$current/$total';

    String? phoneToWrite;
    if (_isFinalPage && _consentChecked) {
      phoneToWrite = _normalizeRuPhone(_phoneController.text);
    }

    await _userWriter.writeResult(
      endOnbord: false,
      lastOnbordpage: last,
      answersOnbord: Map<String, String>.from(_answers),
      phone: phoneToWrite,
    );

    await _goLoans(
      showCaseReason: CombatLoansShowCaseReason.afterOnboardingClose,
    );
  }

  void _onStartContinue() {
    FirebaseAnalyticsService.logOnboardingStart();
    AppMetricaService.reportEvent('onboarding_start');
    _next();
  }

  void _next() {
    final cfg = _config;
    if (cfg == null) return;

    final total = cfg.totalPagesForLastOnbord;
    final nextIndex = (_currentIndex + 1).clamp(0, total - 1);
    _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _onOptionSelected(CombatOnboardingQuestionPageConfig page, String option) {
    final qa =
        'вопрос на экране(${page.question}): $option';
    FirebaseAnalyticsService.logOnboardingPageAnswer(
      pageNumber: page.pageNumber,
      questionAnswer: qa,
    );
    AppMetricaService.reportEvent(
      'onboarding_page_${page.pageNumber}',
      parameters: {'question_answer': qa},
    );
    setState(() {
      _answers[page.question] = option;
    });
    _next();
  }

  Future<void> _onFinalContinue() async {
    final cfg = _config;
    if (cfg == null) return;

    final phone = _normalizeRuPhone(_phoneController.text);
    if (phone == null) return;
    if (!_consentChecked) return;

    FirebaseAnalyticsService.logOnboardingFinish();
    AppMetricaService.reportEvent('onboarding_finish');
    await CombatOnboardingLocalState().clearOnboardingAbandoned();

    final total = cfg.totalPagesForLastOnbord;
    final last = '$total/$total';
    debugPrint('CombatOnboarding: final continue pressed, last=$last');

    try {
      await _userWriter.writeResult(
        endOnbord: false,
        lastOnbordpage: last,
        answersOnbord: Map<String, String>.from(_answers),
        phone: phone,
      );
      final settings = await _settingsResolver.resolveSettings();
      final leadGidEnabled = settings?.leadGidAPI ?? false;
      await _leadgidApi.createApplicationFromNormalizedPhone(
        phone,
        enabled: leadGidEnabled,
      );
    } catch (e, st) {
      debugPrint('CombatOnboarding: writeResult/LeadGid on final FAILED: $e');
      debugPrint('$st');
    }

    // Экран 1
    if (!mounted) return;
    final flowTheme = cfg.start.theme.forFlowBrightness(context);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CombatOnboardingLoadingScreen(
          title: cfg.animation1.title,
          durationSeconds: cfg.animation1.durationSeconds,
          theme: flowTheme,
          onDone: (loadingCtx) {
            debugPrint('CombatOnboarding: animation1 done, push animation2');
            // Экран 2
            Navigator.of(loadingCtx).pushReplacement(
              MaterialPageRoute(
                builder: (_) => CombatOnboardingLoadingScreen(
                  title: cfg.animation2.title,
                  durationSeconds: cfg.animation2.durationSeconds,
                  theme: flowTheme,
                  onDone: (loading2Ctx) async {
                    debugPrint('CombatOnboarding: animation2 done, writeResult...');
                    try {
                      await _userWriter.writeResult(
                        endOnbord: true,
                        lastOnbordpage: last,
                        answersOnbord: Map<String, String>.from(_answers),
                        phone: phone,
                      );
                      await CombatOnboardingLocalState()
                          .setCombatOnboardingFullyCompleted();
                      debugPrint('CombatOnboarding: writeResult ok, go LoansScreen');
                    } catch (e, st) {
                      debugPrint('CombatOnboarding: writeResult FAILED: $e');
                      debugPrint('$st');
                      // Даже при ошибке записи не держим пользователя на лоадере
                      debugPrint('CombatOnboarding: go LoansScreen despite error');
                    }

                    if (!loading2Ctx.mounted) return;
                    await CombatOnboardingLocalState().endOnboardingFlow();
                    CombatShowcaseSession.markLoansScreenOpenedCombat();
                    if (!loading2Ctx.mounted) return;
                    Navigator.of(loading2Ctx).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const LoansScreen(
                          showCaseOnboardingReason:
                              CombatLoansShowCaseReason.afterOnboardingFinish,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _config;
    if (cfg == null) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : Theme.of(context).colorScheme.surface,
        body: Center(
          child: CircularProgressIndicator(
            color: isDark ? Colors.white : null,
          ),
        ),
      );
    }

    final flowTheme = cfg.start.theme.forFlowBrightness(context);
    final total = cfg.totalPagesForLastOnbord;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: flowTheme.backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: _closeOnboarding,
                      icon: Icon(
                        Icons.close,
                        color: flowTheme.titleTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentIndex = i),
                  children: [
                    _StartPage(
                      title: cfg.start.title,
                      body: cfg.start.body,
                      buttonText: cfg.start.primaryButtonText,
                      theme: flowTheme,
                      onContinue: _onStartContinue,
                    ),
                    for (final page in cfg.pagesSorted)
                      _QuestionPage(
                        question: page.question,
                        options: page.options,
                        theme: flowTheme,
                        onSelected: (opt) => _onOptionSelected(page, opt),
                      ),
                    _FinalPage(
                      title: cfg.finalStep.title,
                      body: cfg.finalStep.body,
                      buttonText: cfg.finalStep.primaryButtonText,
                      consentText: cfg.finalStep.consentText,
                      consentLink: cfg.finalStep.consentLink,
                      theme: flowTheme,
                      phoneController: _phoneController,
                      phoneFocusNode: _phoneFocusNode,
                      phoneErrorText: _phoneErrorText,
                      consentChecked: _consentChecked,
                      onConsentChanged: (v) => setState(() => _consentChecked = v),
                      canContinue: _phoneValid && _consentChecked,
                      onContinue: _onFinalContinue,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: total,
                  effect: WormEffect(
                    dotColor: flowTheme.bodyTextColor.withValues(alpha: 0.25),
                    activeDotColor: flowTheme.primaryButtonBgColor,
                    dotHeight: 8,
                    dotWidth: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _StartPage extends StatelessWidget {
  final String title;
  final String body;
  final String buttonText;
  final CombatOnboardingTheme theme;
  final VoidCallback onContinue;

  const _StartPage({
    required this.title,
    required this.body,
    required this.buttonText,
    required this.theme,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: theme.titleTextColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: theme.bodyTextColor,
                ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryButtonBgColor,
                foregroundColor: theme.primaryButtonTextColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onContinue,
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }
}


class _QuestionPage extends StatelessWidget {
  final String question;
  final List<String> options;
  final CombatOnboardingTheme theme;
  final ValueChanged<String> onSelected;

  const _QuestionPage({
    required this.question,
    required this.options,
    required this.theme,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            question,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: theme.titleTextColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 24),
          for (final opt in options) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryButtonBgColor,
                  foregroundColor: theme.primaryButtonTextColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: () => onSelected(opt),
                child: Text(opt, textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}


class _FinalPage extends StatelessWidget {
  static const String defaultConsentUrl =
      'https://baiterek-mfo.com/personaldata';

  final String title;
  final String body;
  final String buttonText;
  final String consentText;
  final String consentLink;
  final CombatOnboardingTheme theme;
  final TextEditingController phoneController;
  final FocusNode phoneFocusNode;
  final String? phoneErrorText;
  final bool consentChecked;
  final ValueChanged<bool> onConsentChanged;
  final bool canContinue;
  final VoidCallback onContinue;

  const _FinalPage({
    required this.title,
    required this.body,
    required this.buttonText,
    required this.consentText,
    required this.consentLink,
    required this.theme,
    required this.phoneController,
    required this.phoneFocusNode,
    required this.phoneErrorText,
    required this.consentChecked,
    required this.onConsentChanged,
    required this.canContinue,
    required this.onContinue,
  });

  void _openPolicy(BuildContext context) {
    final url = consentLink.trim().isNotEmpty ? consentLink.trim() : defaultConsentUrl;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CombatOnboardingConsentWebViewScreen(url: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: theme.titleTextColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: theme.bodyTextColor,
                ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: phoneController,
            focusNode: phoneFocusNode,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: isDark ? Colors.white : null),
            cursorColor: isDark ? Colors.white : null,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? Colors.white38 : Theme.of(context).dividerColor,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? Colors.white38 : Theme.of(context).dividerColor,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? Colors.white : Theme.of(context).colorScheme.primary,
                  width: isDark ? 1.5 : 1,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              labelText: 'Телефон',
              labelStyle: TextStyle(color: isDark ? Colors.white70 : null),
              errorText: phoneErrorText,
              errorStyle: TextStyle(
                color: isDark ? const Color(0xFFFF8A80) : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: consentChecked,
            onChanged: (v) => onConsentChanged(v ?? false),
            checkColor: isDark ? AppColors.darkBackground : null,
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return isDark ? Colors.white : null;
              }
              return isDark ? Colors.transparent : null;
            }),
            side: isDark
                ? const BorderSide(color: Colors.white54, width: 1.5)
                : null,
            title: InkWell(
              onTap: () => _openPolicy(context),
              child: Text(
                consentText,
                style: TextStyle(
                  color: theme.bodyTextColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryButtonBgColor,
                foregroundColor: theme.primaryButtonTextColor,
                disabledBackgroundColor: isDark
                    ? theme.primaryButtonBgColor.withValues(alpha: 0.45)
                    : null,
                disabledForegroundColor:
                    isDark ? Colors.white54 : null,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: canContinue ? onContinue : null,
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }
}

extension _CombatOnboardingFlowTheme on CombatOnboardingTheme {
  CombatOnboardingTheme forFlowBrightness(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.light) {
      return this;
    }

    return const CombatOnboardingTheme(
      backgroundColor: AppColors.darkBackground,
      titleTextColor: Colors.white,
      bodyTextColor: Colors.white,
      primaryButtonBgColor: AppColors.darkSurface,
      primaryButtonTextColor: Colors.white,
      optionButtonBgColor: AppColors.darkSurface,
    );
  }
}