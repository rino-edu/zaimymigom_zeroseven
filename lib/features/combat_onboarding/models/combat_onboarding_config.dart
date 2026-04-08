import 'combat_onboarding_theme.dart';

class CombatOnboardingStartConfig {
  final String title;
  final String body;
  final String primaryButtonText;
  final CombatOnboardingTheme theme;

  const CombatOnboardingStartConfig({
    required this.title,
    required this.body,
    required this.primaryButtonText,
    required this.theme,
  });
}

class CombatOnboardingQuestionPageConfig {
  final String docId;
  final int pageNumber;
  final String question;
  final List<String> options; // len 4

  const CombatOnboardingQuestionPageConfig({
    required this.docId,
    required this.pageNumber,
    required this.question,
    required this.options,
  });
}

class CombatOnboardingFinalConfig {
  final String title;
  final String body;
  final String primaryButtonText;
  final String consentText;

  const CombatOnboardingFinalConfig({
    required this.title,
    required this.body,
    required this.primaryButtonText,
    required this.consentText,
  });
}

class CombatOnboardingAnimationConfig {
  final String title;
  final int durationSeconds;

  const CombatOnboardingAnimationConfig({
    required this.title,
    required this.durationSeconds,
  });
}

class CombatOnboardingConfig {
  final CombatOnboardingStartConfig start;
  final List<CombatOnboardingQuestionPageConfig> pagesSorted;
  final CombatOnboardingFinalConfig finalStep;
  final CombatOnboardingAnimationConfig animation1;
  final CombatOnboardingAnimationConfig animation2;

  const CombatOnboardingConfig({
    required this.start,
    required this.pagesSorted,
    required this.finalStep,
    required this.animation1,
    required this.animation2,
  });

  int get totalPagesForLastOnbord => 1 + pagesSorted.length + 1;
}

