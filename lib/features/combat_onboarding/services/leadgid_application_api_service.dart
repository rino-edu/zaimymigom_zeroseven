import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../config/leadgid_account_token.dart';
import '../utils/leadgid_phone_formatter.dart';

/// Создание заявки в LeadGid Universal API.
///
/// POST https://api.leadgid.com/universal/vl/ru/applications
/// Документация: https://my.leadgid.com/tools/universal-api/doc/ru/ru
class LeadgidApplicationApiService {
  static const String _baseUrl = 'https://api.leadgid.com/universal';
  static const String _applicationsPath = '/v1/ru/applications';
  static const String _accountTokenHeader = 'X-ACCOUNT-TOKEN';

  final Dio _dio;

  LeadgidApplicationApiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: const {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            );

  /// [normalizedRuPhone] — формат `+7XXXXXXXXXX` из онбординга.
  ///
  /// Ошибки логируются и не пробрасываются наружу (онбординг не блокируется).
  Future<void> createApplicationFromNormalizedPhone(
    String normalizedRuPhone,
  ) async {
    if (!LeadGidAccountToken.isConfigured) {
      debugPrint(
        'LeadgidApplicationApiService: пропуск — задайте X-ACCOUNT-TOKEN '
        'в lib/config/leadgid_account_token.dart',
      );
      return;
    }

    final apiPhone = LeadGidPhoneFormatter.toApiPhone(normalizedRuPhone);
    if (apiPhone == null) {
      debugPrint(
        'LeadgidApplicationApiService: неверный формат телефона для API: '
        '$normalizedRuPhone',
      );
      return;
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _applicationsPath,
        data: <String, dynamic>{'phone': apiPhone},
        options: Options(
          headers: <String, dynamic>{
            _accountTokenHeader: LeadGidAccountToken.accountToken,
          },
        ),
      );

      debugPrint(
        'LeadgidApplicationApiService: заявка создана, status=${response.statusCode}, '
        'phone=$apiPhone',
      );
    } on DioException catch (e) {
      debugPrint(
        'LeadgidApplicationApiService: ошибка ${e.response?.statusCode} '
        '${e.response?.data ?? e.message}',
      );
    } catch (e, st) {
      debugPrint('LeadgidApplicationApiService: $e');
      debugPrint('$st');
    }
  }
}
