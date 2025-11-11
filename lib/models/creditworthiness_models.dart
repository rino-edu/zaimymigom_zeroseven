/// Модели для оценки кредитоспособности

/// Ответы на вопросы анкеты
class CreditworthinessAnswers {
  // Финансовое положение
  final double monthlyIncome; // Ежемесячный доход
  final double monthlyExpenses; // Ежемесячные расходы
  final double savings; // Сбережения
  final bool hasRegularIncome; // Регулярный доход

  // Кредитная история
  final bool hasCurrentLoans; // Есть текущие займы
  final int currentLoansCount; // Количество текущих займов
  final double currentLoansTotal; // Общая сумма текущих займов
  final bool hasOverduePayments; // Есть просрочки
  final int overdueCount; // Количество просрочек

  // Финансовая дисциплина
  final bool usesBudgetPlanning; // Использует планирование бюджета
  final bool hasEmergencyFund; // Есть резервный фонд
  final int monthsOfFinancialStability; // Месяцы финансовой стабильности

  const CreditworthinessAnswers({
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.savings,
    required this.hasRegularIncome,
    required this.hasCurrentLoans,
    required this.currentLoansCount,
    required this.currentLoansTotal,
    required this.hasOverduePayments,
    required this.overdueCount,
    required this.usesBudgetPlanning,
    required this.hasEmergencyFund,
    required this.monthsOfFinancialStability,
  });

  Map<String, dynamic> toMap() {
    return {
      'monthly_income': monthlyIncome,
      'monthly_expenses': monthlyExpenses,
      'savings': savings,
      'has_regular_income': hasRegularIncome ? 1 : 0,
      'has_current_loans': hasCurrentLoans ? 1 : 0,
      'current_loans_count': currentLoansCount,
      'current_loans_total': currentLoansTotal,
      'has_overdue_payments': hasOverduePayments ? 1 : 0,
      'overdue_count': overdueCount,
      'uses_budget_planning': usesBudgetPlanning ? 1 : 0,
      'has_emergency_fund': hasEmergencyFund ? 1 : 0,
      'months_of_financial_stability': monthsOfFinancialStability,
    };
  }

  factory CreditworthinessAnswers.fromMap(Map<String, dynamic> map) {
    return CreditworthinessAnswers(
      monthlyIncome: (map['monthly_income'] as num).toDouble(),
      monthlyExpenses: (map['monthly_expenses'] as num).toDouble(),
      savings: (map['savings'] as num).toDouble(),
      hasRegularIncome: (map['has_regular_income'] as int) == 1,
      hasCurrentLoans: (map['has_current_loans'] as int) == 1,
      currentLoansCount: map['current_loans_count'] as int,
      currentLoansTotal: (map['current_loans_total'] as num).toDouble(),
      hasOverduePayments: (map['has_overdue_payments'] as int) == 1,
      overdueCount: map['overdue_count'] as int,
      usesBudgetPlanning: (map['uses_budget_planning'] as int) == 1,
      hasEmergencyFund: (map['has_emergency_fund'] as int) == 1,
      monthsOfFinancialStability: map['months_of_financial_stability'] as int,
    );
  }
}

/// Результаты оценки
class CreditworthinessResult {
  final double score; // Итоговый балл (0-100)
  final double solvencyRatio; // Коэффициент платежеспособности
  final double availableLoanAmount; // Доступная сумма для займа
  final double riskLevel; // Уровень риска (0-1)
  final List<String> strengths; // Сильные стороны
  final List<String> weaknesses; // Слабые стороны
  final List<String> recommendations; // Рекомендации
  final double? recommendedLoanAmount; // Рекомендуемая сумма займа
  final int? recommendedLoanTerm; // Рекомендуемый срок займа (месяцы)

  const CreditworthinessResult({
    required this.score,
    required this.solvencyRatio,
    required this.availableLoanAmount,
    required this.riskLevel,
    required this.strengths,
    required this.weaknesses,
    required this.recommendations,
    this.recommendedLoanAmount,
    this.recommendedLoanTerm,
  });

  String get scoreLabel {
    if (score >= 80) return 'excellent';
    if (score >= 60) return 'good';
    if (score >= 40) return 'fair';
    return 'poor';
  }

  Map<String, dynamic> toMap() {
    return {
      'score': score,
      'solvency_ratio': solvencyRatio,
      'available_loan_amount': availableLoanAmount,
      'risk_level': riskLevel,
      'strengths': strengths.join('|'),
      'weaknesses': weaknesses.join('|'),
      'recommendations': recommendations.join('|'),
      'recommended_loan_amount': recommendedLoanAmount,
      'recommended_loan_term': recommendedLoanTerm,
    };
  }

  factory CreditworthinessResult.fromMap(Map<String, dynamic> map) {
    return CreditworthinessResult(
      score: (map['score'] as num).toDouble(),
      solvencyRatio: (map['solvency_ratio'] as num).toDouble(),
      availableLoanAmount: (map['available_loan_amount'] as num).toDouble(),
      riskLevel: (map['risk_level'] as num).toDouble(),
      strengths: (map['strengths'] as String).split('|').where((s) => s.isNotEmpty).toList(),
      weaknesses: (map['weaknesses'] as String).split('|').where((s) => s.isNotEmpty).toList(),
      recommendations: (map['recommendations'] as String).split('|').where((s) => s.isNotEmpty).toList(),
      recommendedLoanAmount: map['recommended_loan_amount'] != null ? (map['recommended_loan_amount'] as num).toDouble() : null,
      recommendedLoanTerm: map['recommended_loan_term'] as int?,
    );
  }
}

/// Полная оценка кредитоспособности
class CreditworthinessAssessment {
  final String? id;
  final CreditworthinessAnswers answers;
  final CreditworthinessResult result;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CreditworthinessAssessment({
    this.id,
    required this.answers,
    required this.result,
    required this.createdAt,
    required this.updatedAt,
  });

  CreditworthinessAssessment copyWith({
    String? id,
    CreditworthinessAnswers? answers,
    CreditworthinessResult? result,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CreditworthinessAssessment(
      id: id ?? this.id,
      answers: answers ?? this.answers,
      result: result ?? this.result,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      ...answers.toMap(),
      ...result.toMap(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CreditworthinessAssessment.fromMap(Map<String, dynamic> map) {
    return CreditworthinessAssessment(
      id: map['id'] as String?,
      answers: CreditworthinessAnswers.fromMap(map),
      result: CreditworthinessResult.fromMap(map),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

