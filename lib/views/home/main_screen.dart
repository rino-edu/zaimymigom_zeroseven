import 'package:dot_curved_bottom_nav/dot_curved_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../utils/locale_keys.dart';
import '../loans/loans_screen.dart';
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
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

/// Главный экран приложения с bottom navigation bar
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
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
    LoansScreen()
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
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFBEBEBE), Color(0xFF5F5F5F)],
                ),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Row(
                  children: [
                    Image.asset(
                      'assets/icons/icon.png',
                      width: 80,
                      height: 80,
                    ),
                    SizedBox(width: 4,),
                    Text(
                      "BudgetBox",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold
                      ),
                    )
                  ],
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
                  MaterialPageRoute(builder: (context) => const FaqScreen()),
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
      bottomNavigationBar: DotCurvedBottomNav(
        scrollController: _scrollController,
        hideOnScroll: false,
        indicatorColor: _selectedIndex == 0 ? Colors.blue : _selectedIndex == 1 ? Colors.green : _selectedIndex == 2 ? Colors.red : Color(0xff424242),
        backgroundColor: Color(0xff424242),
        animationDuration: const Duration(milliseconds: 300),
        animationCurve: Curves.ease,
        selectedIndex: _selectedIndex,
        indicatorSize: 5,
        borderRadius: 20,
        height: 70,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        items: [
          Icon(
            Icons.calculate,
            color: _selectedIndex == 0 ? Colors.blue : Colors.white,
          ),
          Icon(
            Icons.account_balance_wallet,
            color: _selectedIndex == 1 ? Colors.green : Colors.white,
          ),
          Icon(
            Icons.flag,
            color: _selectedIndex == 2 ? Colors.red : Colors.white,
          ),
          Icon(
            Icons.credit_card,
            color: _selectedIndex == 3 ? Colors.orange : Colors.white,
          ),
        ],
      ),
/*      bottomNavigationBar: LiquidGlassBottomBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        activeColor: const Color(0xFF0547BE),
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
          *//*          LiquidGlassBottomBarItem(
            icon: Icons.credit_card,
            activeIcon: Icons.credit_card,
            label: LocaleKeys.navUserLoans.tr(),
            badge: 1
          ),*//*
        ],
      ),*/
    );
  }
}
