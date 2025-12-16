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
    // Вычисляем динамический отступ для bottom bar
    // Высота LiquidGlassBottomBar обычно около 60-80 пикселей
    // Плюс системные отступы (safe area)
    final mediaQuery = MediaQuery.of(context);
    final bottomBarHeight = 60.0; // Безопасная высота LiquidGlassBottomBar (с учетом всех вариантов)
    final systemBottomPadding = mediaQuery.padding.bottom;
    final totalBottomPadding = bottomBarHeight + systemBottomPadding + 4; // +16 для дополнительного отступа между кнопками и bottom bar
    
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5F5F5F), Color(0xFFBEBEBE)],
        ),
      ),
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: totalBottomPadding,
          left: 16,
          right: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Описание калькулятора
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.white.withOpacity(0.9),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          LocaleKeys.pscCalculatorDescription.tr(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    LocaleKeys.pscCalculatorFormula.tr(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _amountController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: LocaleKeys.pscCalculatorAmount.tr(),
                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                        prefixIcon: Icon(Icons.payments, color: Colors.white.withOpacity(0.8)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white, width: 2),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: false,
                      ),
                      validator: _validatePositiveNumber,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _rateController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: LocaleKeys.pscCalculatorAnnualRate.tr(),
                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                        suffixText: '%',
                        suffixStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                        prefixIcon: Icon(Icons.percent, color: Colors.white.withOpacity(0.8)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white, width: 2),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: false,
                      ),
                      validator: _validateRate,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _termMonthsController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: LocaleKeys.pscCalculatorTermMonths.tr(),
                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                        prefixIcon: Icon(Icons.calendar_month, color: Colors.white.withOpacity(0.8)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white, width: 2),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: _validatePositiveInt,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<PaymentType>(
                      value: _paymentType,
                      style: const TextStyle(color: Colors.white),
                      dropdownColor: const Color(0xFF5F5F5F),
                      decoration: InputDecoration(
                        labelText: LocaleKeys.pscCalculatorPaymentType.tr(),
                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white, width: 2),
                        ),
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _upfrontFeeController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: LocaleKeys.pscCalculatorUpfrontFee.tr(),
                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                        prefixIcon: Icon(Icons.attach_money, color: Colors.white.withOpacity(0.8)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white, width: 2),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: false,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _monthlyFeeController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: LocaleKeys.pscCalculatorMonthlyFee.tr(),
                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                        prefixIcon: Icon(Icons.request_quote, color: Colors.white.withOpacity(0.8)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white, width: 2),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: false,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _insuranceMonthlyController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: LocaleKeys.pscCalculatorInsuranceMonthly.tr(),
                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                        prefixIcon: Icon(Icons.health_and_safety, color: Colors.white.withOpacity(0.8)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white, width: 2),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: false,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.9),
                                  Colors.white.withOpacity(0.7),
                                ],
                              ),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _calculate,
                              icon: const Icon(Icons.calculate, color: Color(0xFF5F5F5F)),
                              label: Text(
                                LocaleKeys.calculatorCalculate.tr(),
                                style: const TextStyle(
                                  color: Color(0xFF5F5F5F),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.6),
                                width: 2,
                              ),
                            ),
                            child: OutlinedButton.icon(
                              onPressed: _clear,
                              icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.9)),
                              label: Text(
                                LocaleKeys.calculatorClear.tr(),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          if (_pskAnnualPercent != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.assessment,
                        color: Colors.white.withOpacity(0.9),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          LocaleKeys.pscCalculatorResultTitle.tr(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      _ResultCard(
                        labelKey: LocaleKeys.pscCalculatorResultPsk,
                        value: (_pskAnnualPercent!).toStringAsFixed(2) + ' %',
                        icon: Icons.trending_up,
                        color: Colors.blue,
                      ),
                      if (_totalPayment != null) ...[
                        const SizedBox(height: 12),
                        _ResultCard(
                          labelKey: LocaleKeys.pscCalculatorResultTotalPayment,
                          value: _fmtAmount(context, _totalPayment!),
                          icon: Icons.account_balance_wallet,
                          color: Colors.green,
                        ),
                      ],
                      if (_totalOverpayment != null) ...[
                        const SizedBox(height: 12),
                        _ResultCard(
                          labelKey: LocaleKeys.pscCalculatorResultOverpayment,
                          value: _fmtAmount(context, _totalOverpayment!),
                          icon: Icons.money_off,
                          color: Colors.orange,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          if (_schedule.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.table_chart,
                        color: Colors.white.withOpacity(0.9),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          LocaleKeys.pscCalculatorScheduleTitle.tr(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _ScheduleTable(rows: _schedule),
              ],
            ),
        ],
      ),
      ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String labelKey;
  final String value;
  final IconData icon;
  final Color color;
  const _ResultCard({
    required this.labelKey,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  labelKey.tr(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(
            Colors.white.withOpacity(0.15),
          ),
          dataRowColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.white.withOpacity(0.2);
            }
            return null;
          }),
          columns: [
            DataColumn(
              label: Text(
                LocaleKeys.pscCalculatorColMonth.tr(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                LocaleKeys.pscCalculatorColPrincipal.tr(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                LocaleKeys.pscCalculatorColInterest.tr(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                LocaleKeys.pscCalculatorColFees.tr(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                LocaleKeys.pscCalculatorColTotal.tr(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                LocaleKeys.pscCalculatorColBalance.tr(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          rows: rows.asMap().entries.map(
            (entry) {
              final index = entry.key;
              final r = entry.value;
              return DataRow(
                color: MaterialStateProperty.all(
                  index.isEven
                      ? Colors.white.withOpacity(0.05)
                      : Colors.white.withOpacity(0.08),
                ),
                cells: [
                  DataCell(
                    Text(
                      r.month.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  DataCell(
                    Text(
                      r.principal.toStringAsFixed(2),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  DataCell(
                    Text(
                      r.interest.toStringAsFixed(2),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  DataCell(
                    Text(
                      r.fees.toStringAsFixed(2),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  DataCell(
                    Text(
                      r.total.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      r.balance.toStringAsFixed(2),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ).toList(),
        ),
      ),
    );
  }
}

// no extra math helpers needed; using dart:math

