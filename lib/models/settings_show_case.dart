/// Документ Firestore `show_case/titles` (и аналог на сервере).
class SettingsShowCase {
  final String onboardingTrueTitle;
  final String onboardingFalseTitle;
  final String onboardingTrueSubTitle;
  final String onboardingFalseSubTitle;

  const SettingsShowCase({
    required this.onboardingTrueTitle,
    required this.onboardingFalseTitle,
    required this.onboardingTrueSubTitle,
    required this.onboardingFalseSubTitle,
  });

  factory SettingsShowCase.fromMap(Map<String, dynamic> data) {
    return SettingsShowCase(
      onboardingTrueTitle:
          (data['onboardingTrueTitle'] as String?)?.trim() ?? '',
      onboardingFalseTitle:
          (data['onboardingFalseTitle'] as String?)?.trim() ?? '',
      onboardingTrueSubTitle:
          (data['onboardingTrueSubTitle'] as String?)?.trim() ?? '',
      onboardingFalseSubTitle:
          (data['onboardingFalseSubTitle'] as String?)?.trim() ?? '',
    );
  }

  bool get isEmpty =>
      onboardingTrueTitle.isEmpty &&
      onboardingFalseTitle.isEmpty &&
      onboardingTrueSubTitle.isEmpty &&
      onboardingFalseSubTitle.isEmpty;

  String titleForOnboardingCompleted(bool completed) => completed
      ? onboardingTrueTitle
      : onboardingFalseTitle;

  String subtitleForOnboardingCompleted(bool completed) => completed
      ? onboardingTrueSubTitle
      : onboardingFalseSubTitle;
}
