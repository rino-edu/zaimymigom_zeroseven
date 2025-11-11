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

  final List<Widget> _screens = [
    PscCalculatorScreen(),
    BudgetScreen(),
    GoalsScreen(),
    const LoansScreen(withScaffold: false),
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
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 48,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ЗаймыМигом',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
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
