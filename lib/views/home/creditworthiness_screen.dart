import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../utils/locale_keys.dart';
import '../../services/creditworthiness_provider.dart';
import '../../models/creditworthiness_models.dart';
import '../../utils/helpers.dart';

/// Экран оценки кредитоспособности
class CreditworthinessScreen extends StatefulWidget {
  const CreditworthinessScreen({super.key});

  @override
  State<CreditworthinessScreen> createState() => _CreditworthinessScreenState();
}

class _CreditworthinessScreenState extends State<CreditworthinessScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Контроллеры для полей формы
  final TextEditingController _monthlyIncomeController = TextEditingController();
  final TextEditingController _monthlyExpensesController = TextEditingController();
  final TextEditingController _savingsController = TextEditingController();
  final TextEditingController _currentLoansCountController = TextEditingController();
  final TextEditingController _currentLoansTotalController = TextEditingController();
  final TextEditingController _overdueCountController = TextEditingController();
  final TextEditingController _monthsStabilityController = TextEditingController();

  bool _hasRegularIncome = true;
  bool _hasCurrentLoans = false;
  bool _hasOverduePayments = false;
  bool _usesBudgetPlanning = false;
  bool _hasEmergencyFund = false;

  @override
  void dispose() {
    _monthlyIncomeController.dispose();
    _monthlyExpensesController.dispose();
    _savingsController.dispose();
    _currentLoansCountController.dispose();
    _currentLoansTotalController.dispose();
    _overdueCountController.dispose();
    _monthsStabilityController.dispose();
    super.dispose();
  }

  String? _validatePositiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return LocaleKeys.validationRequired.tr();
    }
    final number = double.tryParse(value.replaceAll(',', '.'));
    if (number == null || number < 0) {
      return LocaleKeys.validationEnterNumber.tr();
    }
    return null;
  }

  String? _validatePositiveInt(String? value) {
    if (value == null || value.trim().isEmpty) {
      return LocaleKeys.validationRequired.tr();
    }
    final number = int.tryParse(value.trim());
    if (number == null || number < 0) {
      return LocaleKeys.validationEnterNumber.tr();
    }
    return null;
  }

  void _nextStep() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    setState(() {
      _currentStep--;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final answers = CreditworthinessAnswers(
      monthlyIncome: double.parse(_monthlyIncomeController.text.replaceAll(',', '.')),
      monthlyExpenses: double.parse(_monthlyExpensesController.text.replaceAll(',', '.')),
      savings: double.parse(_savingsController.text.replaceAll(',', '.')),
      hasRegularIncome: _hasRegularIncome,
      hasCurrentLoans: _hasCurrentLoans,
      currentLoansCount: _hasCurrentLoans
          ? int.parse(_currentLoansCountController.text)
          : 0,
      currentLoansTotal: _hasCurrentLoans
          ? double.parse(_currentLoansTotalController.text.replaceAll(',', '.'))
          : 0.0,
      hasOverduePayments: _hasOverduePayments,
      overdueCount: _hasOverduePayments
          ? int.parse(_overdueCountController.text)
          : 0,
      usesBudgetPlanning: _usesBudgetPlanning,
      hasEmergencyFund: _hasEmergencyFund,
      monthsOfFinancialStability: int.parse(_monthsStabilityController.text),
    );

    final provider = context.read<CreditworthinessProvider>();
    final id = await provider.addAssessment(answers);

    if (id != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CreditworthinessResultScreen(assessmentId: id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.creditworthinessTitle.tr()),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Stepper(
            currentStep: _currentStep,
            onStepContinue: _currentStep < 2 ? _nextStep : _submit,
            onStepCancel: _currentStep > 0 ? _previousStep : null,
            steps: [
              _buildStep1(),
              _buildStep2(),
              _buildStep3(),
            ],
          ),
        ),
      ),
    );
  }

  Step _buildStep1() {
    return Step(
      title: Text(LocaleKeys.creditworthinessStep1Title.tr()),
      content: Padding(
        padding: const EdgeInsets.only(top: 5.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _monthlyIncomeController,
              decoration: InputDecoration(
                labelText: LocaleKeys.creditworthinessMonthlyIncome.tr(),
                hintText: LocaleKeys.creditworthinessMonthlyIncomeHint.tr(),
                suffixText: '₽',
              ),
              keyboardType: TextInputType.number,
              validator: (v) => _currentStep == 0 ? _validatePositiveNumber(v) : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _monthlyExpensesController,
              decoration: InputDecoration(
                labelText: LocaleKeys.creditworthinessMonthlyExpenses.tr(),
                hintText: LocaleKeys.creditworthinessMonthlyExpensesHint.tr(),
                suffixText: '₽',
              ),
              keyboardType: TextInputType.number,
              validator: (v) => _currentStep == 0 ? _validatePositiveNumber(v) : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _savingsController,
              decoration: InputDecoration(
                labelText: LocaleKeys.creditworthinessSavings.tr(),
                hintText: LocaleKeys.creditworthinessSavingsHint.tr(),
                suffixText: '₽',
              ),
              keyboardType: TextInputType.number,
              validator: (v) => _currentStep == 0 ? _validatePositiveNumber(v) : null,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(LocaleKeys.creditworthinessHasRegularIncome.tr()),
              value: _hasRegularIncome,
              onChanged: (value) => setState(() => _hasRegularIncome = value),
            ),
          ],
        ),
      ),
    );
  }

  Step _buildStep2() {
    return Step(
      title: Text(LocaleKeys.creditworthinessStep2Title.tr()),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: Text(LocaleKeys.creditworthinessHasCurrentLoans.tr()),
            value: _hasCurrentLoans,
            onChanged: (value) => setState(() => _hasCurrentLoans = value),
          ),
          if (_hasCurrentLoans) ...[
            TextFormField(
              controller: _currentLoansCountController,
              decoration: InputDecoration(
                labelText: LocaleKeys.creditworthinessCurrentLoansCount.tr(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) =>
                  _currentStep == 1 && _hasCurrentLoans ? _validatePositiveInt(v) : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _currentLoansTotalController,
              decoration: InputDecoration(
                labelText: LocaleKeys.creditworthinessCurrentLoansTotal.tr(),
                suffixText: '₽',
              ),
              keyboardType: TextInputType.number,
              validator: (v) =>
                  _currentStep == 1 && _hasCurrentLoans ? _validatePositiveNumber(v) : null,
            ),
          ],
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(LocaleKeys.creditworthinessHasOverduePayments.tr()),
            value: _hasOverduePayments,
            onChanged: (value) => setState(() => _hasOverduePayments = value),
          ),
          if (_hasOverduePayments)
            TextFormField(
              controller: _overdueCountController,
              decoration: InputDecoration(
                labelText: LocaleKeys.creditworthinessOverdueCount.tr(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) =>
                  _currentStep == 1 && _hasOverduePayments ? _validatePositiveInt(v) : null,
            ),
        ],
      ),
    );
  }

  Step _buildStep3() {
    return Step(
      title: Text(LocaleKeys.creditworthinessStep3Title.tr()),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: Text(LocaleKeys.creditworthinessUsesBudgetPlanning.tr()),
            value: _usesBudgetPlanning,
            onChanged: (value) => setState(() => _usesBudgetPlanning = value),
          ),
          SwitchListTile(
            title: Text(LocaleKeys.creditworthinessHasEmergencyFund.tr()),
            value: _hasEmergencyFund,
            onChanged: (value) => setState(() => _hasEmergencyFund = value),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _monthsStabilityController,
            decoration: InputDecoration(
              labelText: LocaleKeys.creditworthinessMonthsStability.tr(),
              hintText: LocaleKeys.creditworthinessMonthsStabilityHint.tr(),
            ),
            keyboardType: TextInputType.number,
            validator: (v) => _currentStep == 2 ? _validatePositiveInt(v) : null,
          ),
        ],
      ),
    );
  }
}

/// Экран результатов оценки
class CreditworthinessResultScreen extends StatelessWidget {
  final String assessmentId;

  const CreditworthinessResultScreen({super.key, required this.assessmentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.creditworthinessResultTitle.tr()),
      ),
      body: Consumer<CreditworthinessProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final assessment = provider.assessments.firstWhere(
            (a) => a.id == assessmentId,
            orElse: () => throw StateError('Assessment not found'),
          );
          final result = assessment.result;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildScoreCard(context, result),
                const SizedBox(height: 16),
                _buildSolvencyCard(context, result),
                const SizedBox(height: 16),
                _buildRecommendationsCard(context, result),
                const SizedBox(height: 16),
                _buildStrengthsWeaknessesCard(context, result),
                const SizedBox(height: 16),
                _buildHistoryButton(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context, CreditworthinessResult result) {
    Color scoreColor;
    if (result.score >= 80) {
      scoreColor = Colors.green;
    } else if (result.score >= 60) {
      scoreColor = Colors.blue;
    } else if (result.score >= 40) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.creditworthinessScore.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text(
                    result.score.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: scoreColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'creditworthiness.score_label.${result.scoreLabel}'.tr(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: scoreColor,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: result.score / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolvencyCard(BuildContext context, CreditworthinessResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.creditworthinessSolvencyInfo.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              LocaleKeys.creditworthinessSolvencyRatio.tr(),
              '${(result.solvencyRatio * 100).toStringAsFixed(1)}%',
            ),
            _buildInfoRow(
              context,
              LocaleKeys.creditworthinessAvailableLoanAmount.tr(),
              '${Helpers.formatNumber(result.availableLoanAmount, decimals: 0)} ₽',
            ),
            _buildInfoRow(
              context,
              LocaleKeys.creditworthinessRiskLevel.tr(),
              '${(result.riskLevel * 100).toStringAsFixed(1)}%',
            ),
            if (result.recommendedLoanAmount != null) ...[
              const Divider(),
              _buildInfoRow(
                context,
                LocaleKeys.creditworthinessRecommendedLoanAmount.tr(),
                '${Helpers.formatNumber(result.recommendedLoanAmount!, decimals: 0)} ₽',
              ),
              if (result.recommendedLoanTerm != null)
                _buildInfoRow(
                  context,
                  LocaleKeys.creditworthinessRecommendedLoanTerm.tr(),
                  '${result.recommendedLoanTerm} ${LocaleKeys.creditworthinessMonths.tr()}',
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(BuildContext context, CreditworthinessResult result) {
    if (result.recommendations.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.creditworthinessRecommendations.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...result.recommendations.map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'creditworthiness.recommendation.$rec'.tr(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthsWeaknessesCard(BuildContext context, CreditworthinessResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.strengths.isNotEmpty) ...[
              Text(
                LocaleKeys.creditworthinessStrengths.tr(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.green,
                    ),
              ),
              const SizedBox(height: 8),
              ...result.strengths.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.thumb_up, color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'creditworthiness.strength.$s'.tr(),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            if (result.weaknesses.isNotEmpty) ...[
              if (result.strengths.isNotEmpty) const SizedBox(height: 16),
              Text(
                LocaleKeys.creditworthinessWeaknesses.tr(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.orange,
                    ),
              ),
              const SizedBox(height: 8),
              ...result.weaknesses.map((w) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.thumb_down, color: Colors.orange, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'creditworthiness.weakness.$w'.tr(),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreditworthinessHistoryScreen(),
          ),
        );
      },
      icon: const Icon(Icons.history),
      label: Text(LocaleKeys.creditworthinessHistory.tr()),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }
}

/// Экран истории оценок
class CreditworthinessHistoryScreen extends StatelessWidget {
  const CreditworthinessHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.creditworthinessHistory.tr()),
      ),
      body: Consumer<CreditworthinessProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final assessments = provider.assessments;

          if (assessments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 72, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    LocaleKeys.creditworthinessHistoryEmpty.tr(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: assessments.length,
            itemBuilder: (context, index) {
              final assessment = assessments[index];
              final result = assessment.result;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    '${LocaleKeys.creditworthinessScore.tr()}: ${result.score.toStringAsFixed(1)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    Helpers.formatDate(assessment.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _confirmDelete(context, assessment.id!),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreditworthinessResultScreen(
                          assessmentId: assessment.id!,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocaleKeys.creditworthinessDeleteConfirm.tr()),
        content: Text(LocaleKeys.creditworthinessDeleteConfirmMessage.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocaleKeys.actionsCancel.tr()),
          ),
          TextButton(
            onPressed: () async {
              await context.read<CreditworthinessProvider>().deleteAssessment(id);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(LocaleKeys.actionsDelete.tr()),
          ),
        ],
      ),
    );
  }
}

