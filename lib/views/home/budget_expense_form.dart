import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../utils/locale_keys.dart';
import '../../utils/helpers.dart';
import '../../services/budget_provider.dart';
import '../../models/budget_models.dart';

/// Экран для добавления/редактирования расхода
class BudgetExpenseScreen extends StatefulWidget {
  final BudgetProvider provider;
  final Expense? expense;
  final VoidCallback onSaved;

  const BudgetExpenseScreen({
    super.key,
    required this.provider,
    this.expense,
    required this.onSaved,
  });

  @override
  State<BudgetExpenseScreen> createState() => _BudgetExpenseScreenState();
}

class _BudgetExpenseScreenState extends State<BudgetExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tagController = TextEditingController();
  final _imagePicker = ImagePicker();

  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _intervalController;

  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;
  int? _recurringIntervalDays;
  List<String> _tags = [];
  String? _receiptImagePath;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.expense?.title ?? '');
    _amountController = TextEditingController(
      text: widget.expense != null ? widget.expense!.amount.toString() : '',
    );
    _descriptionController = TextEditingController(
      text: widget.expense?.description ?? '',
    );
    _intervalController = TextEditingController(
      text: widget.expense?.recurringIntervalDays?.toString() ?? '',
    );
    _selectedCategoryId = widget.expense?.categoryId;
    _selectedDate = widget.expense?.date ?? DateTime.now();
    _isRecurring = widget.expense?.isRecurring ?? false;
    _recurringIntervalDays = widget.expense?.recurringIntervalDays;
    _tags = List.from(widget.expense?.tags ?? []);
    _receiptImagePath = widget.expense?.receiptImagePath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _intervalController.dispose();
    _tagController.dispose();
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

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _receiptImagePath = pickedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при выборе изображения: $e')),
        );
      }
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleKeys.budgetSelectCategory.tr())),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleKeys.validationEnterNumber.tr())),
      );
      return;
    }

    final expense = Expense(
      id: widget.expense?.id,
      title: _titleController.text.trim(),
      amount: amount,
      categoryId: _selectedCategoryId!,
      date: _selectedDate,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      receiptImagePath: _receiptImagePath,
      isRecurring: _isRecurring,
      recurringIntervalDays: _isRecurring && _recurringIntervalDays != null
          ? _recurringIntervalDays
          : null,
      tags: _tags,
    );

    if (widget.expense == null) {
      await widget.provider.addExpense(expense);
    } else {
      await widget.provider.updateExpense(expense);
    }

    if (mounted) {
      Navigator.pop(context);
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseCategories = widget.provider.expenseCategories;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          widget.expense == null
              ? LocaleKeys.budgetAddExpense.tr()
              : LocaleKeys.budgetEditExpense.tr(),
        ),
        actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save)],
      ),
      body: SafeArea(
        top: true,
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
                          labelText: LocaleKeys.budgetExpenseTitle.tr(),
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
                        items: expenseCategories.map((category) {
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
                      if (_receiptImagePath != null)
                        Stack(
                          children: [
                            Image.file(
                              File(_receiptImagePath!),
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _receiptImagePath = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.camera_alt),
                          label: Text(LocaleKeys.budgetAddReceipt.tr()),
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
                      const SizedBox(height: 16),
                      Text(
                        LocaleKeys.budgetTags.tr(),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _tagController,
                              decoration: InputDecoration(
                                labelText: LocaleKeys.budgetAddTag.tr(),
                                border: const OutlineInputBorder(),
                              ),
                              onFieldSubmitted: (_) => _addTag(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _addTag,
                          ),
                        ],
                      ),
                      if (_tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _tags.map((tag) {
                            return Chip(
                              label: Text(tag),
                              onDeleted: () => _removeTag(tag),
                            );
                          }).toList(),
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

