/// Модель настроек из Firebase Firestore
/// Коллекция: settings
/// Документ: general
class FirebaseSettings {
  final bool checkInternet;
  final bool checkLocation;
  final bool checkSIM;
  final bool checkVPN;
  final String location;
  final String? appbarTitle;
  final String? appbarTitleRu;
  final String? appbarTitleEn;
  final String? showcaseTitle;
  final String? showcaseTitleRu;
  final String? showcaseTitleEn;
  final bool hideBanner;

  FirebaseSettings({
    required this.checkInternet,
    required this.checkLocation,
    required this.checkSIM,
    required this.checkVPN,
    required this.location,
    this.appbarTitle,
    this.appbarTitleRu,
    this.appbarTitleEn,
    this.showcaseTitle,
    this.showcaseTitleRu,
    this.showcaseTitleEn,
    this.hideBanner = false,
  });

  /// Создание объекта из документа Firestore
  factory FirebaseSettings.fromFirestore(Map<String, dynamic> data) {
    return FirebaseSettings(
      checkInternet: data['checkInternet'] as bool? ?? false,
      checkLocation: data['checkLocation'] as bool? ?? false,
      checkSIM: data['checkSIM'] as bool? ?? false,
      checkVPN: data['checkVPN'] as bool? ?? false,
      location: data['location'] as String? ?? '',
      appbarTitle: data['appbar_title'] as String?,
      appbarTitleRu: data['appbar_title_ru'] as String?,
      appbarTitleEn: data['appbar_title_en'] as String?,
      showcaseTitle:
          data['showcase_title'] as String? ??
          data['showcase_titles'] as String?,
      showcaseTitleRu: data['showcase_title_ru'] as String?,
      showcaseTitleEn: data['showcase_title_en'] as String?,
      hideBanner: data['hide_banner'] as bool? ?? false,
    );
  }

  /// Заголовок AppBar для текущего языка: appbar_title_[lang] или appbar_title
  String getAppbarTitleForLocale(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'ru':
        return (appbarTitleRu ?? appbarTitle ?? '').trim();
      case 'en':
        return (appbarTitleEn ?? appbarTitle ?? '').trim();
      default:
        return (appbarTitle ?? '').trim();
    }
  }

  /// Заголовок баннера (showcase) для текущего языка
  String getShowcaseTitleForLocale(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'ru':
        return (showcaseTitleRu ?? showcaseTitle ?? '').trim();
      case 'en':
        return (showcaseTitleEn ?? showcaseTitle ?? '').trim();
      default:
        return (showcaseTitle ?? '').trim();
    }
  }

  /// Преобразование объекта в Map для Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'checkInternet': checkInternet,
      'checkLocation': checkLocation,
      'checkSIM': checkSIM,
      'checkVPN': checkVPN,
      'location': location,
      if (appbarTitle != null) 'appbar_title': appbarTitle,
      if (appbarTitleRu != null) 'appbar_title_ru': appbarTitleRu,
      if (appbarTitleEn != null) 'appbar_title_en': appbarTitleEn,
      if (showcaseTitle != null) 'showcase_title': showcaseTitle,
      if (showcaseTitleRu != null) 'showcase_title_ru': showcaseTitleRu,
      if (showcaseTitleEn != null) 'showcase_title_en': showcaseTitleEn,
      'hide_banner': hideBanner,
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
    return 'FirebaseSettings(checkInternet: $checkInternet, checkLocation: $checkLocation, checkSIM: $checkSIM, checkVPN: $checkVPN, location: $location)';
  }
}
