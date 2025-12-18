import 'dart:io';
import 'dart:convert'; // Added missing import for json
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'config_service.dart';

class HealthChecker {
  /// Проверяет здоровье сервера через маршрут /health
  static Future<Map<String, dynamic>> checkServerHealth() async {
    try {
      final serverUrl = ConfigService.getKey('server_url');
      if (serverUrl == null) {
        return {
          'status': 'error',
          'message': 'server_url не найден в конфигурации',
          'timestamp': DateTime.now().toIso8601String(),
        };
      }

      final healthUrl = ConfigService.getFullUrl('health');
      debugPrint('[HealthChecker] Проверяем здоровье сервера: $healthUrl');

      final response = await http
          .get(
            Uri.parse(healthUrl),
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'Taxes2App/1.0',
            },
          )
          .timeout(const Duration(seconds: 10));

      final responseBody = response.body;
      debugPrint(
        '[HealthChecker] Ответ сервера: ${response.statusCode} - $responseBody',
      );

      if (response.statusCode == 200) {
        try {
          final jsonResponse = json.decode(responseBody);
          return {
            'status': 'success',
            'message': 'Сервер работает корректно',
            'statusCode': response.statusCode,
            'response': jsonResponse,
            'timestamp': DateTime.now().toIso8601String(),
          };
        } catch (e) {
          // Если ответ не JSON, но статус 200
          return {
            'status': 'success',
            'message': 'Сервер отвечает (не JSON ответ)',
            'statusCode': response.statusCode,
            'response': responseBody,
            'timestamp': DateTime.now().toIso8601String(),
          };
        }
      } else {
        return {
          'status': 'error',
          'message': 'Сервер отвечает с ошибкой',
          'statusCode': response.statusCode,
          'response': responseBody,
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      debugPrint('[HealthChecker] Ошибка при проверке здоровья сервера: $e');

      // Проверяем тип ошибки
      if (e.toString().contains('CERTIFICATE_VERIFY_FAILED') ||
          e.toString().contains('HandshakeException')) {
        return {
          'status': 'error',
          'message': 'SSL сертификат истек или недействителен',
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else if (e.toString().contains('SocketException')) {
        return {
          'status': 'error',
          'message': 'Сервер недоступен (сетевая ошибка)',
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else if (e.toString().contains('TimeoutException')) {
        return {
          'status': 'error',
          'message': 'Превышено время ожидания ответа сервера',
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else {
        return {
          'status': 'error',
          'message': 'Неизвестная ошибка при проверке здоровья сервера',
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    }
  }

  /// Проверяет здоровье сервера без SSL (для отладки)
  static Future<Map<String, dynamic>> checkServerHealthWithoutSSL() async {
    try {
      final serverUrl = ConfigService.getKey('server_url');
      if (serverUrl == null) {
        return {
          'status': 'error',
          'message': 'server_url не найден в конфигурации',
          'timestamp': DateTime.now().toIso8601String(),
        };
      }

      // Заменяем https на http
      final httpUrl = serverUrl.replaceFirst('https://', 'http://');
      final healthUrl = '$httpUrl/health';
      debugPrint(
        '[HealthChecker] Проверяем здоровье сервера (без SSL): $healthUrl',
      );

      final httpClient =
          HttpClient()
            ..badCertificateCallback = (cert, host, port) {
              debugPrint(
                '[HealthChecker] Игнорируем SSL сертификат для $host:$port',
              );
              return true;
            };

      final request = await httpClient.getUrl(Uri.parse(healthUrl));
      request.headers.set('Accept', 'application/json');
      request.headers.set('User-Agent', 'Taxes2App/1.0');

      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      final responseBody = await response.transform(utf8.decoder).join();

      debugPrint(
        '[HealthChecker] Ответ сервера (без SSL): ${response.statusCode} - $responseBody',
      );

      if (response.statusCode == 200) {
        try {
          final jsonResponse = json.decode(responseBody);
          return {
            'status': 'success',
            'message': 'Сервер работает (без SSL)',
            'statusCode': response.statusCode,
            'response': jsonResponse,
            'timestamp': DateTime.now().toIso8601String(),
            'note': 'SSL сертификат недействителен, но сервер работает',
          };
        } catch (e) {
          return {
            'status': 'success',
            'message': 'Сервер отвечает (без SSL, не JSON)',
            'statusCode': response.statusCode,
            'response': responseBody,
            'timestamp': DateTime.now().toIso8601String(),
            'note': 'SSL сертификат недействителен, но сервер работает',
          };
        }
      } else {
        return {
          'status': 'error',
          'message': 'Сервер отвечает с ошибкой (без SSL)',
          'statusCode': response.statusCode,
          'response': responseBody,
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      debugPrint(
        '[HealthChecker] Ошибка при проверке здоровья сервера (без SSL): $e',
      );
      return {
        'status': 'error',
        'message': 'Сервер недоступен даже без SSL',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Полная диагностика здоровья сервера
  static Future<Map<String, dynamic>> diagnoseServerHealth() async {
    debugPrint('[HealthChecker] Начинаем диагностику здоровья сервера...');

    final sslHealthCheck = await checkServerHealth();
    final httpHealthCheck = await checkServerHealthWithoutSSL();

    final diagnosis = <String, dynamic>{
      'ssl_health_check': sslHealthCheck,
      'http_health_check': httpHealthCheck,
      'timestamp': DateTime.now().toIso8601String(),
      'recommendations': <String>[],
    };

    // Добавляем рекомендации
    if (sslHealthCheck['status'] == 'success') {
      diagnosis['recommendations']!.add(
        'Сервер работает корректно. Можно отправлять данные.',
      );
    } else if (sslHealthCheck['status'] == 'error' &&
        httpHealthCheck['status'] == 'success') {
      diagnosis['recommendations']!.add(
        'Сервер работает, но SSL сертификат истек. '
        'Обновите SSL сертификат на сервере.',
      );
    } else if (sslHealthCheck['status'] == 'error' &&
        httpHealthCheck['status'] == 'error') {
      diagnosis['recommendations']!.add(
        'Сервер недоступен. Проверьте доступность сервера и маршрут /health.',
      );
    }

    debugPrint('[HealthChecker] Диагностика здоровья завершена: $diagnosis');
    return diagnosis;
  }
}
