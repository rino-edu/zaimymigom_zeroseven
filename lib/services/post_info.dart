import 'dart:async';

import 'package:advertising_id/advertising_id.dart';
import 'package:android_play_install_referrer/android_play_install_referrer.dart';
import 'package:appmetrica_plugin/appmetrica_plugin.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:http/http.dart' as http;
import 'package:battery_plus/battery_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import 'ip_info_repository.dart';
import '../main.dart';
import 'appsflyer_service.dart';
import 'config_service.dart';
import 'health_checker.dart';

class UserDataManager {
  static final UserDataManager _instance = UserDataManager._internal();
  factory UserDataManager() => _instance;
  UserDataManager._internal();

  final Map<String, dynamic> _userData = {};
  String? _appmetricaDeviceId = "none";
  String? _appsflyerDeviceId = "none";
  String? _packageName = "none";
  String? _appName = "none";
  String? _appVersionName = "none";
  String? _deviceOsType = "none";
  String? _deviceModel = "none";
  String? _osVersion = "none";
  String? _isEmulator = "none";
  Map<String, String> _deviceLanguage = {"country": "none", "language": "none"};
  String? _carrierName = "none";
  String? _networkType = "none";
  String? _advertisingId = "none";
  String? _timeZone = "none";
  String? _typeDevice = "none";
  String? _browserVersion = "none";
  String? _firstOpenTime = "none";
  String? _userIp = "none";
  String _referrer = "none";
  String? _kindDevice = "none";
  Map<String, dynamic> _batteryInfo = {
    "battery_state": "none",
    "battery_level": "none",
  };
  Map<String, dynamic> _carrierInfo = {};

  static final platform = MethodChannel('mobile_network_channel');

  Future<void> initialize() async {
    try {
      // Сначала пытаемся загрузить кешированные данные
      await _loadCachedDeviceInfo();

      // Группируем параметры по изменяемости
      final Future staticDataFutures = Future.wait([
        _getDeviceInfo(),
        _getPackageName(),
        _getAppName(),
      ]);

      final Future dynamicDataFutures = Future.wait([
        _getGoogleAdvertisingId(),
        _getUserAgentInfo(),
        _getAppMetricaDeviceID(),
        _getAppsFlyerDeviceID(),
        _getFirstOpenTime(),
        _getMobileNetworkName(),
        _getUserIP(),
        getReferrer(),
        _getBatteryInfo(),
        _getNetworkInfo(),
      ]);

      // Запускаем параллельные процессы сбора данных
      await Future.wait([staticDataFutures, dynamicDataFutures]);

      // Кешируем неизменяемые данные для будущего использования
      await _cacheStaticDeviceInfo();

      // Обновляем Map для отправки на сервер
      _updateUserData();

      await _saveDebugInfoToJson();
    } catch (e) {
      debugPrint('Ошибка инициализации: $e');
      rethrow;
    }
  }

  Future<void> sendDataToServer() async {
    try {
      // Сначала проверяем здоровье сервера
      debugPrint(
        '[UserDataManager] Проверяем здоровье сервера перед отправкой данных...',
      );
      final healthCheck = await HealthChecker.checkServerHealth();

      if (healthCheck['status'] == 'success') {
        debugPrint('[UserDataManager] Сервер здоров, отправляем данные...');
      } else {
        debugPrint(
          '[UserDataManager] Предупреждение: сервер не здоров: ${healthCheck['message']}',
        );
        // Продолжаем отправку, но логируем предупреждение
      }

      // Отправляем данные
      final response = await _retryWithTimeout(
        operation: () => _sendHttpRequest('app', _userData),
        maxAttempts: 3,
        timeout: const Duration(seconds: 10),
      );

      // Логируем результат отправки
      _handleResponse(response);
      debugPrint('[UserDataManager] ✅ Данные успешно отправлены на сервер');
    } catch (e) {
      _handleError(e);
      debugPrint('[UserDataManager] ❌ Ошибка при отправке данных: $e');
      rethrow;
    }
  }

  Future<String> getReferrer() async {
    try {
      ReferrerDetails referrerDetails =
      await AndroidPlayInstallReferrer.installReferrer;
      _referrer = referrerDetails.installReferrer.toString();
      _referrer = Uri.decodeFull(Uri.decodeFull(_referrer));
      return _referrer;
    } on PlatformException catch (e) {
      debugPrint("Failed to get referrer: ${e.message}");
      _referrer = "error_reading_referrer";
      return _referrer;
    }
  }

  Future<void> _getUserIP() async {
    try {
      _userIp = await IpInfoRepository().getIp();
    } on PlatformException catch (e) {
      debugPrint("Failed to get user IP: ${e.message}");
      _userIp = "error_reading_ip";
    }
  }

  Future<void> _getMobileNetworkName() async {
    try {
      _carrierName = await platform.invokeMethod('getMobileNetworkName');
    } on PlatformException catch (e) {
      debugPrint("Failed to get mobile network name: ${e.message}");
      _carrierName = "error_reading_carrier";
    }
  }

  Future<void> _getGoogleAdvertisingId() async {
    try {
      _advertisingId = await AdvertisingId.id(true);
    } catch (e) {
      _advertisingId = "gaid_error";
    }
  }

  Future<void> _getAppMetricaDeviceID() async {
    try {
      Future<AppMetricaStartupParams> params = AppMetrica.requestStartupParams([
        AppMetricaStartupParams.deviceIdHashKey,
        AppMetricaStartupParams.deviceIdKey,
        AppMetricaStartupParams.uuidKey,
      ]);
      await params.then(
            (value) => {
          _appmetricaDeviceId = value.result?.deviceIdHash,
        },
      );
    } catch (e) {
      _appmetricaDeviceId = "appmetrica_device_id_error";
    }
  }

  Future<void> _getAppsFlyerDeviceID() async {
    try {
      String? uid = await AppsFlyerService.getAppsFlyerUID();
      _appsflyerDeviceId = uid;
    } catch (e) {
      _appsflyerDeviceId = "appsflyer_device_id_error";
    }
  }

  Future<void> _getAppName() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      _appName = packageInfo.appName;
    } catch (e) {
      _appName = "app_name_error";
    }
  }

  Future<void> _getPackageName() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      _packageName = packageInfo.packageName;
      _appVersionName = packageInfo.version;
    } catch (e) {
      _packageName = "package_name_error";
    }
  }

  Future<void> _getDeviceInfo() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

      // Получаем язык устройства и страну
      final locale = Platform.localeName.split('_');
      _deviceLanguage = {
        "country": locale.length > 1 ? locale[1] : "unknown",
        "language": locale[0],
      };

      // Получаем часовой пояс
      _timeZone = await FlutterTimezone.getLocalTimezone();

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        _deviceOsType = "Android";
        _osVersion = androidInfo.version.release;
        _isEmulator = androidInfo.isPhysicalDevice ? "false" : "true";

        // Получаем информацию о модели устройства и бренде
        _typeDevice = "${androidInfo.model} ${androidInfo.brand}";

        // Определяем тип устройства
        if (androidInfo.systemFeatures.contains(
          'android.hardware.type.watch',
        )) {
          _kindDevice = 'Watch';
        } else if (androidInfo.systemFeatures.contains(
          'android.hardware.type.television',
        )) {
          _kindDevice = 'TV';
        } else if (androidInfo.systemFeatures.contains(
          'android.hardware.type.automotive',
        )) {
          _kindDevice = 'Automotive';
        } else if (androidInfo.systemFeatures.contains(
          'android.software.leanback',
        )) {
          _kindDevice = 'TV';
        } else {
          _kindDevice = 'Handset'; // По умолчанию считаем телефоном
        }
      }

      // Получаем тип подключения
      final List<ConnectivityResult> connectivityResult =
      await (Connectivity().checkConnectivity());

      if (connectivityResult.contains(ConnectivityResult.mobile)) {
        _networkType = "mobile";
        return;
      } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
        _networkType = "wifi";
        return;
      } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
        _networkType = "ethernet";
        return;
      } else if (connectivityResult.contains(ConnectivityResult.other)) {
        _networkType = "unknown";
        return;
      } else if (connectivityResult.contains(ConnectivityResult.none)) {
        _networkType = "none";
        return;
      }
    } catch (e) {
      debugPrint("Error getting device info: $e");
      _kindDevice = "unknown";
    }
  }

  Future<void> _getFirstOpenTime() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedFirstOpenTime = prefs.getString('first_open_time');

      if (savedFirstOpenTime == null) {
        // Если времени первого запуска нет - значит это первый запуск
        _firstOpenTime = DateTime.now().toUtc().toIso8601String();
        await prefs.setString('first_open_time', _firstOpenTime!);
      } else {
        // Если время уже сохранено - используем его
        _firstOpenTime = savedFirstOpenTime;
      }
    } catch (e) {
      _firstOpenTime = "first_open_time_error";
    }
  }

  Future<void> _getUserAgentInfo() async {
    String platformVersion;

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

    try {
      platformVersion = "Dalvik/2.1.0 (Linux; U; Android ${androidInfo.version.release}; ${androidInfo.model} Build/${androidInfo.id})";
      print("platformVersion = $platformVersion");
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    _browserVersion = platformVersion;
  }

  Future<void> _getBatteryInfo() async {
    try {
      final Battery battery = Battery();

      // Инициализируем значения по умолчанию
      _batteryInfo = {
        "batteryState": "unknown",
        "batteryLevel": 0.0,
        "lowPowerMode": false,
      };

      // Получаем уровень заряда и нормализуем к диапазону 0-1
      final int levelPercent = await battery.batteryLevel;
      _batteryInfo["batteryLevel"] = levelPercent / 100.0;

      // Получаем состояние батареи
      final state = await battery.batteryState;
      String stateString;

      switch (state) {
        case BatteryState.full:
          stateString = "full";
          break;
        case BatteryState.charging:
          stateString = "charging";
          break;
        case BatteryState.discharging:
          stateString = "discharging";
          break;
        case BatteryState.unknown:
        default:
          stateString = "unknown";
      }

      _batteryInfo["batteryState"] = stateString;

      // Пытаемся получить состояние режима энергосбережения
      try {
        // Для Android нужно использовать метод через MethodChannel
        if (Platform.isAndroid) {
          final bool isLowPowerMode =
              await const MethodChannel(
                'battery_channel',
              ).invokeMethod<bool>('isLowPowerMode') ??
                  false;
          _batteryInfo["lowPowerMode"] = isLowPowerMode;
        }
      } catch (e) {
        debugPrint("Не удалось получить состояние режима энергосбережения: $e");
        // В случае ошибки оставляем значение по умолчанию (false)
      }
    } catch (e) {
      debugPrint("Ошибка при получении информации о батарее: $e");
      _batteryInfo = {
        "batteryState": "error",
        "batteryLevel": 0.0,
        "lowPowerMode": false,
      };
    }
  }

  Future<void> _getNetworkInfo() async {
    Map<String, dynamic> netInfo = {
      "isConnected": false,
      "type": "none",
      "isInternetReachable": false,
      "isWifiEnabled": false,
      "details": {},
    };

    try {
      // Получаем базовую информацию о подключении
      final List<ConnectivityResult> connectivityResults =
      await Connectivity().checkConnectivity();
      bool isConnected =
          connectivityResults.isNotEmpty &&
              !connectivityResults.contains(ConnectivityResult.none);

      netInfo["isConnected"] = isConnected;

      // Определяем тип подключения
      if (connectivityResults.contains(ConnectivityResult.wifi)) {
        netInfo["type"] = "wifi";
        netInfo["isWifiEnabled"] = true;
      } else if (connectivityResults.contains(ConnectivityResult.mobile)) {
        netInfo["type"] = "mobile";
      } else if (connectivityResults.contains(ConnectivityResult.ethernet)) {
        netInfo["type"] = "ethernet";
      } else if (connectivityResults.contains(ConnectivityResult.bluetooth)) {
        netInfo["type"] = "bluetooth";
      } else if (connectivityResults.contains(ConnectivityResult.other)) {
        netInfo["type"] = "other";
      }

      // Проверяем доступность интернета
      bool isInternetReachable =
      await InternetConnectionChecker.instance.hasConnection;
      netInfo["isInternetReachable"] = isInternetReachable;

      // Детальная информация о сети будет собрана только для WiFi
      if (connectivityResults.contains(ConnectivityResult.wifi)) {
        // Используем Network Info Plus для получения информации о WiFi
        final info = NetworkInfo();

        // Получаем основные данные о WiFi
        String? wifiBSSID = await info.getWifiBSSID(); // BSSID
        String? wifiIP = await info.getWifiIP(); // IP адрес
        final String? wifiSubmask = await info.getWifiSubmask();
        final String? wifiBroadcast = await info.getWifiBroadcast();
        final String? wifiGateway = await info.getWifiGatewayIP();

        final String? userIp = await IpInfoRepository().getIp();

        // Собираем детальную информацию через нативный канал
        final details = await _getDetailedWifiInfo();

        // Заполняем поле details
        netInfo["details"] = {
          "ipAddress": userIp ?? "unknown",
          "bssid": wifiBSSID?.replaceAll('"', '') ?? "unknown",
          "ipAddressWIFI": wifiIP ?? "unknown",
          "subnet": wifiSubmask ?? "255.255.255.0",
          "broadcast": wifiBroadcast ?? "unknown",
          "gateway": wifiGateway ?? "unknown",
          ...details, // Добавляем все данные из нативного метода
          "isConnectionExpensive":
          false, // Это значение можно получить только в нативном коде
        };
      } else if (connectivityResults.contains(ConnectivityResult.mobile)) {
        // Для мобильной сети собираем меньше информации
        netInfo["details"] = await _getMobileNetworkDetails();
      }
    } catch (e) {
      debugPrint("Ошибка при получении информации о сети: $e");
    }

    // Сохраняем полученную информацию
    _carrierInfo = netInfo;
  }

  // Метод для получения детальной информации о WiFi через нативный канал
  Future<Map<String, dynamic>> _getDetailedWifiInfo() async {
    try {
      // Получаем данные из нативного канала
      final result = await const MethodChannel(
        'network_info_channel',
      ).invokeMethod('getDetailedWifiInfo');

      // Преобразуем результат в Map<String, dynamic>
      Map<String, dynamic> convertedResult = {};

      if (result is Map) {
        // Итерируем по всем элементам в результате
        result.forEach((key, value) {
          if (key is String) {
            convertedResult[key] = value;
          }
        });
        return convertedResult;
      } else {
        throw Exception("Результат не является Map");
      }
    } catch (e) {
      debugPrint("Ошибка при получении детальной информации о WiFi: $e");
      return {
        "subnet": "255.255.255.0",
        "frequency": 0,
        "strength": 0,
        "linkSpeed": 0,
        "txLinkSpeed": 0,
        "rxLinkSpeed": 0,
      };
    }
  }

  // Метод для получения информации о мобильной сети
  Future<Map<String, dynamic>> _getMobileNetworkDetails() async {
    try {
      // Можно добавить дополнительные данные через нативный канал
      final String? ipAddress = await NetworkInfo().getWifiIP();

      return {
        "ipAddressWIFI": ipAddress ?? "unknown",
        "isConnectionExpensive": true,
      };
    } catch (e) {
      debugPrint("Ошибка при получении информации о мобильной сети: $e");
      return {"ipAddressWIFI": "unknown", "isConnectionExpensive": true};
    }
  }

  Future<void> _saveDebugInfoToJson() async {
    if (kDebugMode) {
      try {
        Map<String, dynamic> debugInfo = {
          'appmetrica_device_id': _appmetricaDeviceId,
          'apps_flyer_id': _appsflyerDeviceId,
          'bundle': _packageName,
          'name': _appName,
          'model_device': _deviceOsType,
          'type_device': _typeDevice,
          'os_device': _osVersion,
          'emulator': _isEmulator,
          'language_device': _deviceLanguage,
          'network_operator': _carrierName,
          'type_network': _networkType,
          'google_advertising_id': _advertisingId,
          'time_zone': _timeZone,
          'kind_device': _kindDevice,
          'version_browser': _browserVersion,
          'time_first_open_app': _firstOpenTime,
          'install_referrer': _referrer,
          'power_info': _batteryInfo,
          'net_info': _carrierInfo,
        };

        // Преобразуем Map в JSON с отступами для читаемости
        final jsonString = const JsonEncoder.withIndent(
          '  ',
        ).convert(debugInfo);

        // Выводим в консоль с разделителями для лучшей видимости
        debugPrint('\n=== DEBUG INFO ===\n');
        debugPrint(jsonString);
        debugPrint('\n================\n');
      } catch (e) {
        debugPrint('Error debugPrinting debug info: $e');
      }
    }
  }

  Future<T> _retryWithTimeout<T>({
    required Future<T> Function() operation,
    required int maxAttempts,
    required Duration timeout,
  }) async {
    int attempts = 0;
    while (attempts < maxAttempts) {
      try {
        return await operation().timeout(timeout);
      } catch (e) {
        attempts++;
        if (attempts >= maxAttempts) rethrow;
        await Future.delayed(Duration(seconds: attempts));
      }
    }
    throw TimeoutException('Превышено количество попыток');
  }

  Future<http.Response> _sendHttpRequest(
      String route,
      Map<String, dynamic> data,
      ) async {
    final uuid = Uuid();
    final fullUrl = ConfigService.getFullUrl(route);

    try {
      return await http.post(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Request-ID': uuid.v4(),
          'User-Agent': '$_packageName/$_appVersionName',
        },
        body: json.encode(data),
      );
    } catch (e) {
      // Обработка SSL ошибок
      if (e.toString().contains('CERTIFICATE_VERIFY_FAILED') ||
          e.toString().contains('HandshakeException')) {
        debugPrint('[HTTP] SSL сертификат истек или недействителен: $e');

        // Попытка отправить данные без проверки сертификата (только для отладки)
        if (kDebugMode) {
          debugPrint('[HTTP] Попытка отправки без проверки SSL сертификата...');
          return await _sendHttpRequestWithoutSSL(route, data, uuid);
        }

        throw HttpException(
          'SSL сертификат сервера истек или недействителен. '
              'Обратитесь к администратору сервера.',
        );
      }
      rethrow;
    }
  }

  /// Альтернативный метод отправки данных без проверки SSL (только для отладки)
  Future<http.Response> _sendHttpRequestWithoutSSL(
      String route,
      Map<String, dynamic> data,
      Uuid uuid,
      ) async {
    try {
      final fullUrl = ConfigService.getFullUrl(route);

      // Создаем HttpClient с отключенной проверкой сертификата
      final httpClient =
      HttpClient()
        ..badCertificateCallback = (cert, host, port) {
          debugPrint(
            '[HTTP] Игнорируем недействительный сертификат для $host:$port',
          );
          return true; // Принимаем любой сертификат
        };

      final request = await httpClient.postUrl(Uri.parse(fullUrl));
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Accept', 'application/json');
      request.headers.set('X-Request-ID', uuid.v4());
      request.headers.set('User-Agent', '$_packageName/$_appVersionName');

      request.write(json.encode(data));
      final response = await request.close();

      // Читаем тело ответа
      final responseBody = await response.transform(utf8.decoder).join();

      // Создаем http.Response объект
      final Map<String, String> headers = {};
      response.headers.forEach((key, values) {
        headers[key] = values.join(', ');
      });

      return http.Response(responseBody, response.statusCode, headers: headers);
    } catch (e) {
      debugPrint('[HTTP] Ошибка при отправке без SSL: $e');
      rethrow;
    }
  }

  void _handleResponse(http.Response response) {
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw HttpException('Ошибка отправки: ${response.statusCode}');
    }
    debugPrint('Данные успешно отправлены');
  }

  void _handleError(dynamic error) {
    debugPrint('Ошибка при отправке данных: $error');
  }

  Future<void> postInfo() async {
    await initialize();
    await sendDataToServer();
  }

  // Добавляем метод для кеширования данных устройства
  Future<void> _cacheStaticDeviceInfo() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Проверяем, есть ли уже кешированные данные
      final bool hasCachedData = prefs.getBool('device_info_cached') ?? false;

      if (!hasCachedData) {
        // Сохраняем неизменяемые данные устройства в кеш
        await prefs.setString('device_os_type', _deviceOsType ?? "none");
        await prefs.setString('device_model', _typeDevice ?? "none");
        await prefs.setString('os_version', _osVersion ?? "none");
        await prefs.setString('is_emulator', _isEmulator ?? "none");
        await prefs.setString('kind_device', _kindDevice ?? "none");

        // Сохраняем языковые настройки
        await prefs.setString(
          'language_code',
          _deviceLanguage['language'] ?? "none",
        );
        await prefs.setString(
          'country_code',
          _deviceLanguage['country'] ?? "none",
        );

        // Отмечаем, что данные были закешированы
        await prefs.setBool('device_info_cached', true);
      }
    } catch (e) {
      debugPrint('Ошибка при кешировании данных устройства: $e');
    }
  }

  // Добавляем метод для загрузки кешированных данных
  Future<void> _loadCachedDeviceInfo() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool hasCachedData = prefs.getBool('device_info_cached') ?? false;

      if (hasCachedData) {
        // Загружаем кешированные данные
        _deviceOsType = prefs.getString('device_os_type') ?? _deviceOsType;
        _typeDevice = prefs.getString('device_model') ?? _typeDevice;
        _osVersion = prefs.getString('os_version') ?? _osVersion;
        _isEmulator = prefs.getString('is_emulator') ?? _isEmulator;
        _kindDevice = prefs.getString('kind_device') ?? _kindDevice;
        _advertisingId = prefs.getString('advertising_id') ?? _advertisingId;

        // Загружаем языковые настройки
        _deviceLanguage = {
          "language": prefs.getString('language_code') ?? "none",
          "country": prefs.getString('country_code') ?? "none",
        };

        debugPrint('Загружены кешированные данные устройства');
        return; // Возвращаемся, если загрузили кешированные данные
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке кешированных данных: $e');
    }
  }

  // Добавляем метод для обновления _userData перед отправкой
  void _updateUserData() {
    _userData.addAll({
      'appmetrica_device_id': _appmetricaDeviceId,
      'apps_flyer_id': _appsflyerDeviceId,
      'bundle': _packageName,
      'name': _appName,
      'model_device': _deviceOsType,
      'type_device': _typeDevice,
      'os_device': _osVersion,
      'emulator': _isEmulator,
      'language_device': _deviceLanguage,
      'network_operator': _carrierName,
      'type_network': _networkType,
      'google_advertising_id': _advertisingId,
      'time_zone': _timeZone,
      'kind_device': _kindDevice,
      'version_browser': _browserVersion,
      'time_first_open_app': _firstOpenTime,
      'install_referrer': _referrer,
      'power_info': _batteryInfo,
      'net_info': _carrierInfo,
    });
  }
}
