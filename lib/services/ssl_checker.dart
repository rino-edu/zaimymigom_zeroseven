import 'dart:io';
import 'package:flutter/foundation.dart';
import 'config_service.dart';

class SSLChecker {
  /// Проверяет SSL сертификат сервера
  static Future<Map<String, dynamic>> checkServerCertificate() async {
    try {
      final serverUrl = ConfigService.getKey('server_url');
      if (serverUrl == null) {
        return {
          'status': 'error',
          'message': 'server_url не найден в конфигурации',
        };
      }

      final uri = Uri.parse(serverUrl);
      final httpClient = HttpClient();

      try {
        final request = await httpClient.getUrl(uri);
        final response = await request.close();

        return {
          'status': 'success',
          'message': 'SSL сертификат действителен',
          'statusCode': response.statusCode,
        };
      } catch (e) {
        if (e.toString().contains('CERTIFICATE_VERIFY_FAILED') ||
            e.toString().contains('HandshakeException')) {
          return {
            'status': 'error',
            'message': 'SSL сертификат истек или недействителен',
            'error': e.toString(),
            'recommendation':
                'Обратитесь к администратору сервера для обновления SSL сертификата',
          };
        }

        return {
          'status': 'error',
          'message': 'Ошибка подключения к серверу',
          'error': e.toString(),
        };
      } finally {
        httpClient.close();
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Ошибка при проверке сертификата',
        'error': e.toString(),
      };
    }
  }

  /// Проверяет доступность сервера без SSL
  static Future<Map<String, dynamic>> checkServerWithoutSSL() async {
    try {
      final serverUrl = ConfigService.getKey('server_url');
      if (serverUrl == null) {
        return {
          'status': 'error',
          'message': 'server_url не найден в конфигурации',
        };
      }

      // Заменяем https на http для проверки без SSL
      final httpUrl = serverUrl.replaceFirst('https://', 'http://');
      final uri = Uri.parse(httpUrl);
      final httpClient = HttpClient();

      try {
        final request = await httpClient.getUrl(uri);
        final response = await request.close();

        return {
          'status': 'success',
          'message': 'Сервер доступен по HTTP',
          'statusCode': response.statusCode,
          'note': 'Сервер работает, но SSL сертификат недействителен',
        };
      } catch (e) {
        return {
          'status': 'error',
          'message': 'Сервер недоступен даже по HTTP',
          'error': e.toString(),
        };
      } finally {
        httpClient.close();
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Ошибка при проверке сервера',
        'error': e.toString(),
      };
    }
  }

  /// Полная диагностика сервера
  static Future<Map<String, dynamic>> diagnoseServer() async {
    debugPrint('[SSLChecker] Начинаем диагностику сервера...');

    final sslCheck = await checkServerCertificate();
    final httpCheck = await checkServerWithoutSSL();

    final diagnosis = <String, dynamic>{
      'ssl_check': sslCheck,
      'http_check': httpCheck,
      'timestamp': DateTime.now().toIso8601String(),
      'recommendations': <String>[],
    };

    // Добавляем рекомендации
    if (sslCheck['status'] == 'error' && httpCheck['status'] == 'success') {
      diagnosis['recommendations']!.add(
        'Сервер работает, но SSL сертификат истек. '
        'Обновите SSL сертификат на сервере.',
      );
    } else if (sslCheck['status'] == 'error' &&
        httpCheck['status'] == 'error') {
      diagnosis['recommendations']!.add(
        'Сервер недоступен. Проверьте доступность сервера.',
      );
    } else if (sslCheck['status'] == 'success') {
      diagnosis['recommendations']!.add('Сервер работает корректно.');
    }

    debugPrint('[SSLChecker] Диагностика завершена: $diagnosis');
    return diagnosis;
  }
}
