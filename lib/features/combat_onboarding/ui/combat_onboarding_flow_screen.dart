import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../services/firebase_analytics_service.dart';
import '../../../services/appmetrica_service.dart';
import '../../../views/loans/loans_screen.dart';
import '../models/combat_onboarding_config.dart';
import '../models/combat_onboarding_theme.dart';
import '../services/combat_onboarding_firestore_service.dart';
import '../services/combat_onboarding_local_state.dart';
import '../services/combat_onboarding_user_writer.dart';
import 'combat_onboarding_policy_screen.dart';
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
      _goLoans(
        showCaseReason: CombatLoansShowCaseReason.afterOnboardingClose,
      );
    }
  }

  void _goLoans({CombatLoansShowCaseReason? showCaseReason}) {
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
      _goLoans(
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

    _goLoans(
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

    final total = cfg.totalPagesForLastOnbord;
    final last = '$total/$total';
    debugPrint('CombatOnboarding: final continue pressed, last=$last');

    // Экран 1
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CombatOnboardingLoadingScreen(
          title: cfg.animation1.title,
          durationSeconds: cfg.animation1.durationSeconds,
          theme: cfg.start.theme,
          onDone: (loadingCtx) {
            debugPrint('CombatOnboarding: animation1 done, push animation2');
            // Экран 2
            Navigator.of(loadingCtx).pushReplacement(
              MaterialPageRoute(
                builder: (_) => CombatOnboardingLoadingScreen(
                  title: cfg.animation2.title,
                  durationSeconds: cfg.animation2.durationSeconds,
                  theme: cfg.start.theme,
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
      // минимальный лоадер на время запроса
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final total = cfg.totalPagesForLastOnbord;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: cfg.start.theme.backgroundColor,
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
                        color: cfg.start.theme.titleTextColor,
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
                      theme: cfg.start.theme,
                      onContinue: _onStartContinue,
                    ),
                    for (final page in cfg.pagesSorted)
                      _QuestionPage(
                        question: page.question,
                        options: page.options,
                        theme: cfg.start.theme,
                        onSelected: (opt) => _onOptionSelected(page, opt),
                      ),
                    _FinalPage(
                      title: cfg.finalStep.title,
                      body: cfg.finalStep.body,
                      buttonText: cfg.finalStep.primaryButtonText,
                      consentText: cfg.finalStep.consentText,
                      theme: cfg.start.theme,
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
                    dotColor:
                        cfg.start.theme.bodyTextColor.withValues(alpha: 0.25),
                    activeDotColor: cfg.start.theme.primaryButtonBgColor,
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
  final String title;
  final String body;
  final String buttonText;
  final String consentText;
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CombatOnboardingPolicyScreen(),
      ),
    );
  }

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
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              labelText: 'Телефон',
              errorText: phoneErrorText,
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: consentChecked,
            onChanged: (v) => onConsentChanged(v ?? false),
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