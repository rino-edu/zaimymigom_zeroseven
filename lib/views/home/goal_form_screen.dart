import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../utils/locale_keys.dart';
import '../../services/goals_provider.dart';
import '../../models/goals_models.dart';

class GoalFormScreen extends StatefulWidget {
  final Goal? goal;
  const GoalFormScreen({super.key, this.goal});

  @override
  State<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends State<GoalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _targetController;
  DateTime? _deadline;
  GoalPriority _priority = GoalPriority.medium;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.goal?.title ?? '');
    _targetController = TextEditingController(
      text: widget.goal != null ? widget.goal!.targetAmount.toStringAsFixed(0) : '',
    );
    _deadline = widget.goal?.deadline;
    _priority = widget.goal?.priority ?? GoalPriority.medium;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<GoalsProvider>();
    final target = double.tryParse(_targetController.text.replaceAll(',', '.'));
    if (target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleKeys.validationEnterNumber.tr())),
      );
      return;
    }
    final now = DateTime.now();
    final goal = Goal(
      id: widget.goal?.id,
      title: _titleController.text.trim(),
      targetAmount: target,
      deadline: _deadline,
      priority: _priority,
      createdAt: widget.goal?.createdAt ?? now,
      updatedAt: now,
      currentAmount: widget.goal?.currentAmount ?? 0.0,
      imagePath: widget.goal?.imagePath,
    );
    if (widget.goal == null) {
      await provider.addGoal(goal);
    } else {
      await provider.updateGoal(goal);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.goal != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? LocaleKeys.goalsEditGoal.tr() : LocaleKeys.goalsAddGoal.tr()),
        actions: [
          IconButton(onPressed: _save, icon: const Icon(Icons.check)),
        ],
      ),
      body: SafeArea(
        top: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: LocaleKeys.goalsFieldTitle.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? LocaleKeys.validationRequired.tr() : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _targetController,
                  decoration: InputDecoration(
                    labelText: LocaleKeys.goalsFieldTarget.tr(),
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
                  onTap: _pickDeadline,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: LocaleKeys.goalsFieldDeadline.tr(),
                      border: const OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_deadline != null ? DateFormat('dd.MM.yyyy').format(_deadline!) : LocaleKeys.validationNotSet.tr()),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: LocaleKeys.goalsFieldPriority.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<GoalPriority>(
                      value: _priority,
                      items: [
                        DropdownMenuItem(
                          value: GoalPriority.high,
                          child: Text(LocaleKeys.goalsPriorityHigh.tr()),
                        ),
                        DropdownMenuItem(
                          value: GoalPriority.medium,
                          child: Text(LocaleKeys.goalsPriorityMedium.tr()),
                        ),
                        DropdownMenuItem(
                          value: GoalPriority.low,
                          child: Text(LocaleKeys.goalsPriorityLow.tr()),
                        ),
                      ],
                      onChanged: (v) => setState(() => _priority = v ?? GoalPriority.medium),
                    ),
                  ),
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


