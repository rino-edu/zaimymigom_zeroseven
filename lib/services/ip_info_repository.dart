import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Репозиторий для получения информации о местоположении по IP адресу
class IpInfoRepository {
  final options = BaseOptions(
    baseUrl: 'https://api.pub.dev',
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
  );

  // Singleton
  static final IpInfoRepository _instance = IpInfoRepository._internal();
  factory IpInfoRepository() => _instance;
  IpInfoRepository._internal();

  // API для получения информации о местоположении
  static const String _ipInfoApiUrl = 'https://ipinfo.io/json';
  static const String _ipApiUrl = 'http://ip-api.com/json';
  static const String _ipApiCoUrl = 'https://ipapi.co/json/';
  static const String _ipifyUrl = 'https://api64.ipify.org?format=json';

  /// Получить код страны пользователя
  Future<String> getCountry() async {
    try {
      debugPrint(
        'IpInfoRepository: Попытка #1 (ipinfo) получить код страны...',
      );
      final http.Response response = await http.get(Uri.parse(_ipInfoApiUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(response.body) as Map<String, dynamic>;
        final String countryCode = data['country'] as String? ?? 'unknown';
        if (countryCode != 'unknown') {
          debugPrint(
            'IpInfoRepository: Получен код страны из ipinfo: $countryCode',
          );
          return countryCode;
        }
      } else {
        debugPrint('IpInfoRepository: ipinfo статус ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('IpInfoRepository: ipinfo ошибка: $e');
    }
    try {
      debugPrint(
        'IpInfoRepository: Попытка #2 (ip-api) получить код страны...',
      );
      final http.Response response = await http.get(Uri.parse(_ipApiUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(response.body) as Map<String, dynamic>;
        final String countryCode = data['countryCode'] as String? ?? 'unknown';
        if (countryCode != 'unknown') {
          debugPrint(
            'IpInfoRepository: Получен код страны из ip-api: $countryCode',
          );
          return countryCode;
        }
      } else {
        debugPrint('IpInfoRepository: ip-api статус ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('IpInfoRepository: ip-api ошибка: $e');
    }
    try {
      debugPrint(
        'IpInfoRepository: Попытка #3 (ipapi.co) получить код страны...',
      );
      final http.Response response = await http.get(Uri.parse(_ipApiCoUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(response.body) as Map<String, dynamic>;
        final String countryCode = data['country_code'] as String? ?? 'unknown';
        if (countryCode != 'unknown') {
          debugPrint(
            'IpInfoRepository: Получен код страны из ipapi.co: $countryCode',
          );
          return countryCode;
        }
      } else {
        debugPrint('IpInfoRepository: ipapi.co статус ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('IpInfoRepository: ipapi.co ошибка: $e');
    }
    return 'unknown';
  }

  Future<String> getIp() async {
    try {
      debugPrint('IpInfoRepository: Попытка #1 (ipify) получить IP...');
      final http.Response response = await http.get(Uri.parse(_ipifyUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(response.body) as Map<String, dynamic>;
        final String ip = data['ip'] as String? ?? '';
        if (ip.isNotEmpty) {
          debugPrint('IpInfoRepository: Получен IP из ipify: $ip');
          return ip;
        }
      } else {
        debugPrint('IpInfoRepository: ipify статус ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('IpInfoRepository: ipify ошибка: $e');
    }
    try {
      debugPrint('IpInfoRepository: Попытка #2 (ipinfo) получить IP...');
      final http.Response response = await http.get(Uri.parse(_ipInfoApiUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(response.body) as Map<String, dynamic>;
        final String ip = data['ip'] as String? ?? '';
        if (ip.isNotEmpty) {
          debugPrint('IpInfoRepository: Получен IP из ipinfo: $ip');
          return ip;
        }
      } else {
        debugPrint('IpInfoRepository: ipinfo статус ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('IpInfoRepository: ipinfo ошибка: $e');
    }
    try {
      debugPrint('IpInfoRepository: Попытка #3 (ip-api) получить IP...');
      final http.Response response = await http.get(Uri.parse(_ipApiUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(response.body) as Map<String, dynamic>;
        final String ip = data['query'] as String? ?? '';
        if (ip.isNotEmpty) {
          debugPrint('IpInfoRepository: Получен IP из ip-api: $ip');
          return ip;
        }
      } else {
        debugPrint('IpInfoRepository: ip-api статус ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('IpInfoRepository: ip-api ошибка: $e');
    }
    return 'unknown';
  }
}
