import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:zaimymigom_zeroseven/services/appsflyer_service.dart';
import 'package:zaimymigom_zeroseven/services/config_service.dart';
import 'package:zaimymigom_zeroseven/utils/theme.dart';
import 'package:zaimymigom_zeroseven/views/loans/loans_screen.dart';
import 'services/firebase_service.dart';
import 'services/app_mode_service.dart';
import 'services/appmetrica_service.dart';
import 'services/settings_service.dart';
import 'services/budget_provider.dart';
import 'services/goals_provider.dart';
import 'services/currency_prefs.dart';
import 'services/calendar_provider.dart';
import 'services/creditworthiness_provider.dart';
import 'views/home/main_screen.dart';
import 'views/onboarding/onboarding_screen.dart';
import 'views/webview/webview_screen.dart';
import 'models/offer.dart';
import 'services/webview_link_service.dart';
import 'services/firebase_messaging_service.dart';
import 'package:facebook_app_events/facebook_app_events.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Инициализация AppMetrica
  await AppMetricaService().initialize();

  // Инициализация Firebase
  final firebaseService = FirebaseService();
  await firebaseService.initialize();

  // Инициализация Firebase Cloud Messaging
  try {
    await FirebaseMessagingService().initialize();
  } catch (e) {
    // Игнорируем ошибки инициализации FCM, чтобы приложение могло запуститься
    if (kDebugMode) {
      //print('[MAIN] Firebase Messaging initialization error: $e');
    }
  }

  try {
    final facebookAppEvents = FacebookAppEvents();
    facebookAppEvents.setAutoLogAppEventsEnabled(true);
  } catch (e) {
    debugPrint('[PostFrame] Facebook events init error: $e');
  }

  // Инициализация AppsFlyer
  final afDevKey = ConfigService.getKey('af_dev_key');
  if (afDevKey != null) {
    try {
      await AppsFlyerService.initialize(afDevKey);
    } catch (e) {
      debugPrint('[PostFrame] AppsFlyer init error: $e');
    }
  }

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
      fallbackLocale: const Locale('ru'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settingsService),
          ChangeNotifierProvider(create: (_) => BudgetProvider()),
          ChangeNotifierProvider(create: (_) => GoalsProvider()),
          ChangeNotifierProvider(create: (_) => CurrencyPrefs()..load()),
          ChangeNotifierProvider(create: (_) => CalendarProvider()..load()),
          ChangeNotifierProvider(
            create: (_) {
              final provider = CreditworthinessProvider();
              provider.initialize();
              return provider;
            },
          ),
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
      title: 'Займ сразу',
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
    final settings = context.watch<SettingsService>();
    // Если режим еще не определен (теоретически), показываем лоадер
    if (appMode == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // В боевом режиме — сразу LoansScreen c боевыми офферами
    if (appMode == AppMode.combat) {
      return const LoansScreen();
    }

    // В небоевом режиме — если онбординг не пройден, сначала онбординг
    if (!settings.onboardingCompleted) {
      return const OnboardingScreen();
    }
    return const MainScreen();
  }
}
