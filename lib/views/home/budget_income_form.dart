import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../utils/locale_keys.dart';
import '../../utils/helpers.dart';
import '../../services/budget_provider.dart';
import '../../models/budget_models.dart';

/// Экран для добавления/редактирования дохода
class BudgetIncomeScreen extends StatefulWidget {
  final BudgetProvider provider;
  final Income? income;
  final VoidCallback onSaved;

  const BudgetIncomeScreen({
    super.key,
    required this.provider,
    this.income,
    required this.onSaved,
  });

  @override
  State<BudgetIncomeScreen> createState() => _BudgetIncomeScreenState();
}

class _BudgetIncomeScreenState extends State<BudgetIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _intervalController;

  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;
  int? _recurringIntervalDays;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.income?.title ?? '');
    _amountController = TextEditingController(
      text: widget.income != null ? widget.income!.amount.toString() : '',
    );
    _descriptionController = TextEditingController(
      text: widget.income?.description ?? '',
    );
    _intervalController = TextEditingController(
      text: widget.income?.recurringIntervalDays?.toString() ?? '',
    );
    _selectedCategoryId = widget.income?.categoryId;
    _selectedDate = widget.income?.date ?? DateTime.now();
    _isRecurring = widget.income?.isRecurring ?? false;
    _recurringIntervalDays = widget.income?.recurringIntervalDays;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleKeys.budgetSelectCategory.tr())),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleKeys.validationEnterNumber.tr())),
      );
      return;
    }

    final income = Income(
      id: widget.income?.id,
      title: _titleController.text.trim(),
      amount: amount,
      categoryId: _selectedCategoryId!,
      date: _selectedDate,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      isRecurring: _isRecurring,
      recurringIntervalDays: _isRecurring && _recurringIntervalDays != null
          ? _recurringIntervalDays
          : null,
    );

    if (widget.income == null) {
      await widget.provider.addIncome(income);
    } else {
      await widget.provider.updateIncome(income);
    }

    if (mounted) {
      Navigator.pop(context);
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    final incomeCategories = widget.provider.incomeCategories;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          widget.income == null
              ? LocaleKeys.budgetAddIncome.tr()
              : LocaleKeys.budgetEditIncome.tr(),
        ),
        actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save)],
      ),
      body: SafeArea(
        top: true,
        bottom: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: LocaleKeys.budgetIncomeTitle.tr(),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return LocaleKeys.validationRequired.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: LocaleKeys.budgetAmount.tr(),
                          border: const OutlineInputBorder(),
                          suffixText: '₽',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: false,
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return LocaleKeys.validationRequired.tr();
                          }
                          final amount = double.tryParse(
                            value.replaceAll(',', '.'),
                          );
                          if (amount == null || amount <= 0) {
                            return LocaleKeys.validationEnterNumber.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategoryId,
                        decoration: InputDecoration(
                          labelText: LocaleKeys.budgetCategory.tr(),
                          border: const OutlineInputBorder(),
                        ),
                        items: incomeCategories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category.id,
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Color(category.color),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(category.name),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return LocaleKeys.validationRequired.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: LocaleKeys.budgetDate.tr(),
                            border: const OutlineInputBorder(),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(Helpers.formatDate(_selectedDate)),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: LocaleKeys.budgetDescription.tr(),
                          border: const OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: Text(LocaleKeys.budgetRecurring.tr()),
                        value: _isRecurring,
                        onChanged: (value) {
                          setState(() {
                            _isRecurring = value ?? false;
                          });
                        },
                      ),
                      if (_isRecurring) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _intervalController,
                          decoration: InputDecoration(
                            labelText: LocaleKeys.budgetRecurringInterval.tr(),
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              _recurringIntervalDays = int.tryParse(value);
                            });
                          },
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _save,
                        child: Text(LocaleKeys.actionsSave.tr()),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
