import 'onboarding_source.dart';

/// Модель настроек из Firebase Firestore
/// Коллекция: settings
/// Документ: general
class FirebaseSettings {
  final bool checkInternet;
  final bool checkLocation;
  final bool checkSIM;
  final bool checkVPN;
  final String location;
  final bool showOnboarding;

  /// Отправка телефона в LeadGid Universal API после финала онбординга.
  final bool leadGidAPI;

  /// Источник решения о показе онбординга: `server` | `varioqub`.
  final OnboardingSource onboardingSource;

  /// `true` — нативная витрина (LoansScreen), `false` — WebView по [showCaseLink].
  final bool nativeVitrina;

  /// URL веб-витрины, если [nativeVitrina] == false.
  final String showCaseLink;

  /// `true` — непропускаемый VpnBlockedScreen при VPN на iOS.
  /// `false` — только dismissible-попап, флоу не блокируется.
  final bool isShowVpnScreen;

  FirebaseSettings({
    required this.checkInternet,
    required this.checkLocation,
    required this.checkSIM,
    required this.checkVPN,
    required this.location,
    required this.showOnboarding,
    this.leadGidAPI = false,
    this.onboardingSource = OnboardingSource.server,
    this.nativeVitrina = true,
    this.showCaseLink = '',
    this.isShowVpnScreen = true,
  });

  /// Создание объекта из документа Firestore
  factory FirebaseSettings.fromFirestore(Map<String, dynamic> data) {
    return FirebaseSettings(
      checkInternet: data['checkInternet'] as bool? ?? false,
      checkLocation: data['checkLocation'] as bool? ?? false,
      checkSIM: data['checkSIM'] as bool? ?? false,
      checkVPN: data['checkVPN'] as bool? ?? false,
      location: data['location'] as String? ?? '',
      showOnboarding: data['showOnboarding'] as bool? ?? false,
      leadGidAPI: data['leadGidAPI'] as bool? ?? false,
      onboardingSource: OnboardingSource.fromSettingsValue(
        data['onboardingSource'] as String?,
      ),
      nativeVitrina: data['nativeVitrina'] as bool? ?? true,
      showCaseLink: data['showCaseLink'] as String? ?? '',
      isShowVpnScreen: data['isShowVpnScreen'] as bool? ?? true,
    );
  }

  /// Преобразование объекта в Map для Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'checkInternet': checkInternet,
      'checkLocation': checkLocation,
      'checkSIM': checkSIM,
      'checkVPN': checkVPN,
      'location': location,
      'showOnboarding': showOnboarding,
      'leadGidAPI': leadGidAPI,
      'onboardingSource': onboardingSource.settingsValue,
      'nativeVitrina': nativeVitrina,
      'showCaseLink': showCaseLink,
      'isShowVpnScreen': isShowVpnScreen,
    };
  }

  /// Вывод данных в лог
  void logData() {
    //print('=== Firebase Settings ===');
    //print('checkInternet: $checkInternet');
    //print('checkLocation: $checkLocation');
    //print('checkSIM: $checkSIM');
    //print('checkVPN: $checkVPN');
    //print('location: $location');
    //print('========================');
  }

  @override
  String toString() {
    return 'FirebaseSettings(checkInternet: $checkInternet, checkLocation: $checkLocation, checkSIM: $checkSIM, checkVPN: $checkVPN, location: $location, showOnboarding: $showOnboarding, leadGidAPI: $leadGidAPI, onboardingSource: ${onboardingSource.settingsValue}, nativeVitrina: $nativeVitrina, showCaseLink: $showCaseLink, isShowVpnScreen: $isShowVpnScreen)';
  }
}
