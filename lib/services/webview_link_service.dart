import 'app_mode_service.dart';

/// Сервис формирования инициализирующей ссылки для WebView
class WebViewLinkService {
  static const String _baseUrl = 'https://cash-to-all-ru-app.ru/QjZS3drk?aff_sub1=max.credit.zaym.app';
  /// Построить ссылку с учетом режима работы приложения
  String buildInitialUrl(AppMode mode) {
    final aff4 = mode == AppMode.combat ? 'boy' : 'vpn';
    return '$_baseUrl&aff_sub4=$aff4';
  }
}