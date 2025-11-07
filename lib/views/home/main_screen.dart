import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../utils/locale_keys.dart';
import '../loans/loans_screen.dart';
import 'psc_calculator_screen.dart';
import 'budget_screen.dart';
import 'goals_screen.dart';
import 'user_loans_screen.dart';

/// Главный экран приложения с bottom navigation bar
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    PscCalculatorScreen(),
    BudgetScreen(),
    GoalsScreen(),
    LoansScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.calculate),
            label: LocaleKeys.navPscCalculator.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet),
            label: LocaleKeys.navBudget.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.flag),
            label: LocaleKeys.navGoals.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.credit_card),
            label: LocaleKeys.navUserLoans.tr(),
          ),
        ],
      ),
    );
  }
}

