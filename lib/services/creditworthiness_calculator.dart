import '../models/creditworthiness_models.dart';

/// Сервис для расчета кредитоспособности
class CreditworthinessCalculator {
  /// Расчет оценки кредитоспособности на основе ответов
  static CreditworthinessResult calculate(CreditworthinessAnswers answers) {
    // 1. Расчет коэффициента платежеспособности
    final disposableIncome = answers.monthlyIncome - answers.monthlyExpenses;
    final solvencyRatio = answers.monthlyIncome > 0
        ? (disposableIncome / answers.monthlyIncome).clamp(0.0, 1.0)
        : 0.0;

    // 2. Расчет доступной суммы для займа
    // Обычно рекомендуется не более 30% от дохода на платежи по займам
    final maxMonthlyPayment = answers.monthlyIncome * 0.3;
    final availableLoanAmount = maxMonthlyPayment > 0
        ? maxMonthlyPayment * 12 // Примерная оценка на год
        : 0.0;

    // 3. Расчет базового балла (0-100)
    double score = 50.0; // Стартовая оценка

    // Финансовое положение (макс 30 баллов)
    if (answers.hasRegularIncome) {
      score += 10;
    }
    if (solvencyRatio > 0.3) {
      score += 10;
    } else if (solvencyRatio > 0.1) {
      score += 5;
    }
    if (answers.savings > answers.monthlyIncome * 3) {
      score += 10;
    } else if (answers.savings > answers.monthlyIncome) {
      score += 5;
    }

    // Кредитная история (макс 30 баллов)
    if (!answers.hasCurrentLoans) {
      score += 15;
    } else if (answers.currentLoansCount <= 2) {
      score += 5;
    }
    if (!answers.hasOverduePayments) {
      score += 15;
    } else if (answers.overdueCount <= 1) {
      score += 5;
    }

    // Финансовая дисциплина (макс 20 баллов)
    if (answers.usesBudgetPlanning) {
      score += 10;
    }
    if (answers.hasEmergencyFund) {
      score += 10;
    }

    // Стабильность (макс 20 баллов)
    if (answers.monthsOfFinancialStability >= 12) {
      score += 20;
    } else if (answers.monthsOfFinancialStability >= 6) {
      score += 10;
    } else if (answers.monthsOfFinancialStability >= 3) {
      score += 5;
    }

    // Штрафы за негативные факторы
    if (answers.hasOverduePayments && answers.overdueCount > 1) {
      score -= 20;
    }
    if (answers.currentLoansTotal > answers.monthlyIncome * 6) {
      score -= 15;
    }
    if (solvencyRatio < 0) {
      score -= 25; // Отрицательный баланс
    }

    score = score.clamp(0.0, 100.0);

    // 4. Расчет уровня риска (0-1, где 0 - низкий риск, 1 - высокий)
    double riskLevel = 0.0;
    if (solvencyRatio < 0) {
      riskLevel += 0.4;
    }
    if (answers.hasOverduePayments) {
      riskLevel += 0.3;
    }
    if (answers.currentLoansTotal > answers.monthlyIncome * 6) {
      riskLevel += 0.2;
    }
    if (!answers.hasRegularIncome) {
      riskLevel += 0.1;
    }
    riskLevel = riskLevel.clamp(0.0, 1.0);

    // 5. Определение сильных и слабых сторон
    final strengths = <String>[];
    final weaknesses = <String>[];

    if (answers.hasRegularIncome) {
      strengths.add('regular_income');
    } else {
      weaknesses.add('irregular_income');
    }

    if (solvencyRatio > 0.3) {
      strengths.add('good_solvency');
    } else if (solvencyRatio < 0.1) {
      weaknesses.add('low_solvency');
    }

    if (answers.savings > answers.monthlyIncome * 3) {
      strengths.add('good_savings');
    } else if (answers.savings < answers.monthlyIncome) {
      weaknesses.add('low_savings');
    }

    if (!answers.hasCurrentLoans) {
      strengths.add('no_current_loans');
    } else if (answers.currentLoansCount > 2) {
      weaknesses.add('many_loans');
    }

    if (!answers.hasOverduePayments) {
      strengths.add('no_overdue');
    } else {
      weaknesses.add('has_overdue');
    }

    if (answers.usesBudgetPlanning) {
      strengths.add('budget_planning');
    } else {
      weaknesses.add('no_budget_planning');
    }

    if (answers.hasEmergencyFund) {
      strengths.add('emergency_fund');
    } else {
      weaknesses.add('no_emergency_fund');
    }

    if (answers.monthsOfFinancialStability >= 12) {
      strengths.add('financial_stability');
    } else if (answers.monthsOfFinancialStability < 3) {
      weaknesses.add('low_stability');
    }

    // 6. Генерация рекомендаций
    final recommendations = <String>[];
    
    if (solvencyRatio < 0.1) {
      recommendations.add('increase_income_or_reduce_expenses');
    }
    if (answers.savings < answers.monthlyIncome) {
      recommendations.add('build_emergency_fund');
    }
    if (answers.hasOverduePayments) {
      recommendations.add('resolve_overdue_payments');
    }
    if (answers.currentLoansTotal > answers.monthlyIncome * 6) {
      recommendations.add('reduce_current_debt');
    }
    if (!answers.usesBudgetPlanning) {
      recommendations.add('start_budget_planning');
    }
    if (answers.monthsOfFinancialStability < 6) {
      recommendations.add('improve_financial_stability');
    }
    if (score >= 60 && availableLoanAmount > 0) {
      recommendations.add('loan_available');
    } else if (score < 40) {
      recommendations.add('improve_before_loan');
    }

    // 7. Рекомендации по сумме и сроку займа
    double? recommendedLoanAmount;
    int? recommendedLoanTerm;

    if (score >= 60 && availableLoanAmount > 0) {
      // Рекомендуем не более 50% от доступной суммы для безопасности
      recommendedLoanAmount = availableLoanAmount * 0.5;
      // Рекомендуемый срок зависит от суммы и платежеспособности
      if (recommendedLoanAmount <= answers.monthlyIncome * 3) {
        recommendedLoanTerm = 6;
      } else if (recommendedLoanAmount <= answers.monthlyIncome * 6) {
        recommendedLoanTerm = 12;
      } else {
        recommendedLoanTerm = 24;
      }
    }

    return CreditworthinessResult(
      score: score,
      solvencyRatio: solvencyRatio,
      availableLoanAmount: availableLoanAmount,
      riskLevel: riskLevel,
      strengths: strengths,
      weaknesses: weaknesses,
      recommendations: recommendations,
      recommendedLoanAmount: recommendedLoanAmount,
      recommendedLoanTerm: recommendedLoanTerm,
    );
  }
}

