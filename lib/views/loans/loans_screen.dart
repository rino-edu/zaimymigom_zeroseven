import 'package:flutter/material.dart';
import '../../constants/app_strings.dart';
import '../../services/app_mode_service.dart';
import '../../services/firebase_service.dart';
import '../../services/appmetrica_service.dart';
import '../../models/offer.dart';
import '../../widgets/offer_card.dart';
import '../webview/webview_screen.dart';

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
  }

  Future<void> _loadOffers() async {
    try {
      final isCombatMode = _appModeService.currentMode == AppMode.combat;
      print('LoansScreen: Loading offers, combat mode: $isCombatMode');

      if (isCombatMode) {
        // Боевой режим - загружаем boy_offers
        _userCountry = await _getUserCountry();
        print('LoansScreen: User country: $_userCountry');

        if (_userCountry != null) {
          final offers = await _firebaseService.getVisibleBoyOffers(
            _userCountry!,
          );
          print('LoansScreen: Loaded ${offers.length} boy offers');
          setState(() {
            _offers = offers; // Уже отфильтрованы и отсортированы в сервисе
            _isLoading = false;
          });
        } else {
          print('LoansScreen: User country is null, setting empty offers');
          setState(() {
            _offers = [];
            _isLoading = false;
          });
        }
      } else {
        // Небоевой режим - загружаем vpn_offers
        print('LoansScreen: Loading VPN offers');
        final offers = await _firebaseService.getVisibleVpnOffers();
        print('LoansScreen: Loaded ${offers.length} VPN offers');
        setState(() {
          _offers = offers; // Уже отфильтрованы и отсортированы в сервисе
          _isLoading = false;
        });
      }
    } catch (e) {
      print('LoansScreen: Error loading offers: $e');
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
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            await navigator.maybePop();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.loans),
            centerTitle: true,
            // В боевом режиме не показываем кнопку назад
            automaticallyImplyLeading: !isCombatMode,
          ),
          body: body,
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
                  : 'Загрузка VPN предложений...',
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
                  : 'VPN предложения не найдены',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              isCombatMode
                  ? 'В данный момент нет доступных предложений по займам'
                  : 'В данный момент нет доступных VPN предложений',
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
  void _onOfferButtonTap(Offer offer, bool isCombatMode) {
    if (offer.link.isNotEmpty) {
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
        MaterialPageRoute(builder: (context) => WebViewScreen(offer: offer)),
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
