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

  FirebaseSettings({
    required this.checkInternet,
    required this.checkLocation,
    required this.checkSIM,
    required this.checkVPN,
    required this.location,
    required this.showOnboarding,
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
    return 'FirebaseSettings(checkInternet: $checkInternet, checkLocation: $checkLocation, checkSIM: $checkSIM, checkVPN: $checkVPN, location: $location, showOnboarding: $showOnboarding)';
  }
}
