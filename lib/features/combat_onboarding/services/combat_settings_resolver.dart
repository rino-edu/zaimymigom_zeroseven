import '../../../models/firebase_settings.dart';
import '../../../services/firebase_service.dart';
import '../../../services/server_data_service.dart';

/// Резолвит настройки с приоритетом сервера.
class CombatSettingsResolver {
  final ServerDataService _serverDataService;
  final FirebaseService _firebaseService;

  CombatSettingsResolver({
    ServerDataService? serverDataService,
    FirebaseService? firebaseService,
  })  : _serverDataService = serverDataService ?? ServerDataService(),
        _firebaseService = firebaseService ?? FirebaseService();

  /// Возвращает настройки (аналог Firestore settings/general) с приоритетом сервера.
  ///
  /// - Сначала пытается взять settings из `ServerDataService.fetchAllData()`.
  /// - Если settings отсутствуют/ошибка — берёт из Firestore (`FirebaseService.getSettings()`).
  ///
  /// Если оба источника недоступны — возвращает null.
  Future<FirebaseSettings?> resolveSettings() async {
    try {
      final serverData = await _serverDataService.fetchAllData();
      if (serverData.settings != null) {
        return serverData.settings;
      }
    } catch (_) {
      // ignore, fallback below
    }

    return await _firebaseService.getSettings();
  }
}

