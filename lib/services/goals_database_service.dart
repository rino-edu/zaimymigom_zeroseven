import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../models/goals_models.dart';

/// Сервис для работы с базой данных целей
class GoalsDatabaseService {
  static final GoalsDatabaseService _instance = GoalsDatabaseService._internal();
  factory GoalsDatabaseService() => _instance;
  GoalsDatabaseService._internal();

  static Database? _database;
  final _uuid = const Uuid();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'goals.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        target_amount REAL NOT NULL,
        deadline TEXT,
        priority TEXT NOT NULL,
        image_path TEXT,
        current_amount REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE goal_contributions (
        id TEXT PRIMARY KEY,
        goal_id TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        comment TEXT,
        FOREIGN KEY (goal_id) REFERENCES goals (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_goal_contributions_goal ON goal_contributions(goal_id)');
    await db.execute('CREATE INDEX idx_goal_deadline ON goals(deadline)');
  }

  // Goals
  Future<List<Goal>> getAllGoals() async {
    final db = await database;
    final maps = await db.query('goals', orderBy: 'updated_at DESC');
    return maps.map((m) => Goal.fromMap(m)).toList();
  }

  Future<String> addGoal(Goal goal) async {
    final db = await database;
    final id = goal.id ?? _uuid.v4();
    final now = DateTime.now();
    await db.insert('goals', goal.copyWith(id: id, createdAt: now, updatedAt: now).toMap());
    return id;
  }

  Future<void> updateGoal(Goal goal) async {
    final db = await database;
    await db.update(
      'goals',
      goal.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<void> deleteGoal(String id) async {
    final db = await database;
    await db.delete('goal_contributions', where: 'goal_id = ?', whereArgs: [id]);
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  // Contributions
  Future<List<GoalContribution>> getContributions(String goalId) async {
    final db = await database;
    final maps = await db.query(
      'goal_contributions',
      where: 'goal_id = ?',
      whereArgs: [goalId],
      orderBy: 'date DESC',
    );
    return maps.map((m) => GoalContribution.fromMap(m)).toList();
  }

  Future<String> addContribution(GoalContribution c) async {
    final db = await database;
    final id = c.id ?? _uuid.v4();
    await db.insert('goal_contributions', c.copyWith(id: id).toMap());
    // Обновим текущую сумму в цели
    await db.rawUpdate(
      'UPDATE goals SET current_amount = current_amount + ?, updated_at = ? WHERE id = ?',
      [c.amount, DateTime.now().toIso8601String(), c.goalId],
    );
    return id;
  }

  Future<void> deleteContribution(GoalContribution c) async {
    final db = await database;
    await db.delete('goal_contributions', where: 'id = ?', whereArgs: [c.id]);
    await db.rawUpdate(
      'UPDATE goals SET current_amount = current_amount - ?, updated_at = ? WHERE id = ?',
      [c.amount, DateTime.now().toIso8601String(), c.goalId],
    );
  }
}


