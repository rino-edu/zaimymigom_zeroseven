import 'package:flutter/foundation.dart';
import '../models/creditworthiness_models.dart';
import 'creditworthiness_database_service.dart';
import 'creditworthiness_calculator.dart';

class CreditworthinessProvider extends ChangeNotifier {
  final CreditworthinessDatabaseService _db = CreditworthinessDatabaseService();

  bool _isLoading = true;
  List<CreditworthinessAssessment> _assessments = [];

  bool get isLoading => _isLoading;
  List<CreditworthinessAssessment> get assessments => _assessments;

  Future<void> initialize() async {
    try {
      _isLoading = true;
      notifyListeners();
      await loadAssessments();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAssessments() async {
    _assessments = await _db.getAllAssessments();
    notifyListeners();
  }

  Future<String?> addAssessment(CreditworthinessAnswers answers) async {
    try {
      final result = CreditworthinessCalculator.calculate(answers);
      final now = DateTime.now();
      final assessment = CreditworthinessAssessment(
        answers: answers,
        result: result,
        createdAt: now,
        updatedAt: now,
      );
      final id = await _db.addAssessment(assessment);
      await loadAssessments();
      return id;
    } catch (e) {
      //debugPrint('addAssessment error: $e');
      return null;
    }
  }

  Future<void> deleteAssessment(String id) async {
    try {
      await _db.deleteAssessment(id);
      await loadAssessments();
    } catch (e) {
      //debugPrint('deleteAssessment error: $e');
    }
  }
}

