import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/firebase_settings.dart';
import '../models/offer.dart';
import '../models/settings_show_case.dart';

/// Ответ сервера со всеми данными (аналогом коллекций Firestore)
class ServerDataResponse {
  final Map<String, List<Offer>> boyOffersByRegion;
  final List<Offer> vpnOffers;
  final FirebaseSettings? settings;
  /// Аналог `settings/show_case` на сервере.
  final SettingsShowCase? showCase;

  ServerDataResponse({
    required this.boyOffersByRegion,
    required this.vpnOffers,
    required this.settings,
    required this.showCase,
  });
}

/// Сервис для получения и парсинга данных с нашего сервера
class ServerDataService {
  static final ServerDataService _instance = ServerDataService._internal();
  factory ServerDataService() => _instance;
  ServerDataService._internal();

  final Dio _dio = Dio();

  // Кэш данных
  ServerDataResponse? _cachedData;
  DateTime? _cacheTimestamp;

  // Completer для синхронизации параллельных запросов
  Completer<ServerDataResponse>? _pendingRequest;

  // TTL кэша: 5 минут
  static const Duration _cacheTTL = Duration(minutes: 5);

  /// Загрузить все данные с сервера `/api/client/get-all`
  ///
  /// - Строит URL на основе `server_url` из `config.json`
  /// - Делает GET-запрос (если кэш устарел или отсутствует)
  /// - Логирует сырой ответ
  /// - Парсит JSON в `FirebaseSettings` и `Offer` по аналогии с `FirebaseService`
  ///
  /// В случае HTTP 500 или других ошибок:
  /// - логирует ошибку
  /// - выбрасывает [Exception] с сообщением об ошибке
  ///
  /// [forceRefresh] - принудительно обновить данные, игнорируя кэш
  Future<ServerDataResponse> fetchAllData({bool forceRefresh = false}) async {
    // Проверяем кэш, если не требуется принудительное обновление
    if (!forceRefresh && _cachedData != null && _cacheTimestamp != null) {
      final cacheAge = DateTime.now().difference(_cacheTimestamp!);
      if (cacheAge < _cacheTTL) {
        if (kDebugMode) {
          debugPrint(
            'ServerDataService: используем кэш (возраст: ${cacheAge.inSeconds}с, TTL: ${_cacheTTL.inSeconds}с)',
          );
        }
        return _cachedData!;
      } else {
        if (kDebugMode) {
          debugPrint(
            'ServerDataService: кэш устарел (возраст: ${cacheAge.inSeconds}с), обновляем...',
          );
        }
      }
    }

    // Если запрос уже выполняется, возвращаем его Future
    if (_pendingRequest != null) {
      if (kDebugMode) {
        debugPrint('ServerDataService: запрос уже выполняется, ждём...');
      }
      return _pendingRequest!.future;
    }

    // Создаём новый Completer для синхронизации
    _pendingRequest = Completer<ServerDataResponse>();

    try {
      final url = "https://com-kredit7-dney-firebase.ru/api/client/get-all";

      if (kDebugMode) {
        debugPrint('ServerDataService: запрос к $url');
      }

      // Защита от "вечного" ожидания, если сервер/сеть недоступны.
      final response = await _dio.get(url).timeout(
        const Duration(seconds: 25),
      );

      // Проверка на статус 500 и другие серверные ошибки
      if (response.statusCode != null && response.statusCode! >= 500) {
        final errorMessage =
            'ServerDataService: сервер вернул ошибку ${response.statusCode}';
        debugPrint(errorMessage);
        throw Exception(errorMessage);
      }

      // Логируем сырой ответ
      if (kDebugMode) {
        debugPrint(
          'ServerDataService: сырой ответ:\n${const JsonEncoder.withIndent('  ').convert(response.data)}',
        );
      }

      final data = response.data as Map<String, dynamic>;

      // Парсим settings
      FirebaseSettings? settings;
      final settingsList = data['settings'] as List<dynamic>?;
      if (settingsList != null && settingsList.isNotEmpty) {
        final first = settingsList.first as Map<String, dynamic>;
        final json = first['json'] as Map<String, dynamic>? ?? {};
        settings = FirebaseSettings.fromFirestore(json);

        if (kDebugMode) {
          debugPrint('ServerDataService: распарсенные settings:');
          settings.logData();
        }
      }

      // Парсим show_case (документ settings/show_case)
      SettingsShowCase? showCase;
      final showCaseList =
          (data['show_case'] ?? data['showCase']) as List<dynamic>?;
      if (showCaseList != null && showCaseList.isNotEmpty) {
        final first = showCaseList.first as Map<String, dynamic>;
        final json = first['json'] as Map<String, dynamic>? ?? {};
        showCase = SettingsShowCase.fromMap(json);
        if (kDebugMode) {
          debugPrint(
            'ServerDataService: show_case titles true="${showCase.onboardingTrueTitle}" false="${showCase.onboardingFalseTitle}"',
          );
        }
      }

      // Парсим vpn_offers
      final vpnOffersRaw = data['vpn_offers'] as List<dynamic>? ?? [];
      final vpnOffers = <Offer>[];
      for (final item in vpnOffersRaw) {
        final map = item as Map<String, dynamic>;
        final json = map['json'] as Map<String, dynamic>? ?? {};
        final name = map['name']?.toString() ?? '';
        final offer = Offer.fromFirestore(json, name);
        if (kDebugMode) {
          offer.logData();
        }
        vpnOffers.add(offer);
      }

      // Парсим boy_offers_<region>
      final boyOffersByRegion = <String, List<Offer>>{};
      for (final entry in data.entries) {
        final key = entry.key;
        if (key.startsWith('boy_offers_')) {
          final regionCode = key.substring('boy_offers_'.length);
          final rawList = entry.value as List<dynamic>? ?? [];
          final offers = <Offer>[];

          for (final item in rawList) {
            final map = item as Map<String, dynamic>;
            final json = map['json'] as Map<String, dynamic>? ?? {};
            final name = map['name']?.toString() ?? '';
            final offer = Offer.fromFirestore(json, name);
            if (kDebugMode) {
              offer.logData();
            }
            offers.add(offer);
          }

          boyOffersByRegion[regionCode.toLowerCase()] = offers;
        }
      }

      if (kDebugMode) {
        debugPrint(
          'ServerDataService: всего регионов с boy_offers: ${boyOffersByRegion.length}',
        );
        debugPrint('ServerDataService: всего vpn_offers: ${vpnOffers.length}');
      }

      final result = ServerDataResponse(
        boyOffersByRegion: boyOffersByRegion,
        vpnOffers: vpnOffers,
        settings: settings,
        showCase: showCase,
      );

      // Сохраняем в кэш
      _cachedData = result;
      _cacheTimestamp = DateTime.now();

      if (kDebugMode) {
        debugPrint('ServerDataService: данные сохранены в кэш');
      }

      // Завершаем Completer успехом
      _pendingRequest!.complete(result);
      _pendingRequest = null;

      return result;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final body = e.response?.data;

      final errorMessage = StringBuffer()
        ..write('ServerDataService: ошибка запроса к серверу');
      if (statusCode != null) {
        errorMessage.write(' (statusCode=$statusCode)');
      }
      if (body != null) {
        errorMessage.write(', body=$body');
      }

      debugPrint(errorMessage.toString());

      // Завершаем Completer ошибкой
      _pendingRequest!.completeError(Exception(errorMessage.toString()));
      _pendingRequest = null;

      throw Exception(errorMessage.toString());
    } catch (e) {
      final errorMessage = 'ServerDataService: непредвиденная ошибка: $e';
      debugPrint(errorMessage);

      // Завершаем Completer ошибкой (если ещё не завершён)
      _pendingRequest?.completeError(Exception(errorMessage));
      _pendingRequest = null;

      throw Exception(errorMessage);
    }
  }

  /// Принудительно обновить данные (игнорировать кэш)
  Future<ServerDataResponse> refreshData() {
    return fetchAllData(forceRefresh: true);
  }

  /// Очистить кэш
  void clearCache() {
    _cachedData = null;
    _cacheTimestamp = null;
    if (kDebugMode) {
      debugPrint('ServerDataService: кэш очищен');
    }
  }

  /// Получить кэшированные данные (без запроса к серверу)
  /// Возвращает null, если кэш пуст или устарел
  ServerDataResponse? getCachedData() {
    if (_cachedData == null || _cacheTimestamp == null) {
      return null;
    }

    final cacheAge = DateTime.now().difference(_cacheTimestamp!);
    if (cacheAge >= _cacheTTL) {
      return null; // Кэш устарел
    }

    return _cachedData;
  }
}
