import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../utils/locale_keys.dart';
import '../../utils/helpers.dart';
import '../../services/budget_provider.dart';
import '../../models/budget_models.dart';
import 'budget_income_form.dart';
import 'budget_expense_form.dart';

/// Экран ведения бюджета
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  BudgetPeriodFilter _periodFilter = BudgetPeriodFilter.thisMonth;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    final provider = Provider.of<BudgetProvider>(context, listen: false);
    await provider.initialize();
    _loadDataForPeriod();
  }

  void _loadDataForPeriod() {
    final provider = Provider.of<BudgetProvider>(context, listen: false);
    final now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate;

    switch (_periodFilter) {
      case BudgetPeriodFilter.today:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case BudgetPeriodFilter.thisWeek:
        final weekday = now.weekday;
        startDate = now.subtract(Duration(days: weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        endDate = startDate.add(const Duration(days: 7));
        break;
      case BudgetPeriodFilter.thisMonth:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
        break;
      case BudgetPeriodFilter.allTime:
        startDate = null;
        endDate = null;
        break;
    }

    provider.loadIncomes(startDate: startDate, endDate: endDate);
    provider.loadExpenses(startDate: startDate, endDate: endDate);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      bottom: true,
      child: Consumer<BudgetProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              //_buildSummaryCards(provider),
              _buildPeriodFilter(),
              _buildTabs(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildIncomesList(provider),
                    _buildExpensesList(provider),
                  ],
                ),
              ),
              _buildSummaryCards(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(BudgetProvider provider) {
    return FutureBuilder<Map<String, double>>(
      future: _getSummaryData(provider),
      builder: (context, snapshot) {
        final totalIncome = snapshot.data?['income'] ?? 0.0;
        final totalExpense = snapshot.data?['expense'] ?? 0.0;
        final balance = totalIncome - totalExpense;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryColumn(
                  LocaleKeys.budgetTotalIncome.tr(),
                  totalIncome,
                  Colors.green,
                  Icons.trending_up,
                ),
              ),
              Expanded(
                child: _buildSummaryColumn(
                  LocaleKeys.budgetTotalExpense.tr(),
                  totalExpense,
                  Colors.red,
                  Icons.trending_down,
                ),
              ),
              Expanded(
                child: _buildSummaryColumn(
                  LocaleKeys.budgetBalance.tr(),
                  balance,
                  balance >= 0 ? Colors.blue : Colors.orange,
                  Icons.account_balance_wallet,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, double>> _getSummaryData(BudgetProvider provider) async {
    final now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate;

    switch (_periodFilter) {
      case BudgetPeriodFilter.today:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case BudgetPeriodFilter.thisWeek:
        final weekday = now.weekday;
        startDate = now.subtract(Duration(days: weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        endDate = startDate.add(const Duration(days: 7));
        break;
      case BudgetPeriodFilter.thisMonth:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
        break;
      case BudgetPeriodFilter.allTime:
        startDate = null;
        endDate = null;
        break;
    }

    final income = await provider.getTotalIncomes(
      startDate: startDate,
      endDate: endDate,
    );
    final expense = await provider.getTotalExpenses(
      startDate: startDate,
      endDate: endDate,
    );

    return {'income': income, 'expense': expense};
  }

  Widget _buildSummaryColumn(
      String title,
      double amount,
      Color color,
      IconData icon,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          Helpers.formatNumber(amount, decimals: 0),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '₽',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }

  Widget _buildPeriodFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 0,
        children: BudgetPeriodFilter.values.map((filter) {
          final isSelected = _periodFilter == filter;
          return FilterChip(
            label: Text(
              _getPeriodFilterLabel(filter),
              style: TextStyle(color: isSelected ? Colors.white : Colors.black),
            ),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _periodFilter = filter;
                });
                _loadDataForPeriod();
              }
            },
          );
        }).toList(),
      ),
    );
  }

  String _getPeriodFilterLabel(BudgetPeriodFilter filter) {
    switch (filter) {
      case BudgetPeriodFilter.today:
        return LocaleKeys.budgetToday.tr();
      case BudgetPeriodFilter.thisWeek:
        return LocaleKeys.budgetThisWeek.tr();
      case BudgetPeriodFilter.thisMonth:
        return LocaleKeys.budgetThisMonth.tr();
      case BudgetPeriodFilter.allTime:
        return LocaleKeys.budgetAllTime.tr();
    }
  }

  Widget _buildTabs() {
    return TabBar(
      indicatorAnimation: TabIndicatorAnimation.elastic,
      dividerColor: AppColors.primary,
      indicatorWeight: 5,
      controller: _tabController,
      tabs: [
        Tab(icon: const Icon(Icons.add), text: LocaleKeys.budgetIncomes.tr()),
        Tab(
          icon: const Icon(Icons.remove),
          text: LocaleKeys.budgetExpenses.tr(),
        ),
      ],
    );
  }

  Widget _buildIncomesList(BudgetProvider provider) {
    final incomes = provider.incomes;

    if (incomes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              LocaleKeys.budgetNoIncomes.tr(),
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddIncomeDialog(context, provider),
              //icon: const Icon(Icons.add),
              label: Text(LocaleKeys.budgetAddIncome.tr()),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.centerRight,
            child: FloatingActionButton.extended(
              onPressed: () => _showAddIncomeDialog(context, provider),
              //icon: const Icon(Icons.add),
              label: Text(LocaleKeys.budgetAddIncome.tr()),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: incomes.length,
            itemBuilder: (context, index) {
              final income = incomes[index];
              return _buildIncomeCard(income, provider);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIncomeCard(Income income, BudgetProvider provider) {
    final category = provider.categories.firstWhere(
          (c) => c.id == income.categoryId,
      orElse: () => Category(name: 'Неизвестно', type: CategoryType.income),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(category.color).withValues(alpha: 0.2),
          child: Icon(
            _getIconForCategory(category.icon),
            color: Color(category.color),
          ),
        ),
        title: Text(income.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category.name),
            Text(
              Helpers.formatDate(income.date),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${Helpers.formatNumber(income.amount, decimals: 0)} ₽',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (income.isRecurring)
              Text(
                'Регулярный',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontSize: 10),
              ),
          ],
        ),
        onTap: () => _showEditIncomeDialog(context, provider, income),
        onLongPress: () => _showDeleteIncomeDialog(context, provider, income),
      ),
    );
  }

  Widget _buildExpensesList(BudgetProvider provider) {
    final expenses = provider.expenses;

    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.remove, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              LocaleKeys.budgetNoExpenses.tr(),
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddExpenseDialog(context, provider),
              //icon: const Icon(Icons.add),
              label: Text(LocaleKeys.budgetAddExpense.tr()),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.centerRight,
            child: FloatingActionButton.extended(
              onPressed: () => _showAddExpenseDialog(context, provider),
              //icon: const Icon(Icons.add),
              label: Text(LocaleKeys.budgetAddExpense.tr()),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              return _buildExpenseCard(expense, provider);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseCard(Expense expense, BudgetProvider provider) {
    final category = provider.categories.firstWhere(
          (c) => c.id == expense.categoryId,
      orElse: () => Category(name: 'Неизвестно', type: CategoryType.expense),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(category.color).withValues(alpha: 0.2),
          child: Icon(
            _getIconForCategory(category.icon),
            color: Color(category.color),
          ),
        ),
        title: Text(expense.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category.name),
            Text(
              Helpers.formatDate(expense.date),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (expense.tags.isNotEmpty)
              Wrap(
                spacing: 4,
                children: expense.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${Helpers.formatNumber(expense.amount, decimals: 0)} ₽',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (expense.isRecurring)
              Text(
                'Регулярный',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontSize: 10),
              ),
            if (expense.receiptImagePath != null)
              const Icon(Icons.receipt, size: 14),
          ],
        ),
        onTap: () => _showEditExpenseDialog(context, provider, expense),
        onLongPress: () => _showDeleteExpenseDialog(context, provider, expense),
      ),
    );
  }

  IconData _getIconForCategory(String? iconName) {
    if (iconName == null) return Icons.category;
    switch (iconName) {
      case 'work':
        return Icons.work;
      case 'attach_money':
        return Icons.attach_money;
      case 'trending_up':
        return Icons.trending_up;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'directions_car':
        return Icons.directions_car;
      case 'movie':
        return Icons.movie;
      case 'home':
        return Icons.home;
      case 'checkroom':
        return Icons.checkroom;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'school':
        return Icons.school;
      case 'restaurant':
        return Icons.restaurant;
      default:
        return Icons.category;
    }
  }

  void _showAddIncomeDialog(BuildContext context, BudgetProvider provider) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BudgetIncomeScreen(
          provider: provider,
          onSaved: () {
            _loadDataForPeriod();
          },
        ),
      ),
    );
  }

  void _showEditIncomeDialog(
      BuildContext context,
      BudgetProvider provider,
      Income income,
      ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BudgetIncomeScreen(
          provider: provider,
          income: income,
          onSaved: () {
            _loadDataForPeriod();
          },
        ),
      ),
    );
  }

  void _showDeleteIncomeDialog(
      BuildContext context,
      BudgetProvider provider,
      Income income,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocaleKeys.budgetDeleteConfirm.tr()),
        content: Text(LocaleKeys.budgetDeleteConfirmMessage.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocaleKeys.actionsCancel.tr()),
          ),
          TextButton(
            onPressed: () async {
              await provider.deleteIncome(income.id!);
              if (context.mounted) {
                Navigator.pop(context);
                _loadDataForPeriod();
              }
            },
            child: Text(LocaleKeys.actionsDelete.tr()),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, BudgetProvider provider) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BudgetExpenseScreen(
          provider: provider,
          onSaved: () {
            _loadDataForPeriod();
          },
        ),
      ),
    );
  }

  void _showEditExpenseDialog(
      BuildContext context,
      BudgetProvider provider,
      Expense expense,
      ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BudgetExpenseScreen(
          provider: provider,
          expense: expense,
          onSaved: () {
            _loadDataForPeriod();
          },
        ),
      ),
    );
  }

  void _showDeleteExpenseDialog(
      BuildContext context,
      BudgetProvider provider,
      Expense expense,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocaleKeys.budgetDeleteConfirm.tr()),
        content: Text(LocaleKeys.budgetDeleteConfirmMessage.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocaleKeys.actionsCancel.tr()),
          ),
          TextButton(
            onPressed: () async {
              await provider.deleteExpense(expense.id!);
              if (context.mounted) {
                Navigator.pop(context);
                _loadDataForPeriod();
              }
            },
            child: Text(LocaleKeys.actionsDelete.tr()),
          ),
        ],
      ),
    );
  }
}

enum BudgetPeriodFilter { today, thisWeek, thisMonth, allTime }
