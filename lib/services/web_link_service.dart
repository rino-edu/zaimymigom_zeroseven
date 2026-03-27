import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/appmetrica_service.dart';
import 'app_mode_service.dart';

/// Сервис для формирования основной ссылки WebView с параметрами
class WebLinkService {
  // Синглтон
  static final WebLinkService _instance = WebLinkService._internal();
  factory WebLinkService() => _instance;
  WebLinkService._internal();

  // Ключи для хранения в SharedPreferences
  //static const String _prefSub2Key = 'sub2';
  //static const String _prefSub3Key = 'sub3';
  //static const String _prefSub5Key = 'sub5';
  static const String _prefSub6Key = 'sub6';

  // Основная ссылка из конфигурации
  String _mainLink = '';
  bool isBoyMode = false;
  AppMode? _currentAppMode;

  // Параметры для формирования ссылки
  final Map<String, String> _linkParams = {
    //'sub2': '',
    //'sub3': '',
    //'sub5': '',
    'sub6': '',
    //'sub7': '',
  };

  /// Загрузка настроек из config.json
  Future<Map<String, dynamic>> _loadConfig() async {
    debugPrint('WebLinkService: Загрузка настроек из config.json');
    try {
      final String configString = await rootBundle.loadString(
        'assets/strings/config.json',
      );
      final Map<String, dynamic> config = json.decode(configString);
      debugPrint('WebLinkService: Конфигурация загружена: $config');
      return config;
    } catch (e) {
      debugPrint('WebLinkService: Ошибка при загрузке конфигурации: $e');
      return {};
    }
  }

  /// Получение Install Referrer для sub2 и sub3
  /* Future<void> _getInstallReferrer() async {
    debugPrint('WebLinkService: Получение Install Referrer');
    String tempSub2Handler = "";
    String tempSub3Handler = "";
    String referrerDetailsString;

    try {
      ReferrerDetails referrerDetails =
          await AndroidPlayInstallReferrer.installReferrer;

      referrerDetailsString = referrerDetails.installReferrer.toString();
      debugPrint('WebLinkService: Raw referrer: $referrerDetailsString');

      referrerDetailsString = Uri.decodeFull(
        Uri.decodeFull(referrerDetailsString),
      );
      debugPrint('WebLinkService: Decoded referrer: $referrerDetailsString');

      int underscoreIndex = referrerDetailsString.indexOf("_");
      int ampersandIndex = referrerDetailsString.indexOf("&");

      if (underscoreIndex != -1) {
        tempSub2Handler = referrerDetailsString.substring(0, underscoreIndex);
        debugPrint("WebLinkService: tempSub2Handler = $tempSub2Handler");
      }

      if (ampersandIndex != -1) {
        tempSub3Handler = referrerDetailsString.substring(
          underscoreIndex + 1,
          ampersandIndex,
        );
        debugPrint("WebLinkService: tempSub3Handler = $tempSub3Handler");
      } else {
        tempSub3Handler = referrerDetailsString.substring(underscoreIndex + 1);
        debugPrint("WebLinkService: tempSub3Handler = $tempSub3Handler");
      }
    } catch (e) {
      referrerDetailsString = 'Failed to get referrer details: $e';
      debugPrint('WebLinkService: $referrerDetailsString');
      tempSub2Handler = "tracker";
      tempSub3Handler = "error";
    }

    _linkParams['sub2'] = tempSub2Handler;
    _linkParams['sub3'] = tempSub3Handler;

    debugPrint(
      'WebLinkService: sub2 = ${_linkParams['sub2']}, sub3 = ${_linkParams['sub3']}',
    );
  } */

  /// Получение Advertising ID для sub5
/*   Future<void> _getAdvertisingId() async {
    debugPrint('WebLinkService: Получение Advertising ID');
    try {
      String? advertisingId = await AdvertisingId.id(true);
      _linkParams['sub5'] = advertisingId ?? 'advertising_id_not_available';
      debugPrint(
        'WebLinkService: Advertising ID получен: ${_linkParams['sub5']}',
      );
    } catch (e) {
      _linkParams['sub5'] = 'advertising_id_error';
      debugPrint('WebLinkService: Ошибка при получении Advertising ID: $e');
    }
  } */

  /// Сохранение параметров в SharedPreferences
  Future<void> _saveParamsToPrefs() async {
    debugPrint('WebLinkService: Кеширование параметров в SharedPreferences');
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      //await prefs.setString(_prefSub2Key, _linkParams['sub2'] ?? '');
      //await prefs.setString(_prefSub3Key, _linkParams['sub3'] ?? '');
      //await prefs.setString(_prefSub5Key, _linkParams['sub5'] ?? '');
      await prefs.setString(_prefSub6Key, _linkParams['sub6'] ?? '');

      debugPrint(
        'WebLinkService: Параметры успешно сохранены в SharedPreferences',
      );
    } catch (e) {
      debugPrint('WebLinkService: Ошибка при сохранении параметров: $e');
    }
  }

  /// Формирование основной ссылки с параметрами
  Future<String> buildMainLink() async {
    debugPrint('WebLinkService: Начало формирования основной ссылки');

    // Определяем режим через новый сервис

    final AppMode? modeResult = AppModeService().currentMode;
    isBoyMode = modeResult == AppMode.combat;

    debugPrint('WebLinkService: Определен режим: ${modeResult?.name}');

    // Загрузка конфигурации
    final Map<String, dynamic> config = await _loadConfig();
    _mainLink = config['main_link_global'] as String? ?? '';
    debugPrint('WebLinkService: Основная ссылка из конфига: $_mainLink');

    if (_mainLink.isEmpty) {
      debugPrint('WebLinkService: Основная ссылка не найдена в конфигурации');
      return '';
    }

    // Получение параметров
    //await _getInstallReferrer();
    //await _getAdvertisingId();
    _linkParams['sub6'] = await AppMetricaService.getDeviceIdHash();

    // Сохранение параметров
    await _saveParamsToPrefs();

    // Получение и обработка SharedPreferences для модификации ссылки
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Обработка sub2
/*     String sub2 = _linkParams['sub2'] ?? '';
    if (sub2.isNotEmpty) {
      debugPrint('WebLinkService: Добавление sub2=$sub2 в ссылку');
      if (sub2 == "utm") {
        String? prefSub2 = prefs.getString(_prefSub2Key);
        if (prefSub2 != null && prefSub2.isNotEmpty) {
          sub2 = prefSub2;
          debugPrint('WebLinkService: Использую кешированный sub2=$sub2');
        }
      } else {
        await prefs.setString(_prefSub2Key, sub2);
      }

      // Заменяем плейсхолдеры в ссылке
      // Сначала sub2, потом sub3
      if (_mainLink.contains("{deep_adv}")) {
        _mainLink = _mainLink.replaceFirst("{deep_adv}", sub2);
        debugPrint('WebLinkService: Заменено {deep_adv} на $sub2');
      } else {
        _mainLink = _mainLink.replaceFirst(
          "aff_sub4",
          "aff_sub2=$sub2&aff_sub4",
        );
        debugPrint('WebLinkService: Добавлен aff_sub2=$sub2');
      }
    } */

    // Обработка sub3
/*     String sub3 = _linkParams['sub3'] ?? '';
    if (sub3.isNotEmpty) {
      debugPrint('WebLinkService: Добавление sub3=$sub3 в ссылку');
      if (sub3 == "utm") {
        String? prefSub3 = prefs.getString(_prefSub3Key);
        if (prefSub3 != null && prefSub3.isNotEmpty) {
          sub3 = prefSub3;
          debugPrint('WebLinkService: Использую кешированный sub3=$sub3');
        }
      } else {
        await prefs.setString(_prefSub3Key, sub3);
      }

      if (_mainLink.contains("{deep_adv}")) {
        _mainLink = _mainLink.replaceFirst("{deep_adv}", sub3);
        debugPrint('WebLinkService: Заменено {deep_adv} на $sub3');
      } else {
        _mainLink = _mainLink.replaceFirst(
          "aff_sub4",
          "aff_sub3=$sub3&aff_sub4",
        );
        debugPrint('WebLinkService: Добавлен aff_sub3=$sub3');
      }
    } */

    // Обработка параметра aff_sub4 на основе определенного режима
    if (isBoyMode) {
      _mainLink = _mainLink.replaceFirst(
        "aff_sub4=vpn",
        "aff_sub4=boy_showcase",
      );
      debugPrint(
        'WebLinkService: Режим boy - изменено aff_sub4=vpn на aff_sub4=boy_showcase',
      );
    } else {
      debugPrint('WebLinkService: Режим vpn - оставляем aff_sub4=vpn');
    }

    // Добавление sub5 и sub6 в конец ссылки
/*     String sub5 = _linkParams['sub5'] ?? '';
    if (sub5.isEmpty) {
      final String? prefSub5 = prefs.getString(_prefSub5Key);
      if (prefSub5 != null && prefSub5.isNotEmpty) {
        sub5 = prefSub5;
        _linkParams['sub5'] = sub5;
        debugPrint('WebLinkService: Использую кешированный sub5=$sub5');
      }
    } else {
      await prefs.setString(_prefSub5Key, sub5);
    }
    if (sub5.isNotEmpty) {
      _mainLink += "&aff_sub5=$sub5";
      debugPrint('WebLinkService: Добавлен &aff_sub5=$sub5');
    } */

    String sub6 = _linkParams['sub6'] ?? '';
    if (sub6.isEmpty) {
      final String? prefSub6 = prefs.getString(_prefSub6Key);
      if (prefSub6 != null && prefSub6.isNotEmpty) {
        sub6 = prefSub6;
        _linkParams['sub6'] = sub6;
        debugPrint('WebLinkService: Использую кешированный sub6=$sub6');
      }
    } else {
      await prefs.setString(_prefSub6Key, sub6);
    }
    if (sub6.isNotEmpty) {
      _mainLink += "&aff_sub6=$sub6";
      debugPrint('WebLinkService: Добавлен &aff_sub6=$sub6');
    }

/*     String sub7 = _linkParams['sub7'] ?? '';
    if (sub7.isNotEmpty) {
      _mainLink += "&aff_sub7=$sub7";
      debugPrint('WebLinkService: Добавлен &aff_sub7=$sub7');
    } */

    debugPrint('WebLinkService: Итоговая ссылка: $_mainLink');
    debugPrint('WebLinkService: Режим boy определен: $isBoyMode');

    return _mainLink;
  }

  /// Получает текущий режим приложения
  AppMode? get currentAppMode => _currentAppMode;

  /// Обновляет режим приложения извне
  void updateAppMode(AppMode mode) {
    _currentAppMode = mode;
    isBoyMode = mode == AppMode.combat;
    debugPrint('WebLinkService: Режим обновлен на ${mode.name}');
  }

  /// Модифицирует предоставленную ссылку оффера, добавляя трекинг-параметры
  Future<String> generateModifiedOfferLink(String offerLink) async {
    debugPrint('WebLinkService: Начало модификации ссылки оффера: $offerLink');
    debugPrint('WebLinkService: Текущий режим boy: $isBoyMode');

    // Если режим не определен, определяем его
    if (_currentAppMode == null) {
      final AppMode? modeResult = AppModeService().currentMode;
      isBoyMode = modeResult == AppMode.combat;
      debugPrint('WebLinkService: Режим определен как ${modeResult?.name}');
    }

    // Проверяем текущий режим приложения
    if (!isBoyMode) {
      debugPrint(
        'WebLinkService: VPN режим - возвращаем оригинальную ссылку без модификации: $offerLink',
      );

      // Проверяем валидность ссылки
      try {
        final uri = Uri.parse(offerLink);
        if (!uri.hasScheme) {
          debugPrint(
            'WebLinkService: Ссылка не имеет схемы, добавляем https://',
          );
          return 'https://$offerLink';
        }
        return offerLink;
      } catch (e) {
        debugPrint('WebLinkService: Ошибка парсинга ссылки: $e');
        return offerLink;
      }
    }

    // Получаем параметры, если они еще не загружены.
    // sub2/sub3 сейчас отключены, поэтому проверяем активный ключ sub6.
    if ((_linkParams['sub6'] ?? '').isEmpty) {
      //await _getInstallReferrer();
      //await _getAdvertisingId();
      _linkParams['sub6'] = await AppMetricaService.getDeviceIdHash();
      await _saveParamsToPrefs();
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String modifiedLink = offerLink;

    // Добавляем sub2
/*     String sub2 = _linkParams['sub2'] ?? '';
    if (sub2.isNotEmpty) {
      if (sub2 == "utm") {
        String? prefSub2 = prefs.getString(_prefSub2Key);
        if (prefSub2 != null && prefSub2.isNotEmpty) {
          sub2 = prefSub2;
        }
      }

      if (modifiedLink.contains("?")) {
        modifiedLink += "&aff_sub2=$sub2";
      } else {
        modifiedLink += "?aff_sub2=$sub2";
      }
      debugPrint('WebLinkService: Добавлен aff_sub2=$sub2');
    } */

    // Добавляем sub3
/*     String sub3 = _linkParams['sub3'] ?? '';
    if (sub3.isNotEmpty) {
      if (sub3 == "utm") {
        String? prefSub3 = prefs.getString(_prefSub3Key);
        if (prefSub3 != null && prefSub3.isNotEmpty) {
          sub3 = prefSub3;
        }
      }

      modifiedLink += "&aff_sub3=$sub3";
      debugPrint('WebLinkService: Добавлен aff_sub3=$sub3');
    } */

    // Добавляем sub5
/*     String sub5 = _linkParams['sub5'] ?? '';
    if (sub5.isEmpty) {
      final String? prefSub5 = prefs.getString(_prefSub5Key);
      if (prefSub5 != null && prefSub5.isNotEmpty) {
        sub5 = prefSub5;
      }
    }
    if (sub5.isNotEmpty) {
      modifiedLink += "&aff_sub5=$sub5";
      debugPrint('WebLinkService: Добавлен aff_sub5=$sub5');
    } */

    // Добавляем sub6
    String sub6 = _linkParams['sub6'] ?? '';
    if (sub6.isEmpty) {
      final String? prefSub6 = prefs.getString(_prefSub6Key);
      if (prefSub6 != null && prefSub6.isNotEmpty) {
        sub6 = prefSub6;
      }
    }
    if (sub6.isNotEmpty) {
      modifiedLink += "&aff_sub6=$sub6";
      debugPrint('WebLinkService: Добавлен aff_sub6=$sub6');
    }

    // Добавляем sub7
/*     String sub7 = _linkParams['sub7'] ?? '';
    if (sub7.isNotEmpty) {
      modifiedLink += "&aff_sub7=$sub7";
      debugPrint('WebLinkService: Добавлен aff_sub7=$sub7');
    }
    debugPrint(
      'WebLinkService: Итоговая модифицированная ссылка оффера: $modifiedLink',
    ); */
    return modifiedLink;
  }
}
