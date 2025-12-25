import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:zaimymigom_zeroseven/services/appsflyer_service.dart';
import 'package:zaimymigom_zeroseven/services/config_service.dart';
import 'package:zaimymigom_zeroseven/utils/theme.dart';
import 'package:zaimymigom_zeroseven/views/loans/loans_screen.dart';
import 'firebase_options.dart';
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
import 'views/splash/splash_screen.dart';
import 'services/firebase_messaging_service.dart';
import 'package:facebook_app_events/facebook_app_events.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Инициализация Firebase Core ПЕРЕД runApp
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
    name: 'budgetbox',
  );

  // Загрузка конфигурации
  await ConfigService.loadConfig();

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

  // Загрузка настроек
  final settingsService = SettingsService();
  await settingsService.loadSettings();
  
  // Примечание: Определение режима работы теперь происходит в AppModeWrapper
  // после показа SplashScreen, чтобы пользователь видел загрузку

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

class AppModeWrapper extends StatefulWidget {
  const AppModeWrapper({super.key});

  @override
  State<AppModeWrapper> createState() => _AppModeWrapperState();
}

class _AppModeWrapperState extends State<AppModeWrapper> {
  bool _isLoading = true;
  AppMode? _appMode;

  @override
  void initState() {
    super.initState();
    _determineAppMode();
  }

  Future<void> _determineAppMode() async {
    // Определяем режим работы приложения
    final appModeService = AppModeService();
    await appModeService.determineAppMode();

    if (mounted) {
      setState(() {
        _appMode = appModeService.currentMode;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    // Показываем SplashScreen до тех пор, пока не определится режим работы
    if (_isLoading || _appMode == null) {
      return const SplashScreen();
    }

    // В боевом режиме — сразу LoansScreen c боевыми офферами
    if (_appMode == AppMode.combat) {
      return const LoansScreen();
    }

    // В небоевом режиме — если онбординг не пройден, сначала онбординг
    if (!settings.onboardingCompleted) {
      return const OnboardingScreen();
    }
    return const MainScreen();
  }
}
