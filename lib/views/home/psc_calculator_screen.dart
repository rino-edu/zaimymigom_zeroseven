import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../utils/locale_keys.dart';

/// Экран калькулятора полной стоимости кредита (ПСК)
class PscCalculatorScreen extends StatelessWidget {
  const PscCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.pscCalculatorTitle.tr()),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calculate,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                LocaleKeys.pscCalculatorPlaceholder.tr(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

