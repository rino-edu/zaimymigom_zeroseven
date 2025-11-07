import 'currency_rate.dart';

/// Ответ API валютных курсов
class CurrencyApiResponse {
  final String result;
  final String provider;
  final String documentation;
  final String termsOfUse;
  final int timeLastUpdateUnix;
  final String timeLastUpdateUtc;
  final int timeNextUpdateUnix;
  final String timeNextUpdateUtc;
  final int timeEolUnix;
  final String baseCode;
  final Map<String, double> rates;

  const CurrencyApiResponse({
    required this.result,
    required this.provider,
    required this.documentation,
    required this.termsOfUse,
    required this.timeLastUpdateUnix,
    required this.timeLastUpdateUtc,
    required this.timeNextUpdateUnix,
    required this.timeNextUpdateUtc,
    required this.timeEolUnix,
    required this.baseCode,
    required this.rates,
  });

  /// Создание из JSON
  factory CurrencyApiResponse.fromJson(Map<String, dynamic> json) {
    // Безопасное преобразование rates с обработкой int и double
    final ratesMap = <String, double>{};
    final rates = json['rates'] as Map<String, dynamic>;
    
    for (final entry in rates.entries) {
      final value = entry.value;
      if (value is int) {
        ratesMap[entry.key] = value.toDouble();
      } else if (value is double) {
        ratesMap[entry.key] = value;
      } else if (value is num) {
        ratesMap[entry.key] = value.toDouble();
      }
    }
    
    return CurrencyApiResponse(
      result: json['result'] as String,
      provider: json['provider'] as String,
      documentation: json['documentation'] as String,
      termsOfUse: json['terms_of_use'] as String,
      timeLastUpdateUnix: json['time_last_update_unix'] as int,
      timeLastUpdateUtc: json['time_last_update_utc'] as String,
      timeNextUpdateUnix: json['time_next_update_unix'] as int,
      timeNextUpdateUtc: json['time_next_update_utc'] as String,
      timeEolUnix: json['time_eol_unix'] as int,
      baseCode: json['base_code'] as String,
      rates: ratesMap,
    );
  }

  /// Проверка успешности ответа
  bool get isSuccess => result == 'success';

  /// Получение курса валюты
  double? getRate(String currencyCode) {
    return rates[currencyCode];
  }

  /// Получение всех валютных курсов
  List<CurrencyRate> getCurrencyRates() {
    return rates.entries
        .map((entry) => CurrencyRate.fromJson(entry.key, entry.value))
        .toList();
  }
}
