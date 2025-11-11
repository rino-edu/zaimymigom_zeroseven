import 'package:flutter/foundation.dart';
import '../models/goals_models.dart';
import 'goals_database_service.dart';

class GoalsProvider extends ChangeNotifier {
  final GoalsDatabaseService _db = GoalsDatabaseService();

  bool _isLoading = true;
  List<Goal> _goals = [];
  final Map<String, List<GoalContribution>> _goalIdToContribs = {};

  bool get isLoading => _isLoading;
  List<Goal> get goals => _goals;
  List<GoalContribution> contributionsFor(String goalId) => _goalIdToContribs[goalId] ?? const [];

  Future<void> initialize() async {
    try {
      _isLoading = true;
      notifyListeners();
      await loadGoals();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadGoals() async {
    _goals = await _db.getAllGoals();
    notifyListeners();
  }

  Future<void> loadContributions(String goalId) async {
    _goalIdToContribs[goalId] = await _db.getContributions(goalId);
    notifyListeners();
  }

  Future<String?> addGoal(Goal goal) async {
    try {
      final id = await _db.addGoal(goal);
      await loadGoals();
      return id;
    } catch (e) {
      debugPrint('addGoal error: $e');
      return null;
    }
  }

  Future<void> updateGoal(Goal goal) async {
    try {
      await _db.updateGoal(goal);
      await loadGoals();
    } catch (e) {
      debugPrint('updateGoal error: $e');
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      await _db.deleteGoal(id);
      _goalIdToContribs.remove(id);
      await loadGoals();
    } catch (e) {
      debugPrint('deleteGoal error: $e');
    }
  }

  Future<String?> addContribution(GoalContribution c) async {
    try {
      final id = await _db.addContribution(c);
      await loadGoals();
      await loadContributions(c.goalId);
      return id;
    } catch (e) {
      debugPrint('addContribution error: $e');
      return null;
    }
  }

  Future<void> deleteContribution(GoalContribution c) async {
    try {
      await _db.deleteContribution(c);
      await loadGoals();
      await loadContributions(c.goalId);
    } catch (e) {
      debugPrint('deleteContribution error: $e');
    }
  }
}


