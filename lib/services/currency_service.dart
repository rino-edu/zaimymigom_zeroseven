import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import 'currency_api_response.dart';

/// Сервис для работы с валютными курсами
class CurrencyService {
  static const String _baseUrl = 'https://open.er-api.com/v6/latest';
  static const Duration _cacheTimeout = Duration(minutes: 5);
  
  CurrencyApiResponse? _cachedResponse;
  DateTime? _lastUpdate;
  String? _lastBaseCurrency;

  /// Получение валютных курсов
  Future<CurrencyApiResponse> getCurrencyRates(String baseCurrency) async {
    try {
      // Проверяем кэш
      if (_cachedResponse != null &&
          _lastUpdate != null &&
          _lastBaseCurrency == baseCurrency &&
          DateTime.now().difference(_lastUpdate!) < _cacheTimeout) {
        debugPrint('Используем кэшированные валютные курсы');
        return _cachedResponse!;
      }

      debugPrint('Загружаем валютные курсы для $baseCurrency');
      
      final url = Uri.parse('$_baseUrl/$baseCurrency');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final apiResponse = CurrencyApiResponse.fromJson(jsonData);
        
        if (apiResponse.isSuccess) {
          // Сохраняем в кэш
          _cachedResponse = apiResponse;
          _lastUpdate = DateTime.now();
          _lastBaseCurrency = baseCurrency;
          
          debugPrint('Валютные курсы успешно загружены');
          return apiResponse;
        } else {
          throw Exception('API вернул ошибку: ${apiResponse.result}');
        }
      } else {
        throw Exception('HTTP ошибка: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Ошибка загрузки валютных курсов: $e');
      rethrow;
    }
  }

  /// Получение курса валюты
  Future<double?> getCurrencyRate(String baseCurrency, String targetCurrency) async {
    try {
      final response = await getCurrencyRates(baseCurrency);
      return response.getRate(targetCurrency);
    } catch (e) {
      debugPrint('Ошибка получения курса валюты: $e');
      return null;
    }
  }

  /// Конвертация суммы
  Future<double?> convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    try {
      if (fromCurrency == toCurrency) {
        return amount;
      }

      final rate = await getCurrencyRate(fromCurrency, toCurrency);
      if (rate != null) {
        return amount * rate;
      }
      return null;
    } catch (e) {
      debugPrint('Ошибка конвертации валюты: $e');
      return null;
    }
  }

  /// Получение популярных валют
  List<String> getPopularCurrencies() {
    return [
      'RUB', 'USD', 'EUR', 'GBP', 'JPY', 'CNY', 'CAD', 'AUD', 'CHF',
      'SEK', 'NOK', 'DKK', 'PLN', 'CZK', 'HUF', 'TRY', 'BRL', 'MXN',
      'INR', 'KRW', 'SGD', 'HKD', 'NZD', 'ZAR', 'AED', 'SAR', 'QAR',
      'KWD', 'BHD', 'OMR', 'JOD', 'LBP', 'EGP', 'ILS', 'UAH', 'BYN',
      'KZT', 'UZS', 'KGS', 'TJS', 'TMT', 'AZN', 'AMD', 'GEL', 'MDL',
      'RON', 'BGN', 'HRK', 'RSD', 'MKD', 'ALL', 'BAM', 'ISK', 'THB',
      'VND', 'IDR', 'MYR', 'PHP', 'BND', 'MMK', 'LAK', 'KHR', 'LKR',
      'MVR', 'NPR', 'BTN', 'BDT', 'PKR', 'AFN', 'IRR', 'IQD', 'SYP',
    ];
  }

  /// Очистка кэша
  void clearCache() {
    _cachedResponse = null;
    _lastUpdate = null;
    _lastBaseCurrency = null;
    debugPrint('Кэш валютных курсов очищен');
  }
}
