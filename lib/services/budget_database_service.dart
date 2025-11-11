import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../models/budget_models.dart';

/// Сервис для работы с базой данных бюджета
class BudgetDatabaseService {
  static final BudgetDatabaseService _instance = BudgetDatabaseService._internal();
  factory BudgetDatabaseService() => _instance;
  BudgetDatabaseService._internal();

  static Database? _database;
  final _uuid = const Uuid();

  /// Получение экземпляра базы данных
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Инициализация базы данных
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'budget.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// Создание таблиц при первом запуске
  Future<void> _onCreate(Database db, int version) async {
    // Таблица категорий
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        parent_category_id TEXT,
        color INTEGER NOT NULL,
        icon TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Таблица доходов
    await db.execute('''
      CREATE TABLE incomes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category_id TEXT NOT NULL,
        date TEXT NOT NULL,
        description TEXT,
        is_recurring INTEGER NOT NULL DEFAULT 0,
        recurring_interval_days INTEGER,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // Таблица расходов
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category_id TEXT NOT NULL,
        date TEXT NOT NULL,
        description TEXT,
        receipt_image_path TEXT,
        is_recurring INTEGER NOT NULL DEFAULT 0,
        recurring_interval_days INTEGER,
        tags TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // Таблица лимитов бюджета
    await db.execute('''
      CREATE TABLE budget_limits (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        amount REAL NOT NULL,
        period TEXT NOT NULL,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // Создание индексов для улучшения производительности
    await db.execute('CREATE INDEX idx_incomes_date ON incomes(date)');
    await db.execute('CREATE INDEX idx_incomes_category ON incomes(category_id)');
    await db.execute('CREATE INDEX idx_expenses_date ON expenses(date)');
    await db.execute('CREATE INDEX idx_expenses_category ON expenses(category_id)');
    await db.execute('CREATE INDEX idx_categories_type ON categories(type)');

    // Создание стандартных категорий
    await _createDefaultCategories(db);
  }

  /// Создание стандартных категорий
  Future<void> _createDefaultCategories(Database db) async {
    final now = DateTime.now().toIso8601String();

    // Категории доходов
    final incomeCategories = [
      {'name': 'Зарплата', 'type': 'income', 'color': 0xFF4CAF50, 'icon': 'work'},
      {'name': 'Подработка', 'type': 'income', 'color': 0xFF2196F3, 'icon': 'attach_money'},
      {'name': 'Дивиденды', 'type': 'income', 'color': 0xFF9C27B0, 'icon': 'trending_up'},
      {'name': 'Подарки', 'type': 'income', 'color': 0xFFFF9800, 'icon': 'card_giftcard'},
      {'name': 'Прочее', 'type': 'income', 'color': 0xFF9E9E9E, 'icon': 'more_horiz'},
    ];

    // Категории расходов
    final expenseCategories = [
      {'name': 'Продукты', 'type': 'expense', 'color': 0xFF4CAF50, 'icon': 'shopping_cart'},
      {'name': 'Транспорт', 'type': 'expense', 'color': 0xFF2196F3, 'icon': 'directions_car'},
      {'name': 'Развлечения', 'type': 'expense', 'color': 0xFFFF9800, 'icon': 'movie'},
      {'name': 'Коммунальные услуги', 'type': 'expense', 'color': 0xFFF44336, 'icon': 'home'},
      {'name': 'Одежда', 'type': 'expense', 'color': 0xFFE91E63, 'icon': 'checkroom'},
      {'name': 'Здоровье', 'type': 'expense', 'color': 0xFF00BCD4, 'icon': 'local_hospital'},
      {'name': 'Образование', 'type': 'expense', 'color': 0xFF9C27B0, 'icon': 'school'},
      {'name': 'Рестораны', 'type': 'expense', 'color': 0xFFFF5722, 'icon': 'restaurant'},
      {'name': 'Прочее', 'type': 'expense', 'color': 0xFF9E9E9E, 'icon': 'more_horiz'},
    ];

    for (final cat in incomeCategories) {
      await db.insert('categories', {
        'id': _uuid.v4(),
        'name': cat['name'],
        'type': cat['type'],
        'color': cat['color'],
        'icon': cat['icon'],
        'created_at': now,
        'updated_at': now,
      });
    }

    for (final cat in expenseCategories) {
      await db.insert('categories', {
        'id': _uuid.v4(),
        'name': cat['name'],
        'type': cat['type'],
        'color': cat['color'],
        'icon': cat['icon'],
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  // ========== CATEGORIES ==========

  /// Получить все категории
  Future<List<Category>> getAllCategories({CategoryType? type}) async {
    final db = await database;
    final where = type != null ? 'type = ?' : null;
    final whereArgs = type != null ? [type.name] : null;

    final maps = await db.query(
      'categories',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );

    return maps.map((map) => Category.fromMap(map)).toList();
  }

  /// Получить категорию по ID
  Future<Category?> getCategoryById(String id) async {
    final db = await database;
    final maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Category.fromMap(maps.first);
  }

  /// Добавить категорию
  Future<String> addCategory(Category category) async {
    final db = await database;
    final id = category.id ?? _uuid.v4();
    final now = DateTime.now();

    await db.insert(
      'categories',
      category.copyWith(
        id: id,
        createdAt: now,
        updatedAt: now,
      ).toMap(),
    );

    return id;
  }

  /// Обновить категорию
  Future<void> updateCategory(Category category) async {
    final db = await database;
    await db.update(
      'categories',
      category.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  /// Удалить категорию
  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ========== INCOMES ==========

  /// Получить все доходы
  Future<List<Income>> getAllIncomes({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (startDate != null) {
      conditions.add('date >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      conditions.add('date <= ?');
      args.add(endDate.toIso8601String());
    }
    if (categoryId != null) {
      conditions.add('category_id = ?');
      args.add(categoryId);
    }

    final where = conditions.isNotEmpty ? conditions.join(' AND ') : null;

    final maps = await db.query(
      'incomes',
      where: where,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'date DESC',
    );

    return maps.map((map) => Income.fromMap(map)).toList();
  }

  /// Получить доход по ID
  Future<Income?> getIncomeById(String id) async {
    final db = await database;
    final maps = await db.query(
      'incomes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Income.fromMap(maps.first);
  }

  /// Добавить доход
  Future<String> addIncome(Income income) async {
    final db = await database;
    final id = income.id ?? _uuid.v4();
    final now = DateTime.now();

    await db.insert(
      'incomes',
      income.copyWith(
        id: id,
        createdAt: now,
        updatedAt: now,
      ).toMap(),
    );

    return id;
  }

  /// Обновить доход
  Future<void> updateIncome(Income income) async {
    final db = await database;
    await db.update(
      'incomes',
      income.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [income.id],
    );
  }

  /// Удалить доход
  Future<void> deleteIncome(String id) async {
    final db = await database;
    await db.delete('incomes', where: 'id = ?', whereArgs: [id]);
  }

  /// Получить сумму доходов за период
  Future<double> getTotalIncomes({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (startDate != null) {
      conditions.add('date >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      conditions.add('date <= ?');
      args.add(endDate.toIso8601String());
    }
    if (categoryId != null) {
      conditions.add('category_id = ?');
      args.add(categoryId);
    }

    final where = conditions.isNotEmpty ? conditions.join(' AND ') : null;

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM incomes ${where != null ? 'WHERE $where' : ''}',
      args.isNotEmpty ? args : null,
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // ========== EXPENSES ==========

  /// Получить все расходы
  Future<List<Expense>> getAllExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (startDate != null) {
      conditions.add('date >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      conditions.add('date <= ?');
      args.add(endDate.toIso8601String());
    }
    if (categoryId != null) {
      conditions.add('category_id = ?');
      args.add(categoryId);
    }

    final where = conditions.isNotEmpty ? conditions.join(' AND ') : null;

    final maps = await db.query(
      'expenses',
      where: where,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'date DESC',
    );

    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  /// Получить расход по ID
  Future<Expense?> getExpenseById(String id) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Expense.fromMap(maps.first);
  }

  /// Добавить расход
  Future<String> addExpense(Expense expense) async {
    final db = await database;
    final id = expense.id ?? _uuid.v4();
    final now = DateTime.now();

    await db.insert(
      'expenses',
      expense.copyWith(
        id: id,
        createdAt: now,
        updatedAt: now,
      ).toMap(),
    );

    return id;
  }

  /// Обновить расход
  Future<void> updateExpense(Expense expense) async {
    final db = await database;
    await db.update(
      'expenses',
      expense.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  /// Удалить расход
  Future<void> deleteExpense(String id) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  /// Получить сумму расходов за период
  Future<double> getTotalExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (startDate != null) {
      conditions.add('date >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      conditions.add('date <= ?');
      args.add(endDate.toIso8601String());
    }
    if (categoryId != null) {
      conditions.add('category_id = ?');
      args.add(categoryId);
    }

    final where = conditions.isNotEmpty ? conditions.join(' AND ') : null;

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses ${where != null ? 'WHERE $where' : ''}',
      args.isNotEmpty ? args : null,
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // ========== BUDGET LIMITS ==========

  /// Получить все лимиты бюджета
  Future<List<BudgetLimit>> getAllBudgetLimits({String? categoryId}) async {
    final db = await database;
    final where = categoryId != null ? 'category_id = ?' : null;
    final whereArgs = categoryId != null ? [categoryId] : null;

    final maps = await db.query(
      'budget_limits',
      where: where,
      whereArgs: whereArgs,
    );

    return maps.map((map) => BudgetLimit.fromMap(map)).toList();
  }

  /// Получить лимит по ID
  Future<BudgetLimit?> getBudgetLimitById(String id) async {
    final db = await database;
    final maps = await db.query(
      'budget_limits',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return BudgetLimit.fromMap(maps.first);
  }

  /// Получить лимит для категории
  Future<BudgetLimit?> getBudgetLimitForCategory(
    String categoryId,
    BudgetPeriod period,
  ) async {
    final db = await database;
    final maps = await db.query(
      'budget_limits',
      where: 'category_id = ? AND period = ?',
      whereArgs: [categoryId, period.name],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return BudgetLimit.fromMap(maps.first);
  }

  /// Добавить лимит бюджета
  Future<String> addBudgetLimit(BudgetLimit budgetLimit) async {
    final db = await database;
    final id = budgetLimit.id ?? _uuid.v4();
    final now = DateTime.now();

    await db.insert(
      'budget_limits',
      budgetLimit.copyWith(
        id: id,
        createdAt: now,
        updatedAt: now,
      ).toMap(),
    );

    return id;
  }

  /// Обновить лимит бюджета
  Future<void> updateBudgetLimit(BudgetLimit budgetLimit) async {
    final db = await database;
    await db.update(
      'budget_limits',
      budgetLimit.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [budgetLimit.id],
    );
  }

  /// Удалить лимит бюджета
  Future<void> deleteBudgetLimit(String id) async {
    final db = await database;
    await db.delete('budget_limits', where: 'id = ?', whereArgs: [id]);
  }
}

