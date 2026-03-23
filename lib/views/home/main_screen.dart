import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../utils/locale_keys.dart';
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
import '../webview/webview_screen.dart';
import '../../models/offer.dart';
import '../../services/app_mode_service.dart';
import '../../services/webview_link_service.dart';

/// Главный экран приложения с bottom navigation bar
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<String> _screenTitles = [
    LocaleKeys.pscCalculatorTitle,
    LocaleKeys.budgetTitle,
    LocaleKeys.goalsTitle,
    LocaleKeys.userLoansTitle,
  ];

  Widget _buildWebViewScreen() {
    final mode = AppModeService().currentMode ?? AppMode.nonCombat;
    final link = WebViewLinkService().buildInitialUrl(mode);
    final offer = Offer(
      id: 0,
      isShow: true,
      link: link,
      image: '',
      buttonText: '',
      name: tr('user_loans.title'),
      stars: '0',
    );
    return WebViewScreen(offer: offer);
  }

  List<Widget> get _screens => [
    PscCalculatorScreen(),
    BudgetScreen(),
    GoalsScreen(),
    _buildWebViewScreen(),
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
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: Text(_getAppBarTitle())),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              padding: EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFF98CA4C),
              ),
              child: Align(
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/icons/icon.png',
                  width: 200,
                  height: 200,
                ),
              ),
            ),
            ListTile(
              leading: FaIcon(FontAwesomeIcons.calendar),
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
              leading: FaIcon(FontAwesomeIcons.moneyBillTransfer),
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
              leading: FaIcon(FontAwesomeIcons.chartLine),
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
              leading: FaIcon(FontAwesomeIcons.lightbulb),
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
              leading: FaIcon(FontAwesomeIcons.chartSimple),
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
              leading: FaIcon(FontAwesomeIcons.circleQuestion),
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
              leading: FaIcon(FontAwesomeIcons.gear),
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
        activeColor: const Color(0xFF98CA4C),
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
