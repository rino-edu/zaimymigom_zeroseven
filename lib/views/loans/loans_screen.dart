import 'package:flutter/material.dart';
import '../../constants/app_strings.dart';
import '../../services/app_mode_service.dart';
import '../../services/device_data_service.dart';
import '../../services/firebase_service.dart';
import '../../services/appmetrica_service.dart';
import '../../models/offer.dart';
import '../../services/web_link_service.dart';
import '../../widgets/offer_card.dart';
import '../webview/webview_screen.dart';
import '../../services/server_data_service.dart';

/// Экран "Займы"
class LoansScreen extends StatefulWidget {
  final bool withScaffold;
  
  const LoansScreen({
    super.key,
    this.withScaffold = true,
  });

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  final AppModeService _appModeService = AppModeService();
  final FirebaseService _firebaseService = FirebaseService();
  List<Offer> _offers = [];
  bool _isLoading = true;
  String? _userCountry;

  @override
  void initState() {
    super.initState();
    _loadOffers();

    // Отправляем событие о просмотре экрана в AppMetrica
    final isCombatMode = _appModeService.currentMode == AppMode.combat;
    AppMetricaService.reportScreen(
      isCombatMode ? 'loans_combat_mode' : 'loans_non_combat_mode',
    );

    // Отправка данных об устройстве на сервер (в фоновом режиме)
    _sendDeviceDataInBackground();
  }

  /// Отправка данных об устройстве в фоновом режиме
  void _sendDeviceDataInBackground() {
    DeviceDataService().postInfo().catchError((error) {
      debugPrint('[LoansScreen] Ошибка отправки данных об устройстве: $error');
    });
  }

  Future<void> _loadOffers() async {
    try {
      final isCombatMode = _appModeService.currentMode == AppMode.combat;
      //print('LoansScreen: Loading offers, combat mode: $isCombatMode');

      // Пытаемся сначала получить офферы с нашего сервера.
      // Благодаря внутреннему кэшу ServerDataService, реальный GET-запрос
      // будет выполнен только один раз (при первом вызове в AppModeService),
      // а здесь мы, как правило, получим данные из кэша без повторного запроса.
      ServerDataResponse? serverData;
      try {
        serverData = await ServerDataService().fetchAllData();
      } catch (e) {
        debugPrint('[LoansScreen] Ошибка загрузки данных с сервера: $e');
      }

      if (isCombatMode) {
        // Боевой режим - загружаем boy_offers (серваку отдаем приоритет).
        _userCountry = await _getUserCountry();
        //print('LoansScreen: User country: $_userCountry');

        List<Offer> offers = [];

        if (_userCountry != null) {
          final regionCode = _userCountry!.toLowerCase();

          // 1. Пробуем взять офферы из serverData (boy_offers_<region>).
          final serverOffers = serverData?.boyOffersByRegion[regionCode] ?? [];
          if (serverOffers.isNotEmpty) {
            offers = serverOffers;
            debugPrint(
              '[LoansScreen] Используем boy_offers из сервера для региона $regionCode: ${offers.length} офферов',
            );
          } else {
            // 2. Фоллбек на Firestore.
            final firestoreOffers = await _firebaseService.getVisibleBoyOffers(
              _userCountry!,
            );
            offers = firestoreOffers;
            debugPrint(
              '[LoansScreen] Используем boy_offers из Firestore для региона $_userCountry: ${offers.length} офферов',
            );
          }
        }

        setState(() {
          _offers = offers;
          _isLoading = false;
        });
      } else {
        // Небоевой режим - сначала пробуем VPN офферы с сервера, затем Firestore.
        List<Offer> offers = [];

        final serverVpnOffers = serverData?.vpnOffers ?? [];
        if (serverVpnOffers.isNotEmpty) {
          offers = serverVpnOffers;
          debugPrint(
            '[LoansScreen] Используем vpn_offers из сервера: ${offers.length} офферов',
          );
        } else {
          final firestoreOffers = await _firebaseService.getVisibleVpnOffers();
          offers = firestoreOffers;
          debugPrint(
            '[LoansScreen] Используем vpn_offers из Firestore: ${offers.length} офферов',
          );
        }

        setState(() {
          _offers = offers;
          _isLoading = false;
        });
      }
    } catch (e) {
      //print('LoansScreen: Error loading offers: $e');
      setState(() {
        _offers = [];
        _isLoading = false;
      });
    }
  }

  /// Получить страну пользователя
  Future<String?> _getUserCountry() async {
    try {
      // Получаем страну из последнего результата AppModeService
      final lastResult = _appModeService.lastResult;
      //print('LoansScreen: Last result: ${lastResult?.checks}');

      if (lastResult != null && lastResult.checks.containsKey('User Country')) {
        final userCountry = lastResult.checks['User Country']?.toString();
        //print('LoansScreen: User country from checks: $userCountry');
        if (userCountry != null && userCountry.isNotEmpty) {
          // Используем страну в том же регистре, что и в AppModeService (нижний регистр)
          return userCountry;
        }
      }

      // Если страна не определена, используем ru по умолчанию
      //print('LoansScreen: Using default country ru');
      return 'ru';
    } catch (e) {
      //print('LoansScreen: Error getting user country: $e');
      return 'ru'; // Fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCombatMode = _appModeService.currentMode == AppMode.combat;
    final body = _buildBody(context, isCombatMode);

    if (widget.withScaffold) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.loans),
          centerTitle: true,
          // В боевом режиме не показываем кнопку назад
          automaticallyImplyLeading: !isCombatMode,
        ),
        body: body,
      );
    }
    
    return body;
  }

  Widget _buildBody(BuildContext context, bool isCombatMode) {
    // В обоих режимах показываем офферы, но из разных источников
    return _buildOffersContent(context, isCombatMode);
  }

  /// Контент с офферами для обоих режимов
  Widget _buildOffersContent(BuildContext context, bool isCombatMode) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              isCombatMode
                  ? 'Загрузка предложений по займам...'
                  : 'Загрузка предложений по кредитам...',
            ),
          ],
        ),
      );
    }

    if (_offers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCombatMode ? Icons.account_balance_wallet : Icons.vpn_lock,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              isCombatMode
                  ? 'Предложения по займам не найдены'
                  : 'кредитные предложения не найдены',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              isCombatMode
                  ? 'В данный момент нет доступных предложений по займам'
                  : 'В данный момент нет доступных кредитных предложений',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Список офферов
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80, top: 16, right: 16, left: 16),
      itemCount: _offers.length,
      itemBuilder: (context, index) {
        final offer = _offers[index];
        return OfferCard(
          offer: offer,
          onButtonTap: () => _onOfferButtonTap(offer, isCombatMode),
        );
      },
    );
  }

  /// Обработка нажатия на кнопку оффера
  Future<void> _onOfferButtonTap(Offer offer, bool isCombatMode) async{
    final webLinkService = WebLinkService();
    if (offer.link.isNotEmpty) {
      String modifiedUrl = "";
      try {
        // Проверяем текущий режим приложения
        if (_appModeService.currentMode == null) {
          debugPrint("LoansScreen: Режим не определен");
          return;
        }
        debugPrint(
          "LoansScreen: Текущий режим приложения: ${_appModeService.currentMode?.name}",
        );
        debugPrint(
          "LoansScreen: WebLinkService.isBoyMode: ${webLinkService.isBoyMode}",
        );

        debugPrint("LoansScreen: Оригинальная ссылка оффера: ${offer.link}");
        modifiedUrl = await webLinkService.generateModifiedOfferLink(
          offer.link,
        );
        debugPrint("LoansScreen: Модифицированная ссылка: $modifiedUrl");

        // Проверяем валидность ссылки перед открытием
        try {
          final uri = Uri.parse(modifiedUrl);
          if (!uri.hasScheme) {
            debugPrint(
              "LoansScreen: Ссылка не имеет схемы, добавляем https://",
            );
            modifiedUrl = 'https://$modifiedUrl';
            debugPrint("LoansScreen: Исправленная ссылка: $modifiedUrl");
          }
        } catch (e) {
          debugPrint("LoansScreen: Ошибка парсинга ссылки: $e");
          return;
        }
      } catch (e) {
        debugPrint("LoansScreen: Ошибка при модификации ссылки: $e");
        return;
      }

      if (modifiedUrl.isEmpty) {
        debugPrint("LoansScreen: Модифицированная ссылка пуста.");
        return;
      }



      // Отправляем событие в AppMetrica
      AppMetricaService.reportEvent(
        'offer_clicked',
        parameters: {
          'offer_id': offer.id.toString(),
          'offer_name': offer.name,
          'mode': isCombatMode ? 'combat' : 'non_combat',
          'offer_type': isCombatMode ? 'loan' : 'vpn',
        },
      );

      // Открываем WebView с ссылкой оффера
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WebViewScreen(
            offer: offer,
            url_link: modifiedUrl,
          ),
        ),
      );
    } else {
      // Отправляем событие об ошибке в AppMetrica
      AppMetricaService.reportError(
        'Empty offer link',
        reason: '${offer.name} has empty link',
      );

      // Показываем сообщение, если ссылка пустая
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCombatMode
                ? 'Ссылка на займ недоступна: ${offer.name}'
                : 'Ссылка на VPN недоступна: ${offer.name}',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
