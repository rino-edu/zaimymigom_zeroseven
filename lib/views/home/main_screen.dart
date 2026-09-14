import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../utils/locale_keys.dart';
import '../../services/app_mode_service.dart';
import '../../services/vpn_startup_service.dart';
import '../loans/loans_screen.dart';
import '../loans/showcase_screen.dart';
import '../settings/settings_screen.dart';
import 'psc_calculator_screen.dart';
import 'budget_screen.dart';
import 'goals_screen.dart';
import '../currency/currency_converter_screen.dart';
import 'calendar_screen.dart';
import 'creditworthiness_screen.dart';
import 'financial_tips_screen.dart';
import 'expense_statistics_screen.dart';
import 'faq_screen.dart';
import 'package:liquid_glass_bottom_bar/liquid_glass_bottom_bar.dart';

/// Главный экран приложения с bottom navigation bar
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  static bool _vpnDialogShown = false;
  final AppModeService _appModeService = AppModeService();

  final List<String> _screenTitles = [
    LocaleKeys.pscCalculatorTitle,
    LocaleKeys.budgetTitle,
    LocaleKeys.goalsTitle,
    LocaleKeys.userLoansTitle,
  ];

  final List<Widget> _screens = [
    PscCalculatorScreen(),
    BudgetScreen(),
    GoalsScreen(),
    const ShowcaseScreen(withScaffold: false, embedInParent: true),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getAppBarTitle() {
    return _screenTitles[_selectedIndex].tr();
  }

  @override
  void initState() {
    super.initState();

    // Попап про VPN на MainScreen — только если ещё не показали на старте
    // (когда isShowVpnScreen=false попап уже мог показать AppStartupGate).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_vpnDialogShown) return;
      if (VpnStartupService.instance.vpnWarningPopupShown) return;

      final lastResult = AppModeService().lastResult;
      final hasVpn = lastResult?.checks['VPN Status'] == true;
      if (!hasVpn) return;

      _vpnDialogShown = true;
      VpnStartupService.instance.vpnWarningPopupShown = true;
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text(LocaleKeys.vpnDialogTitle.tr()),
            content: Text(LocaleKeys.vpnDialogDescription.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(LocaleKeys.vpnDialogOk.tr()),
              ),
            ],
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Показываем кнопку info только на экране займов и в небоевом режиме
    final isLoansScreen = _selectedIndex == 3;
    final currentMode = _appModeService.currentMode;
    final showInfoButton = isLoansScreen && currentMode != AppMode.combat;
    
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        actions: showInfoButton
            ? [
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => LoansScreen.showTermsDialog(context),
                  tooltip: LocaleKeys.userLoansTermsTitle.tr(),
                ),
              ]
            : null,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              padding: EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFF0C1C3D),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Image.asset(
                  'assets/icons/icon.png',
                  width: 80,
                  height: 80,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: Text(LocaleKeys.navCalendar.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CalendarScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.currency_exchange),
              title: Text(LocaleKeys.navCurrencyConverter.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CurrencyConverterScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assessment),
              title: Text(LocaleKeys.creditworthinessTitle.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreditworthinessScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.tips_and_updates),
              title: Text(LocaleKeys.navFinancialTips.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FinancialTipsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: Text(LocaleKeys.expenseStatisticsTitle.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExpenseStatisticsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: Text(LocaleKeys.navFaq.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FaqScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(LocaleKeys.navSettings.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            const Divider(),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: LiquidGlassBottomBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        activeColor: const Color(0xFF00B0FF),
        barBlurSigma: 10,
        activeBlurSigma: 24,
        items: [
          LiquidGlassBottomBarItem(
            icon: Icons.calculate,
            activeIcon: Icons.calculate,
            label: LocaleKeys.navPscCalculator.tr(),
          ),
          LiquidGlassBottomBarItem(
            icon: Icons.account_balance_wallet,
            activeIcon: Icons.account_balance_wallet,
            label: LocaleKeys.navBudget.tr(),
          ),
          LiquidGlassBottomBarItem(
            icon: Icons.flag,
            activeIcon: Icons.flag,
            label: LocaleKeys.navGoals.tr(),
          ),
          LiquidGlassBottomBarItem(
            icon: Icons.credit_card,
            activeIcon: Icons.credit_card,
            label: LocaleKeys.navUserLoans.tr(),
            badge: 1
          ),
        ],
      ),
    );
  }
}
