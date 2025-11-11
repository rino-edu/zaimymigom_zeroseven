import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyConversionEntry {
  final double amount;
  final String fromCurrency;
  final String toCurrency;
  final double result;
  final DateTime timestamp;

  CurrencyConversionEntry({
    required this.amount,
    required this.fromCurrency,
    required this.toCurrency,
    required this.result,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'from': fromCurrency,
        'to': toCurrency,
        'result': result,
        'ts': timestamp.toIso8601String(),
      };

  static CurrencyConversionEntry fromJson(Map<String, dynamic> json) {
    return CurrencyConversionEntry(
      amount: (json['amount'] as num).toDouble(),
      fromCurrency: json['from'] as String,
      toCurrency: json['to'] as String,
      result: (json['result'] as num).toDouble(),
      timestamp: DateTime.parse(json['ts'] as String),
    );
  }
}

/// Провайдер для хранения избранных валютных пар и истории конвертаций
class CurrencyPrefs extends ChangeNotifier {
  static const _favoritesKey = 'currency_favorites';
  static const _historyKey = 'currency_history';
  static const _historyLimit = 20;

  final List<String> _favoritePairs = <String>[];
  final List<CurrencyConversionEntry> _history = <CurrencyConversionEntry>[];

  List<String> get favoritePairs => List.unmodifiable(_favoritePairs);
  List<CurrencyConversionEntry> get history => List.unmodifiable(_history);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _favoritePairs
      ..clear()
      ..addAll(prefs.getStringList(_favoritesKey) ?? const <String>[]);

    final historyRaw = prefs.getStringList(_historyKey) ?? const <String>[];
    _history
      ..clear()
      ..addAll(historyRaw.map((e) => CurrencyConversionEntry.fromJson(
          json.decode(e) as Map<String, dynamic>)));
    notifyListeners();
  }

  Future<void> toggleFavorite(String from, String to) async {
    final key = _pairKey(from, to);
    if (_favoritePairs.contains(key)) {
      _favoritePairs.remove(key);
    } else {
      _favoritePairs.add(key);
    }
    await _persistFavorites();
    notifyListeners();
  }

  bool isFavorite(String from, String to) => _favoritePairs.contains(_pairKey(from, to));

  Future<void> addHistory(CurrencyConversionEntry entry) async {
    _history.insert(0, entry);
    if (_history.length > _historyLimit) {
      _history.removeRange(_historyLimit, _history.length);
    }
    await _persistHistory();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history.clear();
    await _persistHistory();
    notifyListeners();
  }

  String _pairKey(String from, String to) => '${from}_$to';

  Future<void> _persistFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, _favoritePairs);
  }

  Future<void> _persistHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _historyKey,
      _history.map((e) => json.encode(e.toJson())).toList(growable: false),
    );
  }
}


