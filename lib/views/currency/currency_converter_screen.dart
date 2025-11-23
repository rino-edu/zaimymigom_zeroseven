import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../services/currency_service.dart';
import '../../services/currency_prefs.dart';
import '../../utils/locale_keys.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final CurrencyService _currencyService = CurrencyService();
  final TextEditingController _amountController = TextEditingController(text: '1');
  late List<String> _currencies;
  String _from = 'USD';
  String _to = 'RUB';
  double? _result;
  String? _lastUpdatedUtc;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _currencies = _currencyService.getPopularCurrencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CurrencyPrefs>().load();
      _refreshRates();
    });
  }

  Future<void> _refreshRates() async {
    setState(() {
      _loading = true;
    });
    try {
      final response = await _currencyService.getCurrencyRates(_from);
      _lastUpdatedUtc = response.timeLastUpdateUtc;
      await _convert();
    } catch (_) {
      // Ошибка уже залогирована в сервисе
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _convert() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null) {
      setState(() {
        _result = null;
      });
      return;
    }
    final res = await _currencyService.convertCurrency(
      amount: amount,
      fromCurrency: _from,
      toCurrency: _to,
    );
    setState(() {
      _result = res;
    });
    if (res != null && mounted) {
      final prefs = context.read<CurrencyPrefs>();
      await prefs.addHistory(CurrencyConversionEntry(
        amount: amount,
        fromCurrency: _from,
        toCurrency: _to,
        result: res,
        timestamp: DateTime.now(),
      ));
    }
  }

  void _swap() {
    setState(() {
      final tmp = _from;
      _from = _to;
      _to = tmp;
    });
    _refreshRates();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _formatUpdateTime(String? utc) {
    if (utc == null) return '-';
    // Пример входа: "Sat, 09 Nov 2024 00:02:01 +0000"
    try {
      final parsed = DateFormat("EEE, dd MMM yyyy HH:mm:ss Z", 'en_US').parseUtc(utc).toLocal();
      // 24-часовой формат
      return DateFormat('dd.MM.yyyy HH:mm').format(parsed);
    } catch (_) {
      return utc;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<CurrencyPrefs>();
    final isFav = prefs.isFavorite(_from, _to);

    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.currencyTitle.tr()),
        actions: [
          IconButton(
            tooltip: LocaleKeys.actionsRefresh.tr(),
            onPressed: _loading ? null : () async {
              _currencyService.clearCache();
              await _refreshRates();
            },
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: isFav ? LocaleKeys.currencyRemoveFromFavorites.tr() : LocaleKeys.currencyAddToFavorites.tr(),
            onPressed: () async {
              await prefs.toggleFavorite(_from, _to);
            },
            icon: Icon(isFav ? Icons.star : Icons.star_border),
          ),
        ],
      ),
      body: SafeArea(
        top: true,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                      decoration: InputDecoration(
                        labelText: LocaleKeys.currencyAmount.tr(),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => _convert(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _to,
                      decoration: InputDecoration(
                        labelText: LocaleKeys.currencyTo.tr(),
                        border: const OutlineInputBorder(),
                      ),
                      items: _currencies
                          .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                          .toList(growable: false),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _to = v);
                        _convert();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: LocaleKeys.currencySwap.tr(),
                    onPressed: _swap,
                    icon: const Icon(Icons.swap_horiz),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _from,
                      decoration: InputDecoration(
                        labelText: LocaleKeys.currencyFrom.tr(),
                        border: const OutlineInputBorder(),
                      ),
                      items: _currencies
                          .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                          .toList(growable: false),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _from = v);
                        _refreshRates();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    '${LocaleKeys.currencyLastUpdate.tr()}: ${_formatUpdateTime(_lastUpdatedUtc)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocaleKeys.currencyResult.tr(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _result == null
                            ? '-'
                            : NumberFormat('#,##0.####', 'en_US').format(_result),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (prefs.favoritePairs.isNotEmpty) ...[
                Text(
                  LocaleKeys.currencyFavorites.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: prefs.favoritePairs.map((p) {
                    final parts = p.split('_');
                    final from = parts.first;
                    final to = parts.last;
                    return ActionChip(
                      label: Text('$from → $to'),
                      onPressed: () {
                        setState(() {
                          _from = from;
                          _to = to;
                        });
                        _refreshRates();
                      },
                    );
                  }).toList(growable: false),
                ),
                const SizedBox(height: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            LocaleKeys.currencyHistory.tr(),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: prefs.history.isEmpty ? null : () => prefs.clearHistory(),
                          icon: const Icon(Icons.clear_all),
                          label: Text(LocaleKeys.actionsClear.tr()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: prefs.history.isEmpty
                          ? Center(
                              child: Text(
                                LocaleKeys.currencyHistoryEmpty.tr(),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            )
                          : ListView.separated(
                              itemCount: prefs.history.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final it = prefs.history[index];
                                final ts = DateFormat('dd.MM.yyyy HH:mm').format(it.timestamp);
                                return ListTile(
                                  title: Text(
                                    '${NumberFormat('#,##0.####', 'en_US').format(it.amount)} ${it.fromCurrency} → '
                                    '${NumberFormat('#,##0.####', 'en_US').format(it.result)} ${it.toCurrency}',
                                  ),
                                  subtitle: Text(ts),
                                  trailing: IconButton(
                                    tooltip: LocaleKeys.currencyUsePair.tr(),
                                    icon: const Icon(Icons.north_east),
                                    onPressed: () {
                                      setState(() {
                                        _from = it.fromCurrency;
                                        _to = it.toCurrency;
                                        _amountController.text = it.amount.toString();
                                      });
                                      _refreshRates();
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


