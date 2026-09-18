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
  static const String _prefSub6Key = 'sub6';

  /// Ключ для хранения причины онбординга (aff_sub10).
  /// Объявлен публично, чтобы LoansScreen мог писать значение напрямую.
  static const String prefSub10Key = 'sub10';

  /// aff_sub10 уже был добавлен в ссылку (первый оффер или main_link).
  static const String prefAffSub10AppliedKey = 'aff_sub10_applied';

  // Основная ссылка из конфигурации
  String _mainLink = '';
  bool isBoyMode = false;
  AppMode? _currentAppMode;

  // Параметры для формирования ссылки
  final Map<String, String> _linkParams = {
    'sub6': '',
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

  /// Сохранение параметров в SharedPreferences
  Future<void> _saveParamsToPrefs() async {
    debugPrint('WebLinkService: Кеширование параметров в SharedPreferences');
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefSub6Key, _linkParams['sub6'] ?? '');
      debugPrint(
        'WebLinkService: Параметры успешно сохранены в SharedPreferences',
      );
    } catch (e) {
      debugPrint('WebLinkService: Ошибка при сохранении параметров: $e');
    }
  }

  /// aff_sub10 ещё не подставляли в ссылку и значение задано в prefs.
  Future<bool> _shouldAttachAffSub10(SharedPreferences prefs) async {
    if (prefs.getBool(prefAffSub10AppliedKey) == true) {
      return false;
    }
    final sub10 = prefs.getString(prefSub10Key) ?? '';
    return sub10.isNotEmpty;
  }

  Future<void> _markAffSub10Applied(SharedPreferences prefs) async {
    await prefs.setBool(prefAffSub10AppliedKey, true);
    debugPrint('WebLinkService: aff_sub10 помечен как подставленный в ссылку');
  }

  /// Формирование основной ссылки с параметрами
  Future<String> buildMainLink() async {
    debugPrint('WebLinkService: Начало формирования основной ссылки');

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

    _linkParams['sub6'] = await AppMetricaService.getDeviceIdHash();

    // Сохранение параметров
    await _saveParamsToPrefs();

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Обработка параметра aff_sub4 на основе определенного режима
    if (isBoyMode) {
      _mainLink = _mainLink.replaceFirst(
        "aff_sub4=vpn",
        "aff_sub4=boy",
      );
      debugPrint(
        'WebLinkService: Режим boy - изменено aff_sub4=vpn на aff_sub4=boy',
      );
    } else {
      debugPrint('WebLinkService: Режим vpn - оставляем aff_sub4=vpn');
    }

    // Добавление sub6
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

    // aff_sub10 — один раз, пока не был подставлен в любую ссылку
    if (await _shouldAttachAffSub10(prefs)) {
      final String sub10 = prefs.getString(prefSub10Key)!;
      _mainLink += "&aff_sub10=$sub10";
      await _markAffSub10Applied(prefs);
      debugPrint('WebLinkService: Добавлен &aff_sub10=$sub10');
    } else {
      debugPrint(
        'WebLinkService: aff_sub10 не добавлен (уже подставляли или пусто)',
      );
    }

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

  /// Запасной URL веб-витрины, если `showCaseLink` пустой/невалидный.
  static const String fallbackShowCaseLink =
      'https://crapinka.ru/Zp7h5HDc?aff_sub1=com.kredit7.dney';

  /// Нормализует схему URL (добавляет https:// при необходимости).
  String _ensureHttpsScheme(String link) {
    try {
      final uri = Uri.parse(link);
      if (!uri.hasScheme) {
        return 'https://$link';
      }
      return link;
    } catch (_) {
      return link;
    }
  }

  /// Ставит/заменяет query-параметр в URL.
  String _upsertQueryParam(String link, String key, String value) {
    final uri = Uri.parse(link);
    final params = Map<String, String>.from(uri.queryParameters);
    params[key] = value;
    return uri.replace(queryParameters: params).toString();
  }

  /// Модифицирует ссылку веб-витрины: те же трекинг-параметры, что у офферов,
  /// плюс `aff_sub4=boy` (боевой) / `aff_sub4=vpn` (небоевой).
  Future<String> generateModifiedShowCaseLink(String? showCaseLink) async {
    final raw = (showCaseLink ?? '').trim();
    var link = _ensureHttpsScheme(raw.isNotEmpty ? raw : fallbackShowCaseLink);
    debugPrint('WebLinkService: Модификация showCaseLink: $link');

    if (_currentAppMode == null) {
      final AppMode? modeResult = AppModeService().currentMode;
      isBoyMode = modeResult == AppMode.combat;
      _currentAppMode = modeResult;
      debugPrint('WebLinkService: Режим определён как ${modeResult?.name}');
    }

    final affSub4 = isBoyMode ? 'boy' : 'vpn';
    link = _upsertQueryParam(link, 'aff_sub4', affSub4);
    debugPrint('WebLinkService: Установлен aff_sub4=$affSub4');

    // Как у офферов: aff_sub6 / aff_sub10 только в боевом режиме.
    if (!isBoyMode) {
      debugPrint(
        'WebLinkService: VPN режим — showCaseLink без aff_sub6/aff_sub10: $link',
      );
      return link;
    }

    if ((_linkParams['sub6'] ?? '').isEmpty) {
      _linkParams['sub6'] = await AppMetricaService.getDeviceIdHash();
      await _saveParamsToPrefs();
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String sub6 = _linkParams['sub6'] ?? '';
    if (sub6.isEmpty) {
      final String? prefSub6 = prefs.getString(_prefSub6Key);
      if (prefSub6 != null && prefSub6.isNotEmpty) {
        sub6 = prefSub6;
      }
    }
    if (sub6.isNotEmpty) {
      link = _upsertQueryParam(link, 'aff_sub6', sub6);
      debugPrint('WebLinkService: Установлен aff_sub6=$sub6');
    }

    if (await _shouldAttachAffSub10(prefs)) {
      final String sub10 = prefs.getString(prefSub10Key)!;
      link = _upsertQueryParam(link, 'aff_sub10', sub10);
      await _markAffSub10Applied(prefs);
      debugPrint('WebLinkService: Установлен aff_sub10=$sub10');
    } else {
      debugPrint(
        'WebLinkService: aff_sub10 не добавлен (уже подставляли или пусто)',
      );
    }

    debugPrint('WebLinkService: Итоговая showCaseLink: $link');
    return link;
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
    if ((_linkParams['sub6'] ?? '').isEmpty) {
      _linkParams['sub6'] = await AppMetricaService.getDeviceIdHash();
      await _saveParamsToPrefs();
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String modifiedLink = offerLink;

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

    // aff_sub10 — один раз на первый оффер (или main), в любой сессии
    if (await _shouldAttachAffSub10(prefs)) {
      final String sub10 = prefs.getString(prefSub10Key)!;
      modifiedLink += "&aff_sub10=$sub10";
      await _markAffSub10Applied(prefs);
      debugPrint('WebLinkService: Добавлен aff_sub10=$sub10');
    } else {
      debugPrint(
        'WebLinkService: aff_sub10 не добавлен (уже подставляли или пусто)',
      );
    }

    debugPrint(
      'WebLinkService: Итоговая модифицированная ссылка оффера: $modifiedLink',
    );
    return modifiedLink;
  }
}