import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:zaimymigom_zeroseven/utils/locale_keys.dart';
import '../../constants/app_strings.dart';
import '../../features/combat_onboarding/services/combat_onboarding_local_state.dart';
import '../../models/settings_show_case.dart';
import '../../services/app_mode_service.dart';
import '../../services/att_service.dart';
import '../../services/server_data_service.dart';
import '../../services/firebase_service.dart';
import '../../services/appmetrica_service.dart';
import '../../services/firebase_analytics_service.dart';
import '../../models/offer.dart';
import '../../services/web_link_service.dart';
import '../../widgets/offer_card.dart';
import '../webview/webview_screen.dart';

/// Экран "Займы"
class LoansScreen extends StatefulWidget {
  final bool withScaffold;

  /// Если задан — один раз логируем `show_case_onboarding_*` (гейт / онбординг).
  final CombatLoansShowCaseReason? showCaseOnboardingReason;

  const LoansScreen({
    super.key,
    this.withScaffold = true,
    this.showCaseOnboardingReason,
  });

  @override
  State<LoansScreen> createState() => _LoansScreenState();

  /// Статический метод для показа диалога с условиями кредитования
  /// (используется из MainScreen)
  static void showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocaleKeys.userLoansTermsTitle.tr()),
        content: SingleChildScrollView(
          child: Text(
            LocaleKeys.userLoansTermsContent.tr(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(LocaleKeys.userLoansTermsUnderstood.tr()),
          ),
        ],
      ),
    );
  }
}

class _LoansScreenState extends State<LoansScreen> {
  final AppModeService _appModeService = AppModeService();
  final FirebaseService _firebaseService = FirebaseService();
  final ServerDataService _serverDataService = ServerDataService();
  List<Offer> _offers = [];
  bool _isLoading = true;
  String? _userCountry;
  String _loansAppBarTitle = '';

  @override
  void initState() {
    super.initState();
    final showCase = widget.showCaseOnboardingReason;
    if (showCase != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FirebaseAnalyticsService.logLoansShowCaseIfNeeded(showCase);
        switch (showCase) {
          case CombatLoansShowCaseReason.afterOnboardingFinish:
            AppMetricaService.reportEvent('show_case_onboarding_finish');
          case CombatLoansShowCaseReason.afterOnboardingClose:
            AppMetricaService.reportEvent('show_case_onboarding_close');
          case CombatLoansShowCaseReason.withoutOnboarding:
            AppMetricaService.reportEvent('show_case_onboarding_none');
        }
      });
    }

    _loadOffers();

    // Отправляем событие о просмотре экрана в AppMetrica
    final isCombatMode = _appModeService.currentMode == AppMode.combat;
    AppMetricaService.reportScreen(
      isCombatMode ? 'loans_combat_mode' : 'loans_non_combat_mode',
    );

        // Показ ATT-диалога только в небоевом режиме с задержкой 1 секунда
    if (!isCombatMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(seconds: 1), () {
          ATTService.instance.requestIfFirstLaunch();
        });
      });
    }

  }


  Future<void> _loadOffers() async {
    SettingsShowCase? showCaseFromServer;
    try {
      final isCombatMode = _appModeService.currentMode == AppMode.combat;
      print('LoansScreen: Loading offers, combat mode: $isCombatMode');

      List<Offer> offers = [];

      // Сначала пытаемся получить данные с сервера
      try {
        print('LoansScreen: Attempting to load offers from SERVER...');
        final serverData = await _serverDataService.fetchAllData();
        showCaseFromServer = serverData.showCase;

        if (isCombatMode) {
          // Боевой режим - загружаем boy_offers с сервера
          _userCountry = await _getUserCountry();
          print('LoansScreen: User country: $_userCountry');

          if (_userCountry != null) {
            final keyLower = _userCountry!.toLowerCase();
            final serverOffers =
                serverData.boyOffersByRegion[keyLower] ??
                serverData.boyOffersByRegion[_userCountry!] ??
                serverData.boyOffersByRegion[_userCountry!.toUpperCase()];

            if (serverOffers != null && serverOffers.isNotEmpty) {
              // Фильтруем только видимые офферы (is_show = true) и сортируем
              offers = serverOffers.where((offer) => offer.isShow).toList()
                ..sort((a, b) => a.id.compareTo(b.id));
              print(
                'LoansScreen: Loaded ${offers.length} boy offers from SERVER',
              );
            } else {
              print(
                'LoansScreen: No boy offers for "$_userCountry" in SERVER data, falling back to Firestore...',
              );
              // Fallback на Firestore
              offers = await _firebaseService.getVisibleBoyOffers(
                _userCountry!,
              );
              print(
                'LoansScreen: Loaded ${offers.length} boy offers from Firestore',
              );
            }
          } else {
            print('LoansScreen: User country is null, setting empty offers');
            offers = [];
          }
        } else {
          // Небоевой режим - загружаем vpn_offers с сервера
          print('LoansScreen: Loading VPN offers from SERVER...');
          if (serverData.vpnOffers.isNotEmpty) {
            // Фильтруем только видимые офферы (is_show = true) и сортируем
            offers =
                serverData.vpnOffers.where((offer) => offer.isShow).toList()
                  ..sort((a, b) => a.id.compareTo(b.id));
            print(
              'LoansScreen: Loaded ${offers.length} VPN offers from SERVER',
            );
          } else {
            print(
              'LoansScreen: No VPN offers in SERVER data, falling back to Firestore...',
            );
            // Fallback на Firestore
            offers = await _firebaseService.getVisibleVpnOffers();
            print(
              'LoansScreen: Loaded ${offers.length} VPN offers from Firestore',
            );
          }
        }
      } catch (serverError) {
        // Ошибка при получении данных с сервера - fallback на Firestore
        print('LoansScreen: Failed to load offers from SERVER: $serverError');
        print('LoansScreen: Falling back to Firestore...');

        if (isCombatMode) {
          // Боевой режим - загружаем boy_offers из Firestore
          _userCountry = await _getUserCountry();
          print('LoansScreen: User country: $_userCountry');

          if (_userCountry != null) {
            offers = await _firebaseService.getVisibleBoyOffers(_userCountry!);
            print(
              'LoansScreen: Loaded ${offers.length} boy offers from Firestore',
            );
          } else {
            print('LoansScreen: User country is null, setting empty offers');
            offers = [];
          }
        } else {
          // Небоевой режим - загружаем vpn_offers из Firestore
          print('LoansScreen: Loading VPN offers from Firestore...');
          offers = await _firebaseService.getVisibleVpnOffers();
          print(
            'LoansScreen: Loaded ${offers.length} VPN offers from Firestore',
          );
        }
      }

      // Гарантируем сортировку офферов по id по возрастанию перед отображением
      offers.sort((a, b) => a.id.compareTo(b.id));

      var showCase = showCaseFromServer;
      if (showCase == null || showCase.isEmpty) {
        showCase = await _firebaseService.getShowCase();
      }

      final onboardingFullyDone =
          await CombatOnboardingLocalState().isCombatOnboardingFullyCompleted();
      var barTitle = onboardingFullyDone
          ? (showCase?.onboardingTrueTitle ?? '')
          : (showCase?.onboardingFalseTitle ?? '');
      if (barTitle.isEmpty) {
        barTitle = AppStrings.loans;
      }

      setState(() {
        _offers = offers;
        _isLoading = false;
        _loansAppBarTitle = barTitle;
      });
    } catch (e) {
      print('LoansScreen: Error loading offers: $e');

      SettingsShowCase? showCase;
      try {
        showCase = await _firebaseService.getShowCase();
      } catch (_) {
        showCase = null;
      }
      final onboardingFullyDone =
          await CombatOnboardingLocalState().isCombatOnboardingFullyCompleted();
      var barTitle = onboardingFullyDone
          ? (showCase?.onboardingTrueTitle ?? '')
          : (showCase?.onboardingFalseTitle ?? '');
      if (barTitle.isEmpty) {
        barTitle = AppStrings.loans;
      }

      setState(() {
        _offers = [];
        _isLoading = false;
        _loansAppBarTitle = barTitle;
      });
    }
  }

  /// Получить страну пользователя
  Future<String?> _getUserCountry() async {
    try {
      // Получаем страну из последнего результата AppModeService
      final lastResult = _appModeService.lastResult;
      print('LoansScreen: Last result: ${lastResult?.checks}');

      if (lastResult != null && lastResult.checks.containsKey('User Country')) {
        final userCountry = lastResult.checks['User Country']?.toString();
        print('LoansScreen: User country from checks: $userCountry');
        if (userCountry != null && userCountry.isNotEmpty) {
          // Используем страну в том же регистре, что и в AppModeService (нижний регистр)
          return userCountry;
        }
      }

      // Если страна не определена, используем ru по умолчанию
      print('LoansScreen: Using default country ru');
      return 'ru';
    } catch (e) {
      print('LoansScreen: Error getting user country: $e');
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
          title: Text(
            _loansAppBarTitle.isEmpty ? AppStrings.loans : _loansAppBarTitle,
          ),
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

      // offer_open: логируем после успешной модификации ссылки и перед открытием WebView
      FirebaseAnalyticsService.logOfferOpen(
        link: offer.link,
        name: offer.name,
      );
      AppMetricaService.reportEvent(
        'offer_open',
        parameters: {'link': offer.link, 'name': offer.name},
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
