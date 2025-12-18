import 'dart:convert';
import 'package:flutter/services.dart';

class ConfigService {
  static Map<String, dynamic>? _config;

  static Future<void> loadConfig() async {
    if (_config != null) return;
    final String jsonString = await rootBundle.loadString(
      'assets/strings/config.json',
    );
    _config = json.decode(jsonString);
  }

  static String? getKey(String key) {
    return _config != null ? _config![key] as String? : null;
  }

  static String getFullUrl(String route) {
    final serverUrl = getKey('server_url');
    if (serverUrl == null) {
      throw Exception('server_url не найден в конфигурации');
    }

    // Убираем trailing slash из serverUrl если есть
    final baseUrl =
        serverUrl.endsWith('/')
            ? serverUrl.substring(0, serverUrl.length - 1)
            : serverUrl;

    // Добавляем route с leading slash если его нет
    final routePath = route.startsWith('/') ? route : '/$route';

    return '$baseUrl$routePath';
  }
}
