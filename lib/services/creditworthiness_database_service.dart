import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../models/creditworthiness_models.dart';

/// Сервис для работы с базой данных оценок кредитоспособности
class CreditworthinessDatabaseService {
  static final CreditworthinessDatabaseService _instance = CreditworthinessDatabaseService._internal();
  factory CreditworthinessDatabaseService() => _instance;
  CreditworthinessDatabaseService._internal();

  static Database? _database;
  final _uuid = const Uuid();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'creditworthiness.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE creditworthiness_assessments (
        id TEXT PRIMARY KEY,
        monthly_income REAL NOT NULL,
        monthly_expenses REAL NOT NULL,
        savings REAL NOT NULL,
        has_regular_income INTEGER NOT NULL,
        has_current_loans INTEGER NOT NULL,
        current_loans_count INTEGER NOT NULL,
        current_loans_total REAL NOT NULL,
        has_overdue_payments INTEGER NOT NULL,
        overdue_count INTEGER NOT NULL,
        uses_budget_planning INTEGER NOT NULL,
        has_emergency_fund INTEGER NOT NULL,
        months_of_financial_stability INTEGER NOT NULL,
        score REAL NOT NULL,
        solvency_ratio REAL NOT NULL,
        available_loan_amount REAL NOT NULL,
        risk_level REAL NOT NULL,
        strengths TEXT NOT NULL,
        weaknesses TEXT NOT NULL,
        recommendations TEXT NOT NULL,
        recommended_loan_amount REAL,
        recommended_loan_term INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_creditworthiness_created ON creditworthiness_assessments(created_at DESC)');
  }

  Future<List<CreditworthinessAssessment>> getAllAssessments() async {
    final db = await database;
    final maps = await db.query('creditworthiness_assessments', orderBy: 'created_at DESC');
    return maps.map((m) => CreditworthinessAssessment.fromMap(m)).toList();
  }

  Future<CreditworthinessAssessment?> getAssessmentById(String id) async {
    final db = await database;
    final maps = await db.query(
      'creditworthiness_assessments',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CreditworthinessAssessment.fromMap(maps.first);
  }

  Future<String> addAssessment(CreditworthinessAssessment assessment) async {
    final db = await database;
    final id = assessment.id ?? _uuid.v4();
    final now = DateTime.now();
    await db.insert(
      'creditworthiness_assessments',
      assessment.copyWith(id: id, createdAt: now, updatedAt: now).toMap(),
    );
    return id;
  }

  Future<void> deleteAssessment(String id) async {
    final db = await database;
    await db.delete('creditworthiness_assessments', where: 'id = ?', whereArgs: [id]);
  }
}

