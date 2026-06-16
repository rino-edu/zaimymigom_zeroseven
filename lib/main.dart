import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:zaimymigom_zeroseven/utils/theme.dart';
import 'package:zaimymigom_zeroseven/widgets/connectivity_listener.dart';
import 'services/firebase_service.dart';
import 'services/firebase_auth_service.dart';
import 'services/fcm_service.dart';
import 'services/app_mode_service.dart';
import 'services/appmetrica_service.dart';
import 'services/vpn_startup_service.dart';
import 'services/varioqub_service.dart';
import 'services/settings_service.dart';
import 'services/budget_provider.dart';
import 'services/goals_provider.dart';
import 'services/currency_prefs.dart';
import 'services/calendar_provider.dart';
import 'services/creditworthiness_provider.dart';
import 'views/vpn/app_startup_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Инициализация Firebase
  final firebaseService = FirebaseService();
  await firebaseService.initialize();

  // Анонимная авторизация (нужна для записи в Firestore с правилами по UID)
  final authService = FirebaseAuthService();
  await authService.ensureAnonymousSignIn();

  // AppMetrica Push SDK должен активироваться до регистрации push-токена.
  await AppMetricaService().initialize();
  await AppMetricaService.reportVpnStatusOnLaunch();

  await FCMService.instance.initialize();

  // Varioqub (флаги A/B) — после AppMetrica, до гейта онбординга
  await VarioqubService().initialize();

  // На iOS при активном VPN откладываем определение режима до отключения VPN.
  final iosVpnActive = await VpnStartupService.instance.checkIosVpnActive();

  final appModeService = AppModeService();
  if (!iosVpnActive) {
    await appModeService.determineAppMode();
  } else {
    appModeService.resetMode();
  }

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
      title: 'Кредит 7 дней',
      // Локализация
      locale: locale ?? context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      // Темы
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      debugShowCheckedModeBanner: false,
      home: const ConnectivityListener(
        child: AppStartupGate(),
      ),
    );
  }
}
