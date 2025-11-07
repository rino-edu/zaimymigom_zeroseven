/// Модель настроек из Firebase Firestore
/// Коллекция: settings
/// Документ: general
class FirebaseSettings {
  final bool checkInternet;
  final bool checkLocation;
  final bool checkSIM;
  final bool checkVPN;
  final String location;

  FirebaseSettings({
    required this.checkInternet,
    required this.checkLocation,
    required this.checkSIM,
    required this.checkVPN,
    required this.location,
  });

  /// Создание объекта из документа Firestore
  factory FirebaseSettings.fromFirestore(Map<String, dynamic> data) {
    return FirebaseSettings(
      checkInternet: data['checkInternet'] as bool? ?? false,
      checkLocation: data['checkLocation'] as bool? ?? false,
      checkSIM: data['checkSIM'] as bool? ?? false,
      checkVPN: data['checkVPN'] as bool? ?? false,
      location: data['location'] as String? ?? '',
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
    };
  }

  /// Вывод данных в лог
  void logData() {
    print('=== Firebase Settings ===');
    print('checkInternet: $checkInternet');
    print('checkLocation: $checkLocation');
    print('checkSIM: $checkSIM');
    print('checkVPN: $checkVPN');
    print('location: $location');
    print('========================');
  }

  @override
  String toString() {
    return 'FirebaseSettings(checkInternet: $checkInternet, checkLocation: $checkLocation, checkSIM: $checkSIM, checkVPN: $checkVPN, location: $location)';
  }
}
