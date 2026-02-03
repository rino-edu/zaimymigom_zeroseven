import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/firebase_settings.dart';
import '../../models/offer.dart';
import '../../services/app_mode_service.dart';
import '../../services/device_data_service.dart';
import '../../services/firebase_service.dart';
import '../../services/appmetrica_service.dart';
import '../../services/web_link_service.dart';
import '../../services/server_data_service.dart';
import '../../utils/locale_keys.dart';
import '../../widgets/offer_card.dart';
import '../webview/webview_screen.dart';

/// Экран "Займы"
class LoansScreen extends StatefulWidget {
  final bool withScaffold;

  const LoansScreen({super.key, this.withScaffold = true});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  final AppModeService _appModeService = AppModeService();
  final FirebaseService _firebaseService = FirebaseService();
  List<Offer> _offers = [];
  bool _isLoading = true;
  String? _userCountry;
  FirebaseSettings? _appSettings;

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
              '[LoansScreen] Используем boy_offers из сервера для региона $regionCode: ${offers.length} офферов (до фильтрации isShow)',
            );
          } else {
            // 2. Фоллбек на Firestore.
            final firestoreOffers = await _firebaseService.getVisibleBoyOffers(
              _userCountry!,
            );
            offers = firestoreOffers;
            debugPrint(
              '[LoansScreen] Используем boy_offers из Firestore для региона $_userCountry: ${offers.length} офферов (до фильтрации isShow)',
            );
          }
        }

        // Фильтруем скрытые офферы (isShow == false)
        offers = offers.where((offer) => offer.isShow).toList();

        final appSettings =
            serverData?.settings ?? await _firebaseService.getSettings();
        setState(() {
          _offers = offers;
          _appSettings = appSettings;
          _isLoading = false;
        });
      } else {
        // Небоевой режим - сначала пробуем VPN офферы с сервера, затем Firestore.
        List<Offer> offers = [];

        final serverVpnOffers = serverData?.vpnOffers ?? [];
        if (serverVpnOffers.isNotEmpty) {
          offers = serverVpnOffers;
          debugPrint(
            '[LoansScreen] Используем vpn_offers из сервера: ${offers.length} офферов (до фильтрации isShow)',
          );
        } else {
          final firestoreOffers = await _firebaseService.getVisibleVpnOffers();
          offers = firestoreOffers;
          debugPrint(
            '[LoansScreen] Используем vpn_offers из Firestore: ${offers.length} офферов (до фильтрации isShow)',
          );
        }

        // Фильтруем скрытые офферы (isShow == false)
        offers = offers.where((offer) => offer.isShow).toList();

        final appSettings =
            serverData?.settings ?? await _firebaseService.getSettings();
        setState(() {
          _offers = offers;
          _appSettings = appSettings;
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

  Widget _buildBanner(Color bannerColor) {
    final lang = context.locale.languageCode;
    final String rawBannerText =
        (_appSettings?.getShowcaseTitleForLocale(lang).isNotEmpty == true)
        ? _appSettings!.getShowcaseTitleForLocale(lang)
        : LocaleKeys.appName.tr();
    // Обрабатываем '\n' как перенос строки, если с сервера пришла последовательность '\' + 'n'
    final String bannerText = rawBannerText.replaceAll(r'\n', '\n');

    final List<String> lines = bannerText.split('\n');
    final String firstLine = lines.isNotEmpty ? lines.first : '';
    final String? restText = (lines.length > 1)
        ? lines.sublist(1).join('\n')
        : null;

    return Container(
      width: double.infinity,
      color: bannerColor,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: RichText(
        textAlign: TextAlign.left,
        text: TextSpan(
          style: const TextStyle(color: Colors.white, height: 1.4),
          children: <TextSpan>[
            TextSpan(
              text: firstLine,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            if (restText != null && restText.isNotEmpty)
              TextSpan(
                text: '\n$restText',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsefulAdviceCard() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.loansUsefulAdviceTitle.tr(),
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7DB265),
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: "${LocaleKeys.loansUsefulAdviceSubtitle.tr()} ",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                    height: 1.2,
                  ),
                ),
                TextSpan(
                  text: LocaleKeys.loansUsefulAdviceBodyPrefix.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                    height: 1.2,
                  ),
                ),
                TextSpan(
                  text: LocaleKeys.loansUsefulAdviceBodyBoldPart.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.2,
                  ),
                ),
                TextSpan(
                  text: LocaleKeys.loansUsefulAdviceBodySuffix.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                    height: 1.2,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
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

  /// Заголовок AppBar: appbar_title_[lang] или appbar_title, иначе app_name из локали
  String _getAppBarTitle() {
    final lang = context.locale.languageCode;
    final fromSettings = _appSettings?.getAppbarTitleForLocale(lang) ?? '';
    if (fromSettings.isNotEmpty) return fromSettings;
    return LocaleKeys.appName.tr();
  }

  @override
  Widget build(BuildContext context) {
    final isCombatMode = _appModeService.currentMode == AppMode.combat;
    final body = _buildBody(context, isCombatMode);

    if (widget.withScaffold) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: const Color(0xFF7DB265),
          statusBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          appBar: isCombatMode ? null : AppBar(
            title: Text(_getAppBarTitle()),
            centerTitle: false,
            automaticallyImplyLeading: !isCombatMode,
            backgroundColor: const Color(0xFF7DB265),
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBanner(const Color(0xFF7DB265)),
                Expanded(child: body),
              ],
            ),
          ),
        ),
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

    // Список: полезный совет (если не скрыт настройкой), затем офферы
    final hideBanner = _appSettings?.hideBanner ?? false;
    return ListView(
      padding: const EdgeInsets.only(bottom: 80, top: 16, right: 16, left: 16),
      children: [
        if (!hideBanner) _buildUsefulAdviceCard(),
        ...List.generate(_offers.length, (index) {
          final offer = _offers[index];
          return OfferCard(
            offer: offer,
            onButtonTap: () => _onOfferButtonTap(offer, isCombatMode),
          );
        }),
      ],
    );
  }

  /// Обработка нажатия на кнопку оффера
  Future<void> _onOfferButtonTap(Offer offer, bool isCombatMode) async {
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
          builder: (context) =>
              WebViewScreen(offer: offer, url_link: modifiedUrl),
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
