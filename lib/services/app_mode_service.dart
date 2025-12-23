import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:vpn_detector/vpn_detector.dart';
import 'package:http/http.dart' as http;
import 'firebase_service.dart';
import 'appmetrica_service.dart';

/// Режимы работы приложения
enum AppMode {
  /// Боевой режим - показывать только экран займов
  combat,

  /// Небоевой режим - показывать полное приложение
  nonCombat,
}

/// Результат определения режима работы
class AppModeResult {
  final AppMode mode;
  final String reason;
  final Map<String, dynamic> checks;

  AppModeResult({
    required this.mode,
    required this.reason,
    required this.checks,
  });

  void logResult() {
    //print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    //print('🎯 APP MODE DETERMINATION RESULT');
    //print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    //print('Mode: ${mode == AppMode.combat ? "🔥 COMBAT" : "🛡️ NON-COMBAT"}');
    //print('Reason: $reason');
    //print('');
    //print('Check Details:');
    checks.forEach((key, value) {
      //final status = value == true ? '✅' : '❌';
      //print('  $status $key: $value');
    });
    //print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  @override
  String toString() {
    return 'AppModeResult(mode: $mode, reason: $reason, checks: $checks)';
  }
}

/// Сервис для определения режима работы приложения
class AppModeService {
  static final AppModeService _instance = AppModeService._internal();
  factory AppModeService() => _instance;
  AppModeService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  AppMode? _currentMode;
  AppModeResult? _lastResult;

  /// Текущий режим работы приложения
  AppMode? get currentMode => _currentMode;

  /// Последний результат определения режима
  AppModeResult? get lastResult => _lastResult;

  /// Отправить событие в AppMetrica о результате определения режима
  void _reportModeToAppMetrica(
      AppMode mode,
      String reason, {
        String? userCountry,
      }) {
    AppMetricaService.reportEvent(
      'app_mode_determined',
      parameters: {
        'mode': mode == AppMode.combat ? 'combat' : 'non_combat',
        'reason': reason,
        if (userCountry != null) 'user_country': userCountry,
      },
    );
  }

  /// Определить режим работы приложения
  Future<AppModeResult> determineAppMode() async {
    //print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    //print('🎯 STARTING APP MODE DETERMINATION');
    //print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final checks = <String, dynamic>{};

    // 1. Проверка интернета
    //print('📡 Step 1: Checking internet connection...');
    final hasInternet = await _checkInternetConnection();
    checks['Internet Connection'] = hasInternet;

    if (!hasInternet) {
      _currentMode = AppMode.nonCombat;
      final result = AppModeResult(
        mode: _currentMode!,
        reason: 'No internet connection',
        checks: checks,
      );
      _lastResult = result;
      result.logResult();

      // Отправляем событие в AppMetrica
      _reportModeToAppMetrica(AppMode.nonCombat, 'No internet connection');

      return result;
    }

    // 2. Проверка подключения к Firebase Firestore
    //print('🔥 Step 2: Checking Firebase Firestore connection...');
    final hasFirebaseConnection = await _firebaseService.checkConnection();
    checks['Firebase Connection'] = hasFirebaseConnection;

    if (!hasFirebaseConnection) {
      _currentMode = AppMode.nonCombat;
      final result = AppModeResult(
        mode: _currentMode!,
        reason: 'No Firebase Firestore connection',
        checks: checks,
      );
      _lastResult = result;
      result.logResult();

      // Отправляем событие в AppMetrica
      _reportModeToAppMetrica(
        AppMode.nonCombat,
        'No Firebase Firestore connection',
      );

      return result;
    }

    // 3. Получение настроек из Firebase
    //print('⚙️ Step 3: Loading Firebase settings...');
    final settings = await _firebaseService.getSettings();

    if (settings == null) {
      _currentMode = AppMode.nonCombat;
      final result = AppModeResult(
        mode: _currentMode!,
        reason: 'Failed to load Firebase settings',
        checks: checks,
      );
      _lastResult = result;
      result.logResult();

      // Отправляем событие в AppMetrica
      _reportModeToAppMetrica(
        AppMode.nonCombat,
        'Failed to load Firebase settings',
      );

      return result;
    }

    // 4. Проверка VPN (с учетом настроек)
    //print('🔒 Step 4: Checking VPN status...');
    final hasVpn = await _checkVpnStatus(settings.checkVPN);
    checks['VPN Status'] = hasVpn;

    if (hasVpn) {
      _currentMode = AppMode.nonCombat;
      final result = AppModeResult(
        mode: _currentMode!,
        reason: 'VPN is enabled (blocks combat mode)',
        checks: checks,
      );
      _lastResult = result;
      result.logResult();

      // Отправляем событие в AppMetrica
      _reportModeToAppMetrica(
        AppMode.nonCombat,
        'VPN is enabled (blocks combat mode)',
      );

      return result;
    }

    // 5. Проверка настройки checkLocation
    //print('📍 Step 5: Checking location check setting...');
    final locationCheckEnabled = settings.checkLocation;
    checks['Location Check Enabled'] = locationCheckEnabled;

    if (!locationCheckEnabled) {
      _currentMode = AppMode.nonCombat;
      final result = AppModeResult(
        mode: _currentMode!,
        reason: 'Location check is disabled in settings',
        checks: checks,
      );
      _lastResult = result;
      result.logResult();

      // Отправляем событие в AppMetrica
      _reportModeToAppMetrica(
        AppMode.nonCombat,
        'Location check is disabled in settings',
      );

      return result;
    }

    // 6. Определение страны пользователя по IP
    //print('🌍 Step 6: Determining user country...');
    final userCountry = await _getUserCountryByIp();
    checks['User Country'] = userCountry;

    if (userCountry == null) {
      _currentMode = AppMode.nonCombat;
      final result = AppModeResult(
        mode: _currentMode!,
        reason: 'Failed to determine user country',
        checks: checks,
      );
      _lastResult = result;
      result.logResult();

      // Отправляем событие в AppMetrica
      _reportModeToAppMetrica(
        AppMode.nonCombat,
        'Failed to determine user country',
      );

      return result;
    }

    // 7. Проверка разрешенных стран в настройках
    //print('✅ Step 7: Checking allowed countries...');
    final allowedCountries = settings.location.split('/');
    // Приводим все к нижнему регистру для сравнения
    final allowedCountriesLower = allowedCountries
        .map((c) => c.toLowerCase())
        .toList();
    //print('   📍 User country: "$userCountry"');
    //print('   📍 Allowed countries (original): $allowedCountries');
    //print('   📍 Allowed countries (lowercase): $allowedCountriesLower');
    checks['Allowed Countries'] = allowedCountriesLower;
    checks['User Country Allowed'] = allowedCountriesLower.contains(
      userCountry,
    );

    if (!allowedCountriesLower.contains(userCountry)) {
      _currentMode = AppMode.nonCombat;
      final result = AppModeResult(
        mode: _currentMode!,
        reason:
        'User country "$userCountry" is not in allowed list: $allowedCountriesLower',
        checks: checks,
      );
      _lastResult = result;
      result.logResult();

      // Отправляем событие в AppMetrica
      _reportModeToAppMetrica(
        AppMode.nonCombat,
        'User country not allowed',
        userCountry: userCountry,
      );

      return result;
    }

    // 8. Проверка коллекции boy_offers
    //print('💼 Step 8: Checking boy_offers collection...');
    final hasBoyOffers = await _checkBoyOffersCollection(userCountry);
    checks['Boy Offers Collection'] = hasBoyOffers;

    if (!hasBoyOffers) {
      _currentMode = AppMode.nonCombat;
      final result = AppModeResult(
        mode: _currentMode!,
        reason: 'Boy offers collection not found for country: $userCountry',
        checks: checks,
      );
      _lastResult = result;
      result.logResult();

      // Отправляем событие в AppMetrica
      _reportModeToAppMetrica(
        AppMode.nonCombat,
        'Boy offers collection not found',
        userCountry: userCountry,
      );

      return result;
    }

    // Все проверки пройдены - боевой режим
    _currentMode = AppMode.combat;
    final result = AppModeResult(
      mode: _currentMode!,
      reason: 'All checks passed - combat mode enabled',
      checks: checks,
    );
    _lastResult = result;
    result.logResult();

    // Отправляем событие в AppMetrica
    _reportModeToAppMetrica(
      AppMode.combat,
      'All checks passed',
      userCountry: userCountry,
    );

    return result;
  }

  /// Проверка интернет-соединения
  Future<bool> _checkInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        //print('   ❌ No internet connectivity');
        return false;
      }

      // Дополнительная проверка через HTTP запрос
      // Увеличено время ожидания для медленного интернета (2G)
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 30));

      final hasInternet = response.statusCode == 200;
/*      //print(
        '   ${hasInternet ? "✅" : "❌"} Internet connection: ${hasInternet ? "OK" : "Failed"}',
      );*/
      return hasInternet;
    } catch (e) {
      //print('   ❌ Internet check failed: $e');
      return false;
    }
  }

  /// Проверка статуса VPN (с учетом настроек Firebase)
  Future<bool> _checkVpnStatus(bool checkVpnSetting) async {
    if (!checkVpnSetting) {
      //print('   ⚠️  VPN check disabled in settings - assuming VPN is OFF');
      return false; // Если в настройках отключена проверка VPN, считаем что VPN выключен
    }

    try {
      final vpnDetector = VpnDetector();
      final isVpnActive = await vpnDetector.isVpnActive();
/*      //print(
        '   ${isVpnActive ? "🔴" : "🟢"} VPN status: ${isVpnActive ? "Active (BLOCKS combat mode)" : "Inactive (ALLOWS combat mode)"}',
      );*/
      return isVpnActive;
    } catch (e) {
      //print('   ❌ VPN check failed: $e');
      return false; // При ошибке считаем что VPN выключен
    }
  }

  /// Определение страны пользователя по IP
  Future<String?> _getUserCountryByIp() async {
    try {
      // Увеличено время ожидания для медленного интернета (2G)
      final response = await http
          .get(Uri.parse('https://ipinfo.io/json'))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = response.body;
        // Простое извлечение кода страны из JSON ipinfo.io
        final countryCodeMatch = RegExp(
          r'"country"\s*:\s*"([^"]+)"',
        ).firstMatch(data);
        if (countryCodeMatch != null) {
          final countryCode = countryCodeMatch.group(1)?.toLowerCase();
          //print('   ✅ User country detected: $countryCode');
          return countryCode;
        }
      }

      //print('   ❌ Failed to detect country from IP');
      return null;
    } catch (e) {
      //print('   ❌ Country detection failed: $e');
      return null;
    }
  }

  /// Проверка наличия коллекции boy_offers для страны
  Future<bool> _checkBoyOffersCollection(String countryCode) async {
    try {
      // Timeout уже установлен в getVisibleBoyOffers (30 секунд)
      final offers = await _firebaseService.getVisibleBoyOffers(countryCode);

      final hasOffers = offers.isNotEmpty;
      //print('   ${hasOffers ? "✅" : "❌"} Boy offers collection: ${hasOffers ? "Found ${offers.length} offers" : "Empty or not found"}');
      return hasOffers;
    } catch (e) {
      //print('   ❌ Boy offers collection check failed: $e');
      return false;
    }
  }


  /// Переопределить режим работы (для тестирования)
  void setMode(AppMode mode, {String reason = 'Manual override'}) {
    _currentMode = mode;
    _lastResult = AppModeResult(
      mode: mode,
      reason: reason,
      checks: {'Manual Override': true},
    );
/*    //print(
      '🔧 App mode manually set to: ${mode == AppMode.combat ? "COMBAT" : "NON-COMBAT"}',
    );*/
    //print('Reason: $reason');
  }

  /// Сбросить режим работы (для повторного определения)
  void resetMode() {
    _currentMode = null;
    _lastResult = null;
    //print('🔄 App mode reset - will be determined on next check');
  }
}