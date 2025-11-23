import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../utils/locale_keys.dart';
import '../../services/goals_provider.dart';
import '../../models/goals_models.dart';

class GoalContributionForm extends StatefulWidget {
  final Goal goal;
  const GoalContributionForm({super.key, required this.goal});

  @override
  State<GoalContributionForm> createState() => _GoalContributionFormState();
}

class _GoalContributionFormState extends State<GoalContributionForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _commentController;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleKeys.validationEnterNumber.tr())),
      );
      return;
    }
    final provider = context.read<GoalsProvider>();
    await provider.addContribution(GoalContribution(
      goalId: widget.goal.id!,
      amount: amount,
      date: _date,
      comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.goalsAddContribution.tr()),
        actions: [IconButton(onPressed: _save, icon: const Icon(Icons.check))],
      ),
      body: SafeArea(
        top: true,
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.goal.title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: LocaleKeys.goalsContributionAmount.tr(),
                    suffixText: '₽',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return LocaleKeys.validationRequired.tr();
                    final n = double.tryParse(v.replaceAll(',', '.'));
                    if (n == null || n <= 0) return LocaleKeys.validationEnterNumber.tr();
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: LocaleKeys.budgetDate.tr(),
                      border: const OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('dd.MM.yyyy').format(_date)),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    labelText: LocaleKeys.goalsContributionComment.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                  label: Text(LocaleKeys.actionsSave.tr()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


