import 'app_mode_service.dart';

/// Сервис формирования инициализирующей ссылки для WebView
class WebViewLinkService {
  static const String _baseUrl = 'https://crapinka.ru/3bqQfTny?aff_sub1=ru.credit.plus.loan.app';
  /// Построить ссылку с учетом режима работы приложения
  String buildInitialUrl(AppMode mode) {
    final aff4 = mode == AppMode.combat ? 'boy' : 'vpn';
    return '$_baseUrl&aff_sub4=$aff4';
  }
}