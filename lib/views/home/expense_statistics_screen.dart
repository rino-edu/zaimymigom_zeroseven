import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/locale_keys.dart';
import '../../utils/helpers.dart';
import '../../services/budget_provider.dart';
import '../../models/budget_models.dart';

/// Экран статистики расходов
class ExpenseStatisticsScreen extends StatefulWidget {
  const ExpenseStatisticsScreen({super.key});

  @override
  State<ExpenseStatisticsScreen> createState() => _ExpenseStatisticsScreenState();
}

class _ExpenseStatisticsScreenState extends State<ExpenseStatisticsScreen> {
  ExpensePeriodFilter _periodFilter = ExpensePeriodFilter.thisMonth;
  ExpenseChartType _chartType = ExpenseChartType.pie;
  String? _selectedCategoryId;
  bool _compareWithPrevious = false;
  bool _showIncomeComparison = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final provider = Provider.of<BudgetProvider>(context, listen: false);
    await provider.initialize();
    _loadDataForPeriod();
  }

  void _loadDataForPeriod() {
    final provider = Provider.of<BudgetProvider>(context, listen: false);
    final dates = _getPeriodDates(_periodFilter);
    provider.loadExpenses(
      startDate: dates['start'],
      endDate: dates['end'],
      categoryId: _selectedCategoryId,
    );
    if (_showIncomeComparison) {
      provider.loadIncomes(
        startDate: dates['start'],
        endDate: dates['end'],
      );
    }
  }

  Map<String, DateTime?> _getPeriodDates(ExpensePeriodFilter filter) {
    final now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate;

    switch (filter) {
      case ExpensePeriodFilter.today:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case ExpensePeriodFilter.thisWeek:
        final weekday = now.weekday;
        startDate = now.subtract(Duration(days: weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        endDate = startDate.add(const Duration(days: 7));
        break;
      case ExpensePeriodFilter.thisMonth:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
        break;
      case ExpensePeriodFilter.thisQuarter:
        final quarter = (now.month - 1) ~/ 3;
        startDate = DateTime(now.year, quarter * 3 + 1, 1);
        endDate = DateTime(now.year, (quarter + 1) * 3 + 1, 1);
        break;
      case ExpensePeriodFilter.thisYear:
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year + 1, 1, 1);
        break;
      case ExpensePeriodFilter.custom:
        // Для произвольного периода нужно будет добавить диалог выбора дат
        startDate = null;
        endDate = null;
        break;
    }

    return {'start': startDate, 'end': endDate};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.expenseStatisticsTitle.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _exportStatistics,
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<BudgetProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
        
            final expenses = provider.expenses;
            if (expenses.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bar_chart,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      LocaleKeys.expenseStatisticsEmpty.tr(),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              );
            }
        
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPeriodFilter(),
                  const SizedBox(height: 16),
                  _buildSummaryCards(provider),
                  const SizedBox(height: 24),
                  _buildChartTypeSelector(),
                  const SizedBox(height: 16),
                  _buildChart(provider, expenses),
                  const SizedBox(height: 24),
                  _buildTopCategories(provider, expenses),
                  const SizedBox(height: 24),
                  _buildTrends(provider),
                  const SizedBox(height: 24),
                  if (_showIncomeComparison) _buildIncomeExpenseComparison(provider),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ExpensePeriodFilter.values.map((filter) {
          final isSelected = _periodFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_getPeriodFilterLabel(filter)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _periodFilter = filter;
                  });
                  _loadDataForPeriod();
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getPeriodFilterLabel(ExpensePeriodFilter filter) {
    switch (filter) {
      case ExpensePeriodFilter.today:
        return LocaleKeys.expenseStatisticsPeriodDay.tr();
      case ExpensePeriodFilter.thisWeek:
        return LocaleKeys.expenseStatisticsPeriodWeek.tr();
      case ExpensePeriodFilter.thisMonth:
        return LocaleKeys.expenseStatisticsPeriodMonth.tr();
      case ExpensePeriodFilter.thisQuarter:
        return LocaleKeys.expenseStatisticsPeriodQuarter.tr();
      case ExpensePeriodFilter.thisYear:
        return LocaleKeys.expenseStatisticsPeriodYear.tr();
      case ExpensePeriodFilter.custom:
        return LocaleKeys.expenseStatisticsPeriodCustom.tr();
    }
  }

  Widget _buildSummaryCards(BudgetProvider provider) {
    return FutureBuilder<Map<String, double>>(
      future: _getSummaryData(provider),
      builder: (context, snapshot) {
        final totalExpenses = snapshot.data?['expenses'] ?? 0.0;
        final avgExpense = snapshot.data?['avg'] ?? 0.0;
        final categoryCount = snapshot.data?['categories']?.toDouble() ?? 0.0;

        return Row(
          children: [
            Column(
              children: [
                SizedBox(
                  width: 200,
                  height: 90,
                  child: _buildSummaryCard(
                    LocaleKeys.expenseStatisticsTotalExpenses.tr(),
                    totalExpenses,
                    Colors.red,
                    Icons.trending_down,
                  ),
                ),
                SizedBox(
                  width: 200,
                  height: 90,
                  child: _buildSummaryCard(
                    LocaleKeys.expenseStatisticsAverageExpense.tr(),
                    avgExpense,
                    Colors.orange,
                    Icons.analytics,
                  ),
                ),
              ],
            ),
            SizedBox(
              width: 140,
              height: 90,
              child: _buildSummaryCard(
                LocaleKeys.expenseStatisticsCategoriesCount.tr(),
                categoryCount,
                Colors.blue,
                Icons.category,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, double>> _getSummaryData(BudgetProvider provider) async {
    final dates = _getPeriodDates(_periodFilter);
    final totalExpenses = await provider.getTotalExpenses(
      startDate: dates['start'],
      endDate: dates['end'],
      categoryId: _selectedCategoryId,
    );

    final expenses = provider.expenses;
    final avgExpense = expenses.isNotEmpty ? totalExpenses / expenses.length : 0.0;
    final categoryIds = expenses.map((e) => e.categoryId).toSet();
    final categoryCount = categoryIds.length.toDouble();

    return {
      'expenses': totalExpenses,
      'avg': avgExpense,
      'categories': categoryCount,
    };
  }

  Widget _buildSummaryCard(String title, double value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              icon == Icons.category
                  ? value.toInt().toString()
                  : "${value.toInt().toString()} ₽",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
/*            if (icon != Icons.category)
              Text(
                '₽',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
              ),*/
          ],
        ),
      ),
    );
  }

  Widget _buildChartTypeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            Icons.pie_chart,
            color: _chartType == ExpenseChartType.pie ? Colors.blue : Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _chartType = ExpenseChartType.pie;
            });
          },
        ),
        IconButton(
          icon: Icon(
            Icons.bar_chart,
            color: _chartType == ExpenseChartType.bar ? Colors.blue : Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _chartType = ExpenseChartType.bar;
            });
          },
        ),
        IconButton(
          icon: Icon(
            Icons.show_chart,
            color: _chartType == ExpenseChartType.line ? Colors.blue : Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _chartType = ExpenseChartType.line;
            });
          },
        ),
        IconButton(
          icon: Icon(
            Icons.calendar_view_month,
            color: _chartType == ExpenseChartType.heatmap ? Colors.blue : Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _chartType = ExpenseChartType.heatmap;
            });
          },
        ),
      ],
    );
  }

  Widget _buildChart(BudgetProvider provider, List<Expense> expenses) {
    switch (_chartType) {
      case ExpenseChartType.pie:
        return _buildPieChart(provider, expenses);
      case ExpenseChartType.bar:
        return _buildBarChart(provider, expenses);
      case ExpenseChartType.line:
        return _buildLineChart(provider, expenses);
      case ExpenseChartType.heatmap:
        return _buildHeatmapChart(expenses);
    }
  }

  Widget _buildPieChart(BudgetProvider provider, List<Expense> expenses) {
    final categoryData = _getCategoryData(provider, expenses);
    if (categoryData.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 300,
      child: PieChart(
        PieChartData(
          sections: categoryData.map((data) {
            return PieChartSectionData(
              value: data['amount'] as double,
              title: '${((data['amount'] as double) / _getTotalAmount(expenses) * 100).toStringAsFixed(1)}%',
              color: Color(data['color'] as int),
              radius: 80,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            );
          }).toList(),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  Widget _buildBarChart(BudgetProvider provider, List<Expense> expenses) {
    final categoryData = _getCategoryData(provider, expenses);
    if (categoryData.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getTotalAmount(expenses) * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final categoryName = categoryData[groupIndex]['name'] as String;
                return BarTooltipItem(
                  '$categoryName\n${Helpers.formatNumber(rod.toY, decimals: 0)} ₽',
                  const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= categoryData.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      categoryData[value.toInt()]['name'] as String,
                      style: const TextStyle(fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
                reservedSize: 50,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: true),
          barGroups: categoryData.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: data['amount'] as double,
                  color: Color(data['color'] as int),
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLineChart(BudgetProvider provider, List<Expense> expenses) {
    final dailyData = _getDailyData(expenses);
    if (dailyData.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= dailyData.length) {
                    return const SizedBox.shrink();
                  }
                  final date = dailyData[value.toInt()]['date'] as DateTime;
                  return Text(
                    '${date.day}/${date.month}',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: dailyData.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value['amount'] as double);
              }).toList(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: Colors.blue.withValues(alpha: 0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmapChart(List<Expense> expenses) {
    final monthlyData = _getMonthlyHeatmapData(expenses);
    if (monthlyData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.expenseStatisticsHeatmapTitle.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: monthlyData.map((data) {
                final amount = data['amount'] as double;
                final maxAmount = monthlyData.map((d) => d['amount'] as double).reduce((a, b) => a > b ? a : b);
                final intensity = maxAmount > 0 ? (amount / maxAmount) : 0.0;
                return Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Color.lerp(Colors.green.shade100, Colors.red.shade700, intensity),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      (data['day'] as int).toString(),
                      style: TextStyle(
                        fontSize: 10,
                        color: intensity > 0.5 ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getCategoryData(BudgetProvider provider, List<Expense> expenses) {
    final Map<String, double> categoryAmounts = {};
    final Map<String, Category> categoryMap = {};

    for (final category in provider.categories) {
      if (category.type == CategoryType.expense) {
        categoryMap[category.id ?? ''] = category;
        categoryAmounts[category.id ?? ''] = 0.0;
      }
    }

    for (final expense in expenses) {
      final categoryId = expense.categoryId;
      categoryAmounts[categoryId] = (categoryAmounts[categoryId] ?? 0.0) + expense.amount;
    }

    final sortedEntries = categoryAmounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.map((entry) {
      final category = categoryMap[entry.key];
      return {
        'name': category?.name ?? 'Неизвестно',
        'amount': entry.value,
        'color': category?.color ?? 0xFF2196F3,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _getDailyData(List<Expense> expenses) {
    final Map<DateTime, double> dailyAmounts = {};

    for (final expense in expenses) {
      final date = DateTime(expense.date.year, expense.date.month, expense.date.day);
      dailyAmounts[date] = (dailyAmounts[date] ?? 0.0) + expense.amount;
    }

    final sortedDates = dailyAmounts.keys.toList()..sort();
    return sortedDates.map((date) {
      return {
        'date': date,
        'amount': dailyAmounts[date] ?? 0.0,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _getMonthlyHeatmapData(List<Expense> expenses) {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDay.day;

    final Map<int, double> dayAmounts = {};
    for (int i = 1; i <= daysInMonth; i++) {
      dayAmounts[i] = 0.0;
    }

    for (final expense in expenses) {
      if (expense.date.year == now.year && expense.date.month == now.month) {
        final day = expense.date.day;
        dayAmounts[day] = (dayAmounts[day] ?? 0.0) + expense.amount;
      }
    }

    return dayAmounts.entries.map((entry) {
      return {
        'day': entry.key,
        'amount': entry.value,
      };
    }).toList();
  }

  double _getTotalAmount(List<Expense> expenses) {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  Widget _buildTopCategories(BudgetProvider provider, List<Expense> expenses) {
    final categoryData = _getCategoryData(provider, expenses);
    final topCategories = categoryData.take(5).toList();

    if (topCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.expenseStatisticsTopCategories.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...topCategories.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              final percentage = (data['amount'] as double) / _getTotalAmount(expenses) * 100;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Color(data['color'] as int),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] as String,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(data['color'] as int),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${Helpers.formatNumber(data['amount'] as double, decimals: 0)} ₽',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTrends(BudgetProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.expenseStatisticsTrends.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, double>>(
              future: _getTrendData(provider),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final currentPeriod = snapshot.data!['current'] ?? 0.0;
                final previousPeriod = snapshot.data!['previous'] ?? 0.0;
                final change = previousPeriod > 0
                    ? ((currentPeriod - previousPeriod) / previousPeriod * 100)
                    : 0.0;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          LocaleKeys.expenseStatisticsCurrentPeriod.tr(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${Helpers.formatNumber(currentPeriod, decimals: 0)} ₽',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          LocaleKeys.expenseStatisticsPreviousPeriod.tr(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${Helpers.formatNumber(previousPeriod, decimals: 0)} ₽',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          LocaleKeys.expenseStatisticsChange.tr(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              change >= 0 ? Icons.trending_up : Icons.trending_down,
                              color: change >= 0 ? Colors.red : Colors.green,
                            ),
                            Text(
                              '${change.abs().toStringAsFixed(1)}%',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: change >= 0 ? Colors.red : Colors.green,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, double>> _getTrendData(BudgetProvider provider) async {
    final dates = _getPeriodDates(_periodFilter);
    final currentPeriod = await provider.getTotalExpenses(
      startDate: dates['start'],
      endDate: dates['end'],
    );

    // Вычисляем предыдущий период
    DateTime? previousStart;
    DateTime? previousEnd;

    if (dates['start'] != null && dates['end'] != null) {
      final duration = dates['end']!.difference(dates['start']!);
      previousEnd = dates['start']!;
      previousStart = previousEnd.subtract(duration);
    }

    final previousPeriod = await provider.getTotalExpenses(
      startDate: previousStart,
      endDate: previousEnd,
    );

    return {
      'current': currentPeriod,
      'previous': previousPeriod,
    };
  }

  Widget _buildIncomeExpenseComparison(BudgetProvider provider) {
    return FutureBuilder<Map<String, double>>(
      future: _getIncomeExpenseData(provider),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final income = snapshot.data!['income'] ?? 0.0;
        final expense = snapshot.data!['expense'] ?? 0.0;
        final balance = income - expense;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.expenseStatisticsIncomeExpenseComparison.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Icon(Icons.trending_up, color: Colors.green),
                          const SizedBox(height: 8),
                          Text(
                            LocaleKeys.budgetTotalIncome.tr(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            '${Helpers.formatNumber(income, decimals: 0)} ₽',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Icon(Icons.trending_down, color: Colors.red),
                          const SizedBox(height: 8),
                          Text(
                            LocaleKeys.budgetTotalExpense.tr(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            '${Helpers.formatNumber(expense, decimals: 0)} ₽',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      LocaleKeys.budgetBalance.tr(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${Helpers.formatNumber(balance, decimals: 0)} ₽',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: balance >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, double>> _getIncomeExpenseData(BudgetProvider provider) async {
    final dates = _getPeriodDates(_periodFilter);
    final income = await provider.getTotalIncomes(
      startDate: dates['start'],
      endDate: dates['end'],
    );
    final expense = await provider.getTotalExpenses(
      startDate: dates['start'],
      endDate: dates['end'],
    );

    return {
      'income': income,
      'expense': expense,
    };
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final provider = Provider.of<BudgetProvider>(context, listen: false);
        final expenseCategories = provider.expenseCategories;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(LocaleKeys.expenseStatisticsFilters.tr()),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CheckboxListTile(
                      title: Text(LocaleKeys.expenseStatisticsCompareWithPrevious.tr()),
                      value: _compareWithPrevious,
                      onChanged: (value) {
                        setDialogState(() {
                          _compareWithPrevious = value ?? false;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: Text(LocaleKeys.expenseStatisticsShowIncomeComparison.tr()),
                      value: _showIncomeComparison,
                      onChanged: (value) {
                        setDialogState(() {
                          _showIncomeComparison = value ?? false;
                        });
                      },
                    ),
                    const Divider(),
                    Text(
                      LocaleKeys.expenseStatisticsFilterByCategory.tr(),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      value: _selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: LocaleKeys.budgetSelectCategory.tr(),
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(LocaleKeys.actionsAll.tr()),
                        ),
                        ...expenseCategories.map((category) {
                          return DropdownMenuItem<String?>(
                            value: category.id,
                            child: Text(category.name),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          _selectedCategoryId = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      _selectedCategoryId = null;
                      _compareWithPrevious = false;
                      _showIncomeComparison = false;
                    });
                  },
                  child: Text(LocaleKeys.actionsClearFilters.tr()),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(LocaleKeys.actionsCancel.tr()),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {});
                    _loadDataForPeriod();
                  },
                  child: Text(LocaleKeys.actionsApply.tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _exportStatistics() {
    // TODO: Реализовать экспорт статистики в PDF или изображение
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LocaleKeys.expenseStatisticsExportMessage.tr()),
      ),
    );
  }
}

enum ExpensePeriodFilter {
  today,
  thisWeek,
  thisMonth,
  thisQuarter,
  thisYear,
  custom,
}

enum ExpenseChartType {
  pie,
  bar,
  line,
  heatmap,
}

