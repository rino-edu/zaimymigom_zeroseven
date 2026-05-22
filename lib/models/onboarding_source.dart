/// Источник решения о показе боевого онбординга.
enum OnboardingSource {
  /// `settings.showOnboarding` с сервера / Firestore.
  server,

  /// Флаг `showOnboarding` из Varioqub (строка `"true"` / `"false"`).
  varioqub;

  String get settingsValue => name;

  static OnboardingSource fromSettingsValue(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'varioqub':
        return OnboardingSource.varioqub;
      case 'server':
      default:
        return OnboardingSource.server;
    }
  }
}
