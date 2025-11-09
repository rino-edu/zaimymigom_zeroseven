import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../utils/locale_keys.dart';
import 'dart:math' as math;

enum PaymentType { annuity, differentiated }

class PscCalculatorScreen extends StatefulWidget {
  const PscCalculatorScreen({super.key});

  @override
  State<PscCalculatorScreen> createState() => _PscCalculatorScreenState();
}

class _PscCalculatorScreenState extends State<PscCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _termMonthsController = TextEditingController();
  final TextEditingController _upfrontFeeController = TextEditingController();
  final TextEditingController _monthlyFeeController = TextEditingController();
  final TextEditingController _insuranceMonthlyController =
      TextEditingController();

  PaymentType _paymentType = PaymentType.annuity;

  double? _pskAnnualPercent; // ПСК в % годовых
  double? _totalPayment;
  double? _totalOverpayment;
  List<_ScheduleRow> _schedule = <_ScheduleRow>[];

  @override
  void dispose() {
    _amountController.dispose();
    _rateController.dispose();
    _termMonthsController.dispose();
    _upfrontFeeController.dispose();
    _monthlyFeeController.dispose();
    _insuranceMonthlyController.dispose();
    super.dispose();
  }

  String? _validatePositiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return LocaleKeys.validationRequired.tr();
    }
    final number = double.tryParse(value.replaceAll(',', '.'));
    if (number == null || number <= 0) {
      return LocaleKeys.validationEnterNumber.tr();
    }
    return null;
  }

  String? _validateRate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return LocaleKeys.validationRequired.tr();
    }
    final number = double.tryParse(value.replaceAll(',', '.'));
    if (number == null || number <= 0) {
      return LocaleKeys.validationEnterNumber.tr();
    }
    if (number > 36) {
      return LocaleKeys.pscCalculatorMaxRateError.tr();
    }
    return null;
  }

  String? _validatePositiveInt(String? value) {
    if (value == null || value.trim().isEmpty) {
      return LocaleKeys.validationRequired.tr();
    }
    final number = int.tryParse(value.trim());
    if (number == null || number <= 0) {
      return LocaleKeys.validationEnterNumber.tr();
    }
    return null;
  }

  void _clear() {
    _formKey.currentState?.reset();
    _amountController.clear();
    _rateController.clear();
    _termMonthsController.clear();
    _upfrontFeeController.clear();
    _monthlyFeeController.clear();
    _insuranceMonthlyController.clear();
    setState(() {
      _pskAnnualPercent = null;
      _totalPayment = null;
      _totalOverpayment = null;
      _schedule = <_ScheduleRow>[];
      _paymentType = PaymentType.annuity;
    });
  }

  void _calculate() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final double amount =
        double.parse(_amountController.text.replaceAll(',', '.'));
    final double annualRatePercent =
        double.parse(_rateController.text.replaceAll(',', '.'));
    final int months = int.parse(_termMonthsController.text.trim());
    final double upfrontFee = _parseOptional(_upfrontFeeController.text);
    final double monthlyFee = _parseOptional(_monthlyFeeController.text);
    final double insuranceMonthly =
        _parseOptional(_insuranceMonthlyController.text);

    final double nominalMonthlyRate = annualRatePercent / 12.0 / 100.0;

    // Составляем график и платежи
    final schedule = <_ScheduleRow>[];
    double remaining = amount;
    double monthlyPayment = 0;

    if (_paymentType == PaymentType.annuity) {
      if (nominalMonthlyRate == 0) {
        monthlyPayment = amount / months;
      } else {
        final r = nominalMonthlyRate;
        monthlyPayment = amount * r * (math.pow(1 + r, months) / (math.pow(1 + r, months) - 1));
      }
    }

    double totalPaid = upfrontFee; // t0 комиссии

    for (int m = 1; m <= months; m++) {
      double interest = remaining * nominalMonthlyRate;
      double principal;

      if (_paymentType == PaymentType.annuity) {
        principal = (monthlyPayment - interest).clamp(0, remaining);
      } else {
        // Дифференцированный платеж: основной долг равномерно
        principal = amount / months;
        monthlyPayment = principal + interest;
        if (principal > remaining) principal = remaining;
      }

      final fees = monthlyFee + insuranceMonthly;
      final total = monthlyPayment + fees;
      remaining = (remaining - principal).clamp(0, amount);

      schedule.add(_ScheduleRow(
        month: m,
        principal: principal,
        interest: interest,
        fees: fees,
        total: total,
        balance: remaining,
      ));

      totalPaid += total;
    }

    // Денежные потоки для вычисления ПСК (IRR):
    // t0: +amount - upfrontFee
    // t1..tN: -(monthlyPayment + monthlyFee + insuranceMonthly)
    final cashFlows = <double>[];
    cashFlows.add(amount - upfrontFee);
    for (final row in schedule) {
      cashFlows.add(-row.total);
    }

    final irrMonthly = _irrBisection(cashFlows);
    final pskAnnual = irrMonthly != null ? (math.pow(1 + irrMonthly, 12) - 1) : null;

    setState(() {
      _schedule = schedule;
      _totalPayment = totalPaid;
      _totalOverpayment = totalPaid - amount;
      _pskAnnualPercent = pskAnnual != null ? pskAnnual * 100.0 : null;
    });
  }

  double _parseOptional(String text) {
    final t = text.trim();
    if (t.isEmpty) return 0.0;
    return double.tryParse(t.replaceAll(',', '.')) ?? 0.0;
  }

  // Поиск IRR методом бисекции на интервале [0; 200% в месяц]
  double? _irrBisection(List<double> cashFlows) {
    double a = 0.0;
    double b = 2.0; // 200%/мес верхняя граница, чисто техническая
    double fa = _npv(cashFlows, a);
    double fb = _npv(cashFlows, b);

    if (fa.abs() < 1e-10) return a;
    if (fb.abs() < 1e-10) return b;
    // Если знаки одинаковые, пробуем расширить диапазон
    if (fa * fb > 0) {
      // не удалось найти корень
      return 0.0; // дефолт: ПСК = 0 если нет корня
    }
    for (int i = 0; i < 100; i++) {
      final mid = (a + b) / 2.0;
      final fmid = _npv(cashFlows, mid);
      if (fmid.abs() < 1e-12) return mid;
      if (fa * fmid < 0) {
        b = mid;
        fb = fmid;
      } else {
        a = mid;
        fa = fmid;
      }
    }
    return (a + b) / 2.0;
  }

  double _npv(List<double> cashFlows, double monthlyRate) {
    double sum = 0.0;
    for (int t = 0; t < cashFlows.length; t++) {
      sum += cashFlows[t] / math.pow(1 + monthlyRate, t);
    }
    return sum;
  }

  String _fmtAmount(BuildContext context, double value) {
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Описание калькулятора
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleKeys.pscCalculatorDescription.tr(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      LocaleKeys.pscCalculatorFormula.tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: LocaleKeys.pscCalculatorAmount.tr(),
                      prefixIcon: const Icon(Icons.payments),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: false,
                    ),
                    validator: _validatePositiveNumber,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _rateController,
                    decoration: InputDecoration(
                      labelText: LocaleKeys.pscCalculatorAnnualRate.tr(),
                      suffixText: '%',
                      prefixIcon: const Icon(Icons.percent),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: false,
                    ),
                    validator: _validateRate,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _termMonthsController,
                    decoration: InputDecoration(
                      labelText: LocaleKeys.pscCalculatorTermMonths.tr(),
                      prefixIcon: const Icon(Icons.calendar_month),
                    ),
                    keyboardType: TextInputType.number,
                    validator: _validatePositiveInt,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<PaymentType>(
                    value: _paymentType,
                    decoration: InputDecoration(
                      labelText: LocaleKeys.pscCalculatorPaymentType.tr(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: PaymentType.annuity,
                        child: Text(LocaleKeys.pscCalculatorPaymentTypeAnnuity.tr()),
                      ),
                      DropdownMenuItem(
                        value: PaymentType.differentiated,
                        child: Text(LocaleKeys.pscCalculatorPaymentTypeDifferentiated.tr()),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _paymentType = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _upfrontFeeController,
                    decoration: InputDecoration(
                      labelText: LocaleKeys.pscCalculatorUpfrontFee.tr(),
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: false,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _monthlyFeeController,
                    decoration: InputDecoration(
                      labelText: LocaleKeys.pscCalculatorMonthlyFee.tr(),
                      prefixIcon: const Icon(Icons.request_quote),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: false,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _insuranceMonthlyController,
                    decoration: InputDecoration(
                      labelText: LocaleKeys.pscCalculatorInsuranceMonthly.tr(),
                      prefixIcon: const Icon(Icons.health_and_safety),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: false,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _calculate,
                          icon: const Icon(Icons.calculate),
                          label: Text(LocaleKeys.calculatorCalculate.tr()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _clear,
                          icon: const Icon(Icons.clear),
                          label: Text(LocaleKeys.calculatorClear.tr()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          if (_pskAnnualPercent != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleKeys.pscCalculatorResultTitle.tr(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _ResultChip(
                          labelKey: LocaleKeys.pscCalculatorResultPsk,
                          value: (_pskAnnualPercent!).toStringAsFixed(2) + ' %',
                        ),
                        if (_totalPayment != null)
                          _ResultChip(
                            labelKey: LocaleKeys.pscCalculatorResultTotalPayment,
                            value: _fmtAmount(context, _totalPayment!),
                          ),
                        if (_totalOverpayment != null)
                          _ResultChip(
                            labelKey: LocaleKeys.pscCalculatorResultOverpayment,
                            value: _fmtAmount(context, _totalOverpayment!),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (_schedule.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.pscCalculatorScheduleTitle.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _ScheduleTable(rows: _schedule),
              ],
            ),
        ],
      ),
      ),
    );
  }
}

class _ResultChip extends StatelessWidget {
  final String labelKey;
  final String value;
  const _ResultChip({required this.labelKey, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(labelKey.tr() + ': '),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ScheduleRow {
  final int month;
  final double principal;
  final double interest;
  final double fees;
  final double total;
  final double balance;
  _ScheduleRow({
    required this.month,
    required this.principal,
    required this.interest,
    required this.fees,
    required this.total,
    required this.balance,
  });
}

class _ScheduleTable extends StatelessWidget {
  final List<_ScheduleRow> rows;
  const _ScheduleTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(LocaleKeys.pscCalculatorColMonth.tr())),
            DataColumn(label: Text(LocaleKeys.pscCalculatorColPrincipal.tr())),
            DataColumn(label: Text(LocaleKeys.pscCalculatorColInterest.tr())),
            DataColumn(label: Text(LocaleKeys.pscCalculatorColFees.tr())),
            DataColumn(label: Text(LocaleKeys.pscCalculatorColTotal.tr())),
            DataColumn(label: Text(LocaleKeys.pscCalculatorColBalance.tr())),
          ],
          rows: rows
              .map(
                (r) => DataRow(cells: [
                  DataCell(Text(r.month.toString())),
                  DataCell(Text(r.principal.toStringAsFixed(2))),
                  DataCell(Text(r.interest.toStringAsFixed(2))),
                  DataCell(Text(r.fees.toStringAsFixed(2))),
                  DataCell(Text(r.total.toStringAsFixed(2))),
                  DataCell(Text(r.balance.toStringAsFixed(2))),
                ]),
              )
              .toList(),
        ),
      ),
    );
  }
}

// no extra math helpers needed; using dart:math

