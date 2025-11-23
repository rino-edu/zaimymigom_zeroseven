import 'package:flutter/foundation.dart';
import '../models/budget_models.dart' as budget_models;
import 'budget_database_service.dart';

/// Провайдер для управления состоянием бюджета
class BudgetProvider extends ChangeNotifier {
  final BudgetDatabaseService _dbService = BudgetDatabaseService();

  List<budget_models.Income> _incomes = [];
  List<budget_models.Expense> _expenses = [];
  List<budget_models.Category> _categories = [];
  List<budget_models.BudgetLimit> _budgetLimits = [];
  bool _isLoading = true;

  List<budget_models.Income> get incomes => _incomes;
  List<budget_models.Expense> get expenses => _expenses;
  List<budget_models.Category> get categories => _categories;
  List<budget_models.BudgetLimit> get budgetLimits => _budgetLimits;
  bool get isLoading => _isLoading;

  /// Получить категории доходов
  List<budget_models.Category> get incomeCategories =>
      _categories.where((c) => c.type == budget_models.CategoryType.income).toList();

  /// Получить категории расходов
  List<budget_models.Category> get expenseCategories =>
      _categories.where((c) => c.type == budget_models.CategoryType.expense).toList();

  /// Инициализация - загрузка всех данных
  Future<void> initialize() async {
    try {
      await Future.wait([
        loadCategories(),
        loadIncomes(),
        loadExpenses(),
        loadBudgetLimits(),
      ]);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== CATEGORIES ==========

  /// Загрузить все категории
  Future<void> loadCategories({budget_models.CategoryType? type}) async {
    try {
      _categories = await _dbService.getAllCategories(type: type);
      notifyListeners();
    } catch (e) {
      //debugPrint('Error loading categories: $e');
    }
  }

  /// Добавить категорию
  Future<String?> addCategory(budget_models.Category category) async {
    try {
      final id = await _dbService.addCategory(category);
      await loadCategories();
      return id;
    } catch (e) {
      //debugPrint('Error adding category: $e');
      return null;
    }
  }

  /// Обновить категорию
  Future<void> updateCategory(budget_models.Category category) async {
    try {
      await _dbService.updateCategory(category);
      await loadCategories();
    } catch (e) {
      //debugPrint('Error updating category: $e');
    }
  }

  /// Удалить категорию
  Future<void> deleteCategory(String id) async {
    try {
      await _dbService.deleteCategory(id);
      await loadCategories();
    } catch (e) {
      //debugPrint('Error deleting category: $e');
    }
  }

  // ========== INCOMES ==========

  /// Загрузить все доходы
  Future<void> loadIncomes({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    try {
      _incomes = await _dbService.getAllIncomes(
        startDate: startDate,
        endDate: endDate,
        categoryId: categoryId,
      );
      notifyListeners();
    } catch (e) {
      //debugPrint('Error loading incomes: $e');
    }
  }

  /// Добавить доход
  Future<String?> addIncome(budget_models.Income income) async {
    try {
      final id = await _dbService.addIncome(income);
      await loadIncomes();
      return id;
    } catch (e) {
      //debugPrint('Error adding income: $e');
      return null;
    }
  }

  /// Обновить доход
  Future<void> updateIncome(budget_models.Income income) async {
    try {
      await _dbService.updateIncome(income);
      await loadIncomes();
    } catch (e) {
      //debugPrint('Error updating income: $e');
    }
  }

  /// Удалить доход
  Future<void> deleteIncome(String id) async {
    try {
      await _dbService.deleteIncome(id);
      await loadIncomes();
    } catch (e) {
      //debugPrint('Error deleting income: $e');
    }
  }

  /// Получить сумму доходов за период
  Future<double> getTotalIncomes({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    try {
      return await _dbService.getTotalIncomes(
        startDate: startDate,
        endDate: endDate,
        categoryId: categoryId,
      );
    } catch (e) {
      //debugPrint('Error getting total incomes: $e');
      return 0.0;
    }
  }

  // ========== EXPENSES ==========

  /// Загрузить все расходы
  Future<void> loadExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    try {
      _expenses = await _dbService.getAllExpenses(
        startDate: startDate,
        endDate: endDate,
        categoryId: categoryId,
      );
      notifyListeners();
    } catch (e) {
      //debugPrint('Error loading expenses: $e');
    }
  }

  /// Добавить расход
  Future<String?> addExpense(budget_models.Expense expense) async {
    try {
      final id = await _dbService.addExpense(expense);
      await loadExpenses();
      return id;
    } catch (e) {
      //debugPrint('Error adding expense: $e');
      return null;
    }
  }

  /// Обновить расход
  Future<void> updateExpense(budget_models.Expense expense) async {
    try {
      await _dbService.updateExpense(expense);
      await loadExpenses();
    } catch (e) {
      //debugPrint('Error updating expense: $e');
    }
  }

  /// Удалить расход
  Future<void> deleteExpense(String id) async {
    try {
      await _dbService.deleteExpense(id);
      await loadExpenses();
    } catch (e) {
      //debugPrint('Error deleting expense: $e');
    }
  }

  /// Получить сумму расходов за период
  Future<double> getTotalExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    try {
      return await _dbService.getTotalExpenses(
        startDate: startDate,
        endDate: endDate,
        categoryId: categoryId,
      );
    } catch (e) {
      //debugPrint('Error getting total expenses: $e');
      return 0.0;
    }
  }

  // ========== BUDGET LIMITS ==========

  /// Загрузить все лимиты бюджета
  Future<void> loadBudgetLimits({String? categoryId}) async {
    try {
      _budgetLimits = await _dbService.getAllBudgetLimits(categoryId: categoryId);
      notifyListeners();
    } catch (e) {
      //debugPrint('Error loading budget limits: $e');
    }
  }

  /// Добавить лимит бюджета
  Future<String?> addBudgetLimit(budget_models.BudgetLimit budgetLimit) async {
    try {
      final id = await _dbService.addBudgetLimit(budgetLimit);
      await loadBudgetLimits();
      notifyListeners();
      return id;
    } catch (e) {
      //debugPrint('Error adding budget limit: $e');
      return null;
    }
  }

  /// Обновить лимит бюджета
  Future<void> updateBudgetLimit(budget_models.BudgetLimit budgetLimit) async {
    try {
      await _dbService.updateBudgetLimit(budgetLimit);
      await loadBudgetLimits();
      notifyListeners();
    } catch (e) {
      //debugPrint('Error updating budget limit: $e');
    }
  }

  /// Удалить лимит бюджета
  Future<void> deleteBudgetLimit(String id) async {
    try {
      await _dbService.deleteBudgetLimit(id);
      await loadBudgetLimits();
    } catch (e) {
      //debugPrint('Error deleting budget limit: $e');
    }
  }

  /// Получить лимит для категории
  Future<budget_models.BudgetLimit?> getBudgetLimitForCategory(
    String categoryId,
    budget_models.BudgetPeriod period,
  ) async {
    try {
      return await _dbService.getBudgetLimitForCategory(categoryId, period);
    } catch (e) {
      //debugPrint('Error getting budget limit: $e');
      return null;
    }
  }

  /// Проверить превышение лимита для категории
  Future<bool> isBudgetLimitExceeded(
    String categoryId,
    budget_models.BudgetPeriod period,
  ) async {
    try {
      final limit = await getBudgetLimitForCategory(categoryId, period);
      if (limit == null) return false;

      final now = DateTime.now();
      DateTime startDate;
      DateTime endDate;

      if (period == budget_models.BudgetPeriod.week) {
        final weekday = now.weekday;
        startDate = now.subtract(Duration(days: weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        endDate = startDate.add(const Duration(days: 7));
      } else {
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
      }

      final totalExpenses = await getTotalExpenses(
        startDate: startDate,
        endDate: endDate,
        categoryId: categoryId,
      );

      return totalExpenses > limit.amount;
    } catch (e) {
      //debugPrint('Error checking budget limit: $e');
      return false;
    }
  }
}

