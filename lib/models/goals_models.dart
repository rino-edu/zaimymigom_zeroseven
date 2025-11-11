/// Модели для генератора финансовых целей
enum GoalPriority { high, medium, low }

class Goal {
  final String? id;
  final String title;
  final double targetAmount;
  final DateTime? deadline;
  final GoalPriority priority;
  final String? imagePath; // путь к иконке/фото
  final double currentAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Goal({
    this.id,
    required this.title,
    required this.targetAmount,
    this.deadline,
    this.priority = GoalPriority.medium,
    this.imagePath,
    this.currentAmount = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  double get progress => targetAmount <= 0 ? 0 : (currentAmount / targetAmount).clamp(0, 1);

  int? get monthsLeft {
    if (deadline == null) return null;
    final now = DateTime.now();
    if (deadline!.isBefore(now)) return 0;
    final years = deadline!.year - now.year;
    final months = deadline!.month - now.month;
    final totalMonths = years * 12 + months + (deadline!.day >= now.day ? 0 : -1);
    return totalMonths < 0 ? 0 : totalMonths;
  }

  double? get suggestedMonthlySaving {
    final m = monthsLeft;
    if (m == null || m <= 0) return null;
    final remaining = (targetAmount - currentAmount).clamp(0, targetAmount);
    return remaining / m;
  }

  Goal copyWith({
    String? id,
    String? title,
    double? targetAmount,
    DateTime? deadline,
    GoalPriority? priority,
    String? imagePath,
    double? currentAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      imagePath: imagePath ?? this.imagePath,
      currentAmount: currentAmount ?? this.currentAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'target_amount': targetAmount,
      'deadline': deadline?.toIso8601String(),
      'priority': priority.name,
      'image_path': imagePath,
      'current_amount': currentAmount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] as String?,
      title: map['title'] as String,
      targetAmount: (map['target_amount'] as num).toDouble(),
      deadline: map['deadline'] != null ? DateTime.parse(map['deadline'] as String) : null,
      priority: GoalPriority.values.firstWhere(
        (p) => p.name == (map['priority'] as String? ?? GoalPriority.medium.name),
        orElse: () => GoalPriority.medium,
      ),
      imagePath: map['image_path'] as String?,
      currentAmount: (map['current_amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

class GoalContribution {
  final String? id;
  final String goalId;
  final double amount;
  final DateTime date;
  final String? comment;

  const GoalContribution({
    this.id,
    required this.goalId,
    required this.amount,
    required this.date,
    this.comment,
  });

  GoalContribution copyWith({
    String? id,
    String? goalId,
    double? amount,
    DateTime? date,
    String? comment,
  }) {
    return GoalContribution(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      comment: comment ?? this.comment,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal_id': goalId,
      'amount': amount,
      'date': date.toIso8601String(),
      'comment': comment,
    };
  }

  factory GoalContribution.fromMap(Map<String, dynamic> map) {
    return GoalContribution(
      id: map['id'] as String?,
      goalId: map['goal_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      comment: map['comment'] as String?,
    );
  }
}


