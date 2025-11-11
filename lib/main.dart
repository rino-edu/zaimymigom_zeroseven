import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:zaimymigom_zeroseven/utils/theme.dart';
import 'services/firebase_service.dart';
import 'services/app_mode_service.dart';
import 'services/appmetrica_service.dart';
import 'services/settings_service.dart';
import 'services/budget_provider.dart';
import 'services/goals_provider.dart';
import 'services/currency_prefs.dart';
import 'services/calendar_provider.dart';
import 'views/loans/loans_screen.dart';
import 'views/home/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Инициализация AppMetrica
  await AppMetricaService.initialize();

  // Инициализация Firebase
  final firebaseService = FirebaseService();
  await firebaseService.initialize();

  // Определение режима работы
  final appModeService = AppModeService();
  await appModeService.determineAppMode();

  // Загрузка настроек
  final settingsService = SettingsService();
  await settingsService.loadSettings();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ru')],
      path: 'assets/locales',
      fallbackLocale: const Locale('en'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settingsService),
          ChangeNotifierProvider(create: (_) => BudgetProvider()),
          ChangeNotifierProvider(create: (_) => GoalsProvider()),
          ChangeNotifierProvider(create: (_) => CurrencyPrefs()..load()),
          ChangeNotifierProvider(create: (_) => CalendarProvider()..load()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    // Определяем локаль из настроек
    Locale? locale;
    if (settings.languageCode != null) {
      locale = Locale(settings.languageCode!);
    }

    return MaterialApp(
      title: 'ПОМЕНЯТЬ',
      // Локализация
      locale: locale ?? context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      // Темы
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      debugShowCheckedModeBanner: false,
      home: const AppModeWrapper(),
    );
  }
}

class AppModeWrapper extends StatelessWidget {
  const AppModeWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final appMode = AppModeService().currentMode;
    // Если режим еще не определен (теоретически), показываем лоадер
    if (appMode == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // В боевом режиме — сразу LoansScreen c боевыми офферами
    if (appMode == AppMode.combat) {
      return const LoansScreen();
    }

    // В небоевом режиме — если онбординг не пройден, сначала онбординг
    // final settings = context.watch<SettingsService>();
    // if (!settings.onboardingCompleted) {
    //   return const OnboardingScreen();
    // }
    return const MainScreen();
  }
}
