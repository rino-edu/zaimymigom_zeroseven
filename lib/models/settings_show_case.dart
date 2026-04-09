/// Документ Firestore `settings/show_case` (и аналог на сервере).
class SettingsShowCase {
  final String onboardingTrueTitle;
  final String onboardingFalseTitle;

  const SettingsShowCase({
    required this.onboardingTrueTitle,
    required this.onboardingFalseTitle,
  });

  factory SettingsShowCase.fromMap(Map<String, dynamic> data) {
    return SettingsShowCase(
      onboardingTrueTitle:
          (data['onboardingTrueTitle'] as String?)?.trim() ?? '',
      onboardingFalseTitle:
          (data['onboardingFalseTitle'] as String?)?.trim() ?? '',
    );
  }

  bool get isEmpty =>
      onboardingTrueTitle.isEmpty && onboardingFalseTitle.isEmpty;
}
