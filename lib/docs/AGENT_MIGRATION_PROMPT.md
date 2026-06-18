# Промпт для AI-агента: перенос функционала из zaimymigom_zeroseven

> **Назначение:** этот документ — инструкция для AI-агента, который должен реализовать в **другом Flutter iOS-проекте** тот же функционал, что уже есть в референс-проекте `zaimymigom_zeroseven`.
>
> **Контекст целевого проекта:** уже есть базовый Flutter-проект с простой витриной займов/офферов, но **нет** получения данных с сервера, боевого онбординга, VPN-гейта, полной аналитики, LeadGid, AppMetrica Push и server-driven управления.
>
> **Референс:** исходный код и документация лежат в репозитории `zaimymigom_zeroseven`. При реализации **копируй архитектуру и бизнес-логику**, а не слепо пути/Bundle ID/API keys — адаптируй под целевой проект (bundle id, API keys, server URL, display name).

---

## 0. Задача агента (TL;DR)

Реализовать в целевом проекте:

1. **Два режима приложения:** `combat` (витрина займов) и `nonCombat` (полное приложение).
2. **Server-driven config:** HTTP API + Firestore fallback.
3. **Combat onboarding:** многошаговый flow с Firestore-контентом, темой, аналитикой, LeadGid, записью в `users`.
4. **VPN:** iOS hard-block экран + VPN-проверка в app mode.
5. **Push:** Firebase FCM + AppMetrica Push (Delivered/Opened + custom event `push_open`).
6. **Аналитика:** Firebase Analytics + AppMetrica (дублирование событий).
7. **A/B:** Varioqub для `showOnboarding`.
8. **WebLinkService:** aff_sub6/sub10 в ссылках офферов.
9. **LoansScreen:** загрузка офферов с сервера, WebView, ATT (nonCombat).

**Не ломай** существующий UI/навигацию там, где это возможно — интегрируй через гейты (`AppStartupGate` → `AppModeWrapper` → `CombatOnboardingGate`).

---

## 1. Архитектура старта приложения

### 1.1. Порядок инициализации в `main.dart`

Строго соблюдай порядок:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // 1. FCM background handler — ДО Firebase.initializeApp
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // 2. Firebase Core (+ Crashlytics)
  await FirebaseService().initialize();

  // 3. Анонимная auth (нужна для Firestore rules по UID)
  await FirebaseAuthService().ensureAnonymousSignIn();

  // 4. AppMetrica Core + Push SDK — ДО FCM
  await AppMetricaService().initialize();
  await AppMetricaService.reportVpnStatusOnLaunch();

  // 5. FCM
  await FCMService.instance.initialize();
  await AppMetricaService.setupPushOpenTracking();

  // 6. Varioqub — после AppMetrica, до UI-гейта
  await VarioqubService().initialize();

  // 7. iOS VPN gate — если VPN активен, НЕ вызывать determineAppMode
  final iosVpnActive = await VpnStartupService.instance.checkIosVpnActive();
  final appModeService = AppModeService();
  if (!iosVpnActive) {
    await appModeService.determineAppMode();
  } else {
    appModeService.resetMode();
  }

  // 8. Локальные настройки
  await SettingsService().loadSettings();

  runApp(...);
}
```

### 1.2. UI-цепочка

```
MyApp
└── ConnectivityListener
    └── AppStartupGate                    // lib/views/vpn/app_startup_gate.dart
        ├── [iOS VPN active] → VpnBlockedScreen
        └── AppModeWrapper                // lib/views/app_mode_wrapper.dart
            ├── AppMode.combat    → CombatOnboardingGate(appMode: combat)
            └── AppMode.nonCombat → CombatOnboardingGate(appMode: nonCombat)
                └── MainScreen (или существующий home)
```

### 1.3. Файлы для создания (минимальный каркас)

```
lib/
├── main.dart                          // переписать init order + home: AppStartupGate
├── firebase_options.dart              // flutterfire configure
├── config/
│   ├── leadgid_account_token.dart     // gitignored, см. example
│   └── leadgid_account_token.example.dart
├── models/
│   ├── offer.dart
│   ├── firebase_settings.dart
│   ├── settings_show_case.dart
│   └── onboarding_source.dart
├── services/
│   ├── firebase_service.dart
│   ├── firebase_auth_service.dart
│   ├── firebase_analytics_service.dart
│   ├── firebase_crashlytics_service.dart
│   ├── fcm_service.dart
│   ├── appmetrica_service.dart
│   ├── pending_push_open_channel.dart
│   ├── server_data_service.dart
│   ├── app_mode_service.dart
│   ├── vpn_startup_service.dart
│   ├── varioqub_service.dart
│   ├── web_link_service.dart
│   ├── settings_service.dart
│   ├── att_service.dart
│   └── combat_showcase_analytics.dart
├── features/combat_onboarding/
│   ├── models/
│   │   ├── combat_onboarding_config.dart
│   │   ├── combat_onboarding_theme.dart
│   │   └── combat_onboarding_user_payload.dart
│   ├── services/
│   │   ├── combat_onboarding_local_state.dart
│   │   ├── combat_onboarding_firestore_service.dart
│   │   ├── combat_onboarding_user_writer.dart
│   │   ├── combat_settings_resolver.dart
│   │   ├── onboarding_visibility_resolver.dart
│   │   ├── installation_id_service.dart
│   │   ├── leadgid_application_api_service.dart
│   │   └── utils/leadgid_phone_formatter.dart
│   └── ui/
│       ├── combat_onboarding_gate.dart
│       ├── combat_onboarding_flow_screen.dart
│       ├── combat_onboarding_loading_screen.dart
│       ├── combat_onboarding_policy_screen.dart
│       └── combat_onboarding_consent_webview_screen.dart  // опционально, не в flow
├── views/
│   ├── vpn/
│   │   ├── app_startup_gate.dart
│   │   └── vpn_blocked_screen.dart
│   ├── app_mode_wrapper.dart
│   ├── loans/loans_screen.dart
│   └── webview/webview_screen.dart
├── widgets/
│   ├── offer_card.dart
│   └── connectivity_listener.dart
├── utils/
│   ├── theme.dart
│   └── locale_keys.dart
└── docs/                              // справочная документация
```

---

## 2. Зависимости (`pubspec.yaml`)

Добавь (версии можно взять из референса или актуальные совместимые):

```yaml
dependencies:
  # Firebase
  firebase_core: ^4.1.1
  firebase_analytics: ^12.0.0
  firebase_crashlytics: ^5.1.0
  cloud_firestore: ^6.0.0
  firebase_auth: ^6.0.0
  firebase_messaging: ^16.0.0
  firebase_app_installations: ^1.0.0

  # AppMetrica + Push + A/B
  appmetrica_plugin: ^3.4.0
  appmetrica_push_plugin: ^2.2.0
  varioqub_plugin: ^0.1.0

  # Network
  dio: ^5.9.0
  http: ^1.5.0
  connectivity_plus: ^7.0.0

  # State & storage
  provider: ^6.1.2
  shared_preferences: ^2.3.3
  flutter_secure_storage: ^9.2.4

  # UI
  easy_localization: ^3.0.7
  smooth_page_indicator: ^1.2.0
  flutter_markdown: ^0.7.7+1
  webview_flutter: ^4.13.0
  cached_network_image: ^3.3.1

  # Device
  vpn_detector: ^1.1.1
  app_tracking_transparency: ^2.0.4
  device_info_plus: ^12.1.0
  package_info_plus: ^8.0.2

assets:
  - assets/locales/
  - assets/strings/policy.md
  # config.json — локальный, может быть gitignored; добавь в assets если используешь
```

---

## 3. Server-driven config (HTTP API + Firestore)

### 3.1. ServerDataService

**Файл:** `lib/services/server_data_service.dart`

- **Endpoint:** `GET {server_url}/api/client/get-all`
- `server_url` читается из `assets/strings/config.json` (поле `server_url`)
- **Timeout:** 25 секунд (Dio)
- **Кэш:** TTL 5 минут, dedup параллельных запросов через `Completer`
- **forceRefresh:** для combat gate при необходимости

**Парсинг ответа:**

```json
{
  "settings": [{"name": "general", "json": { ... }}],
  "show_case": [{"name": "titles", "json": { ... }}],
  "vpn_offers": [{ ...offer fields... }],
  "boy_offers_RU": [{ ... }],
  "boy_offers_KZ": [{ ... }]
}
```

**Модель `FirebaseSettings`** (`settings/general`):

| Поле | Тип | Описание |
|------|-----|----------|
| `checkInternet` | bool | Проверять интернет в app mode |
| `checkLocation` | bool | Должен быть true для combat |
| `checkSIM` | bool | Зарезервировано |
| `checkVPN` | bool | VPN блокирует combat mode |
| `location` | string | `"RU/KZ"` — страны через `/`, lowercase compare |
| `showOnboarding` | bool | Master switch онбординга |
| `leadGidAPI` | bool | Отправлять заявку в LeadGid |
| `onboardingSource` | string | `"server"` или `"varioqub"` |

**Модель `SettingsShowCase`** (`show_case/titles`):

- `onboardingTrueTitle`, `onboardingFalseTitle`
- `onboardingTrueSubTitle`, `onboardingFalseSubTitle`

**Модель `Offer`:**

- `id`, `is_show`, `link`, `image`, `button_text`, `name`, `stars`
- `field_1_name`, `field_1_value` … `field_8_name`, `field_8_value`
- `background_color_badge_text`, `badge_text`, `border_color_offer`

### 3.2. FirebaseService (Firestore fallback)

**Коллекции (те же имена):**

```
settings/general
show_case/titles
boy_offers_{region}/
vpn_offers/
onboarding/start, theme, page1..pageN, final, animation1, animation2
users/{firebaseAuthUid}/
```

**Паттерн:** lazy Firestore init — Core инициализируется в `initialize()`, Firestore — при первом обращении к данным.

**CombatSettingsResolver:** server first → Firestore fallback для `FirebaseSettings`.

### 3.3. config.json (assets/strings/)

```json
{
  "server_url": "https://YOUR-SERVER-DOMAIN.ru",
  "main_link_global": "https://your-affiliate-link.example/?aff_sub4=boy_showcase"
}
```

---

## 4. App Mode System (combat vs nonCombat)

**Файл:** `lib/services/app_mode_service.dart`

Singleton. Метод `determineAppMode()` — **8 последовательных проверок**. Любой fail → `AppMode.nonCombat`.

| # | Проверка | Fail condition |
|---|----------|----------------|
| 1 | Internet | `connectivity_plus` + GET google.com |
| 2 | Firestore | connection test к `settings/general` |
| 3 | Settings loaded | `getSettings()` not null |
| 4 | VPN | если `checkVPN=true` и VPN active → fail |
| 5 | checkLocation | must be `true` |
| 6 | Country by IP | GET `https://ipinfo.io/json` → поле `country` |
| 7 | Country in list | country lowercase in `settings.location.split('/')` |
| 8 | Offers exist | `boy_offers_{country}` not empty |

**Country detection:** regex `"country"\s*:\s*"([^"]+)"` из JSON ipinfo.

**Кэш:** `_currentMode` сохраняется; `resetMode()` для повторного определения (VPN refresh).

**AppModeWrapper:** читает `AppModeService.currentMode` и направляет в `CombatOnboardingGate`.

---

## 5. VPN

### 5.1. VpnStartupService (iOS hard block)

**Файл:** `lib/services/vpn_startup_service.dart`

- Только iOS: `VpnDetector().isVpnActive()`
- При ошибке → fail-open (VPN = false)
- Флаг `iosVpnBlockedOnLaunch` — если true, `main()` **не** вызывает `determineAppMode()`

### 5.2. VpnBlockedScreen

**Файл:** `lib/views/vpn/vpn_blocked_screen.dart`

- Кнопка «Обновить»:
  1. `checkIosVpnActive()` снова
  2. если VPN off → `AppModeService.resetMode()` + `determineAppMode()` + `AppMetricaService.reportVpnStatusOnLaunch()`
  3. переход к `AppModeWrapper`

**Локализация:** ключи `vpn.blocked_title`, `vpn.blocked_description`, `vpn.blocked_hint`, `vpn.blocked_refresh`.

### 5.3. AppMetrica VPN events

| Событие | Когда |
|---------|-------|
| `vpn_status_on` | VPN активен при старте |
| `vpn_status_off_after_on` | VPN выключен, ранее был `vpn_status_on` |

**Параметр `data`:** `"{appmetricaDeviceIdHash}, {countryCode}, {yyyy-MM-dd HH:mm:ss}"` GMT+3.

**Prefs key:** `vpn_were_opened` (bool).

---

## 6. Combat Onboarding

### 6.1. CombatOnboardingGate — логика решения

**Файл:** `lib/features/combat_onboarding/ui/combat_onboarding_gate.dart`

```
syncInstallSession()
processOnboardingAbandonOnLaunch()   // только combat
isFirstOpen() → getOrSetFirstOpenDate()

if nonCombat:
  writeNotShownIfFirstOpen()
  → MainScreen

if combat && wasOnboardingShown:
  → LoansScreen()

if combat && !showOnboarding (master OFF или Varioqub OFF):
  writeNotShownIfFirstOpen()
  → LoansScreen(showCaseOnboardingReason: withoutOnboarding)

if combat && showOnboarding:
  → CombatOnboardingFlowScreen
```

**Важно:** показ онбординга привязан к `combat_onboarding_was_shown`, **не** к «первому запуску приложения».

**Combat mode only:** регистрируй `CombatShowcaseLifecycleObserver` для `showcase_not_shown`.

### 6.2. OnboardingVisibilityResolver

```
if settings.showOnboarding == false → false
if onboardingSource == "server" → true
if onboardingSource == "varioqub" → Varioqub flag OR fallback server
```

Varioqub flag: `showOnboarding` string `"true"`/`"false"`. Если ключа нет → fallback server.

### 6.3. CombatOnboardingFlowScreen

**Flow (PageView, physics: NeverScrollableScrollPhysics, PopScope canPop: false):**

```
start → page1..pageN → final → loading1 → loading2 → LoansScreen(finish)
```

**Загрузка контента:**
- Firestore `onboarding/*` через `CombatOnboardingFirestoreService`
- 1 retry: `fetchConfigWithOneRetry()`
- Ошибка → `LoansScreen(close)` без контента

**Firestore документы:**

| Doc | Поля |
|-----|------|
| `start` | title, body, primaryButtonText |
| `theme` | 6 hex colors (без alpha prefix) |
| `page{N}` | question, options[4] |
| `final` | title, body, primaryButtonText, consentText, consentLink |
| `animation1/2` | title, durationSeconds |

**6 цветов темы:** backgroundColor, titleTextColor, bodyTextColor, primaryButtonBgColor, primaryButtonTextColor, optionButtonBgColor.

**Dark mode:** extension `CombatOnboardingTheme.forFlowBrightness()` — в dark подменяет background/surface на AppColors dark.

**Final screen:**
- Телефон +7, checkbox согласия
- Consent → `CombatOnboardingPolicyScreen` (markdown `assets/strings/policy.md`)
- Continue → `onboarding_finish` + LeadGid API + loading screens

**Close (✕):** `onboarding_close` + Firestore write + `LoansScreen(close)`.

**Loading screens:** locked timer по `durationSeconds` из Firestore.

**После animation2:** `fully_completed=true`, Firestore `endOnbord=true`, → `LoansScreen(finish)`.

### 6.4. Локальное состояние (SharedPreferences + Keychain iOS)

| Key | Назначение |
|-----|------------|
| `combat_onboarding_was_shown` | Контент показан |
| `combat_onboarding_fully_completed` | Дошли до конца |
| `combat_onboarding_flow_active` | В процессе flow |
| `combat_onboarding_abandoned` | Уход в фон |
| `combat_onboarding_first_open_at_iso` | ISO дата первого открытия |
| `combat_onboarding_last_known_install_time_ms` | Отпечаток установки |
| Keychain: `combat_onboarding_install_session_id` | iOS session для reinstall detection |

**syncInstallSession():** детект переустановки → сброс флагов онбординга.

**Kill detection:** `CombatShowcaseLifecycleObserver` → inactive/paused/detached + flow_active + !fully_completed → abandoned. Cold start → `processOnboardingAbandonOnLaunch()` → aff_sub10=`onboarding_kill`.

### 6.5. Firestore users/{uid}

**User ID:** `FirebaseAuth.uid` (anonymous), **не** Installations ID.

**Поля:**

```dart
{
  "id": uid,
  "appmetricaId": deviceIdHash,
  "firstOpenDate": iso8601,
  "endOnbord": bool,
  "lastOnbordpage": "current/total" | "Not shown",
  "answersOnbord": { "page1": "answer", ... },
  "phone": "..." // merge, только если не null
}
```

**writeNotShownIfFirstOpen:** первый запуск + (nonCombat OR withoutOnboarding) → lastOnbordpage="Not shown".

**writeResult:** merge `SetOptions(merge: true)`, timeout 10s.

### 6.6. Onboarding analytics (Firebase + AppMetrica, дублировать оба)

| Событие | Когда | Параметры |
|---------|-------|-----------|
| `onboarding_show` | Конфиг загружен | — |
| `onboarding_start` | «Продолжить» на start | — |
| `onboarding_page_{N}` | Ответ на pageN | `question_answer` (max 100 chars GA) |
| `onboarding_close` | ✕ | `page_number` (1-based) |
| `onboarding_finish` | Final continue | — |

---

## 7. LeadGid API

**Файл:** `lib/features/combat_onboarding/services/leadgid_application_api_service.dart`

```
POST https://api.leadgid.com/universal/v1/ru/applications
Header: X-ACCOUNT-TOKEN: {token}
Body: {"phone": "9XXXXXXXXX"}   // 10 цифр, без +7
```

**Token:** `lib/config/leadgid_account_token.dart` (gitignored):

```dart
class LeadGidAccountToken {
  static const String accountToken = 'YOUR_TOKEN';
  static bool get isConfigured => accountToken.isNotEmpty && accountToken != 'YOUR_TOKEN';
}
```

**Enabled:** `settings.leadGidAPI == true` (server priority).

**Trigger:** после final continue, **до** loading screens.

**Errors:** log only, не блокируют UX.

**Phone formatter:** `+7XXXXXXXXXX` → `9XXXXXXXXX`.

---

## 8. LoansScreen (витрина офферов)

**Файл:** `lib/views/loans/loans_screen.dart`

**Загрузка офферов (приоритет server → Firestore):**

| Mode | Source |
|------|--------|
| combat | `boy_offers_{country}` |
| nonCombat | `vpn_offers` |

Фильтр: `is_show == true`, sort by `id` asc.

**Showcase analytics:**

| Событие | Когда |
|---------|-------|
| `showcase_shown` | combat initState |
| `showcase_not_shown` | 2s после pause, onboarding_show && !loans_opened |
| `showcase_error` | load error, param `message` |
| `show_case_onboarding_finish` | reason=finish |
| `show_case_onboarding_close` | reason=close |
| `show_case_onboarding_none` | reason=withoutOnboarding |

**Offer tap:**

1. `WebLinkService.generateModifiedOfferLink(offer.link)`
2. `offer_open` event (`link`, `name`)
3. `WebViewScreen(offer, url_link: modifiedUrl)`

**ATT (nonCombat only):** delay 1s, `ATTService.requestIfFirstLaunch()`.

**Dark theme:** subtitle block — dark surface + white text (если есть subtitle).

---

## 9. WebLinkService

**Файл:** `lib/services/web_link_service.dart`

Singleton. **Combat only** модификация ссылок.

**Из config.json:** `main_link_global`.

**buildMainLink():** `aff_sub4=vpn` → `aff_sub4=boy_showcase`, добавляет `aff_sub6={appmetricaDeviceIdHash}`, `aff_sub10={sub10}`.

**aff_sub10 values:**

| Значение | Когда |
|----------|-------|
| `onboarding_finish` | Завершил онбординг |
| `onboarding_close` | Закрыл ✕ |
| `onboarding_none` | Без онбординга |
| `onboarding_kill` | Kill во время flow |

**aff_sub10 applied once:** prefs `aff_sub10_applied=true` после первой подстановки.

**nonCombat:** ссылка без модификации (только https fix).

---

## 10. Push notifications

### 10.1. FCMService

**Файл:** `lib/services/fcm_service.dart`

- `requestPermission(alert, badge, sound)`
- `setForegroundNotificationPresentationOptions`
- `getToken()`, `onTokenRefresh`
- `onMessage`, `onMessageOpenedApp`, `getInitialMessage`
- Background handler: `@pragma('vm:entry-point')`, только Firebase init + log

### 10.2. AppMetrica Push

**Dart:** `AppMetricaPush.activate()` в `_initPush()`, **до** FCM.

**Сразу после activate:**
- `_attachPushClickListener()` — `pushClickStream`
- `_handleColdStartPushOpen()` — native buffer + `getLaunchPushInfo()`

**setupPushOpenTracking()** (после FCM):
- `onMessageOpenedApp` + `getInitialMessage` fallback

### 10.3. Custom event `push_open`

**AppMetricaService.reportPushOpen({payload, messageId})**

Dedup 3 секунды. После отправки — `PendingPushOpenChannel.clear()`.

**Источники:**

1. `AppMetricaPush.pushClickStream` (warm)
2. `PendingPushOpenChannel.consumeLaunchPush()` (cold start native buffer)
3. `AppMetricaPush.getLaunchPushInfo()` (fallback)
4. FCM `onMessageOpenedApp` / `getInitialMessage`

### 10.4. iOS native (обязательно)

**AppDelegate.swift:**

- `AppMetricaPush.setExtensionAppGroup("group.{bundle}.appmetrica")`
- **НЕ** ставить `userNotificationCenter.delegate` вручную — делает `appmetrica_push_plugin` (иначе infinite recursion)
- `Messaging.messaging().delegate = self`
- `PendingPushOpenStorage` в UserDefaults при cold start + tap
- MethodChannel `com.{bundle}/pending_push_open`
- `clearApplicationBadge()` в `applicationDidBecomeActive`

**NSE target `PushNotificationServiceExtension`:**

```swift
AppMetricaPush.setExtensionAppGroup(appGroup)
AppMetricaPush.handleDidReceive(request)
AppMetrica.sendEventsBuffer()
contentHandler(bestAttemptContent)
```

**Entitlements:** App Group в Runner + NSE, Push Notifications, aps-environment dev/prod.

**Info.plist NSE:** используй `$(MARKETING_VERSION)` / `$(CURRENT_PROJECT_VERSION)` + xcconfig с `Generated.xcconfig`.

**CFBundleName в Runner Info.plist:** не оставляй имя другого проекта — используй `$(PRODUCT_NAME)`.

Подробнее: `lib/docs/APPMETRICA_PUSH_IOS_SETUP.md` в референсе.

### 10.5. Android (если нужен)

**MainActivity.kt:** `PendingPushOpenStorage` в SharedPreferences, MethodChannel тот же.

---

## 11. Аналитика — полный каталог событий

### Firebase Analytics + AppMetrica (дублировать оба, кроме screen_view)

| Event | Parameters | Source |
|-------|------------|--------|
| `onboarding_show/start/finish/close/page_{N}` | см. §6.6 | onboarding flow |
| `showcase_shown/not_shown/error` | message | LoansScreen |
| `show_case_onboarding_finish/close/none` | — | LoansScreen reason |
| `offer_open` | link, name | offer tap |
| `push_open` | payload, message_id | push tap |
| `vpn_status_on/off_after_on` | data | launch/VPN refresh |
| `screen_view` | screen_name | AppMetrica only |
| `app_error` | error, reason | errors |
| `user_attribute` | attribute_key, value | profile |

**GA4 trim:** параметры max 100 символов.

**AppMetrica API key:** вынести в config, не хардкодить в git.

**Device ID:** `AppMetricaService.getDeviceIdHash()` → aff_sub6, users.appmetricaId. Кэш в prefs.

---

## 12. Varioqub (A/B)

**Файл:** `lib/services/varioqub_service.dart`

- Init после AppMetrica: `initVarioqubWithAppMetricaAdapter`
- `clientId` — из AppMetrica dashboard (в референсе: `appmetrica.4796974`)
- Flag: `showOnboarding` → `"true"`/`"false"`
- `activateConfig()` + background `fetchConfig()`
- Без defaults — missing key → fallback server settings

---

## 13. Settings, theme, localization

**SettingsService:** theme (light/dark/system), language (ru/en/system), pin, biometric — SharedPreferences + ChangeNotifier.

**Theme:** Material 3, `AppTheme.lightTheme` / `darkTheme`, `themeMode` from settings.

**Localization:** easy_localization, `assets/locales/en.json`, `ru.json`, fallback en, 24h time format.

**LocaleKeys:** константы для `.tr()`.

---

## 14. Firebase Auth

Anonymous sign-in **обязателен** до Firestore writes:

```dart
await FirebaseAuth.instance.signInAnonymously();
```

User ID для `users/{uid}` = `FirebaseAuth.currentUser.uid`.

---

## 15. iOS checklist

- [ ] `Runner.xcworkspace` (не .xcodeproj напрямую с pods)
- [ ] Push Notifications capability
- [ ] App Groups: `group.{bundle}.appmetrica`
- [ ] NSE target embedded (Embed Without Signing — OK)
- [ ] `GoogleService-Info.plist`
- [ ] `NSUserTrackingUsageDescription` для ATT
- [ ] Background modes: `fetch`, `remote-notification`
- [ ] AppMetrica APNs key в dashboard (production для TestFlight)
- [ ] `CFBundleName` = `$(PRODUCT_NAME)` (не старое имя проекта)
- [ ] Team ID / provisioning profiles для app + NSE

---

## 16. Порядок реализации для агента

### Фаза 1 — Foundation
1. pubspec dependencies
2. `firebase_options.dart`, Firebase init, anonymous auth
3. `FirebaseService`, `ServerDataService`, models
4. `AppModeService` + `AppModeWrapper`
5. `main.dart` init order + `AppStartupGate`

### Фаза 2 — VPN + Settings
6. `VpnStartupService`, `VpnBlockedScreen`, локализация
7. `SettingsService`, theme, easy_localization

### Фаза 3 — Analytics base
8. `AppMetricaService`, `FirebaseAnalyticsService`
9. `FCMService`, background handler
10. iOS AppDelegate (без manual delegate!), badge clear

### Фаза 4 — Onboarding
11. Firestore onboarding service + models + theme
12. All onboarding UI screens + gate
13. Local state, user writer, visibility resolver
14. Onboarding analytics events
15. LeadGid API + token config

### Фаза 5 — Offers + Links
16. `LoansScreen` server-first loading
17. `WebLinkService`, `OfferCard`, `WebViewScreen`
18. Showcase analytics + lifecycle observer
19. ATT for nonCombat

### Фаза 6 — Push advanced
20. AppMetrica Push NSE target (iOS)
21. `PendingPushOpenChannel` + native storage
22. `push_open` event all paths
23. `setupPushOpenTracking`

### Фаза 7 — Varioqub
24. `VarioqubService` + `OnboardingVisibilityResolver`

### Фаза 8 — Polish
25. Dark theme fixes (onboarding, loans subtitle)
26. Error handling, logging
27. Docs in target project

---

## 17. Критические бизнес-правила (не нарушать)

1. **Онбординг один раз** — флаг `was_shown`, не first launch.
2. **Master OFF** (`showOnboarding=false`) перекрывает Varioqub.
3. **Varioqub без эксперимента** → fallback server.
4. **aff_sub10 один раз** в первую ссылку; kill → `onboarding_kill`.
5. **User ID = Firebase Auth UID**, не Installations ID.
6. **LeadGid opt-in** через `leadGidAPI`; token gitignored.
7. **iOS VPN hard block** — до `determineAppMode()`.
8. **AppMetrica Push до FCM** в init order.
9. **Не ставить AppMetrica UNUserNotificationCenter delegate вручную** — recursion crash.
10. **Server first, Firestore fallback** для settings и offers.
11. **LeadGid errors не блокируют** onboarding UX.
12. **PopScope canPop: false** в onboarding — back заблокирован.
13. **Consent policy** — локальный markdown, не WebView по умолчанию.

---

## 18. Тест-план после реализации

Собери приложение и проверь:

### App Mode
- [ ] Combat: RU IP + offers + no VPN → LoansScreen
- [ ] NonCombat: VPN on (checkVPN) / wrong country / no offers → MainScreen
- [ ] iOS VPN on launch → VpnBlockedScreen → off VPN → refresh → app opens

### Onboarding
- [ ] First combat launch + showOnboarding → full flow
- [ ] Second launch → LoansScreen directly
- [ ] Kill mid-flow → restart → aff_sub10=onboarding_kill on first offer link
- [ ] showOnboarding=false → skip onboarding
- [ ] Varioqub onboardingSource=varioqub

### Server
- [ ] Offers load from API
- [ ] API fail → Firestore fallback
- [ ] Settings change on server reflected after cache TTL

### Analytics
- [ ] All onboarding events in Firebase + AppMetrica
- [ ] showcase_shown, offer_open
- [ ] push_open: background tap, foreground tap, **cold start tap**
- [ ] vpn_status_on/off

### Push
- [ ] Push arrives (AppMetrica campaign)
- [ ] Delivered in AppMetrica report (NSE)
- [ ] Opened in AppMetrica report
- [ ] Badge appears, clears on app open
- [ ] No crash on push tap

### LeadGid
- [ ] POST with valid phone when leadGidAPI=true
- [ ] Skip when leadGidAPI=false

---

## 19. Что уже есть в целевом проекте (не переписывать с нуля)

Агент должен **изучить существующий код** целевого проекта и:

- Сохранить существующие экраны/навигацию где возможно
- Заменить/расширить простую витрину офферов на `LoansScreen` с server loading
- Подключить `AppStartupGate` как новый `home` вместо прямого MainScreen
- Не дублировать Firebase project — использовать свой `firebase_options.dart`
- Адаптировать bundle id, App Group, server URL, API keys

---

## 20. Справочные документы в референс-проекте

Если есть доступ к `zaimymigom_zeroseven`, читай:

| Файл | Содержание |
|------|------------|
| `lib/docs/APP_MODE_SYSTEM.md` | App mode checks |
| `lib/docs/COMBAT_ONBOARDING_ANALYTICS.md` | Onboarding events |
| `lib/docs/COMBAT_ONBOARDING_FIRESTORE.md` | Firestore schema (§2.1 устарел) |
| `lib/docs/COMBAT_ONBOARDING_ONBOARDING_SOURCE.md` | Varioqub A/B |
| `lib/docs/FIREBASE_GUIDE.md` | Firebase setup |
| `lib/docs/APPMETRICA_PUSH_IOS_SETUP.md` | Push iOS NSE setup |

---

## 21. Инструкция агенту по работе

1. **Сначала** прочитай структуру целевого проекта (`lib/`, `pubspec.yaml`, `ios/`).
2. **Сверь** что уже реализовано vs этот документ.
3. **Реализуй по фазам** (§16), каждую фазу — рабочий инкремент.
4. **Копируй** файлы из референса, адаптируя imports/package name/bundle id.
5. **Не коммить** secrets: LeadGid token, API keys, config.json с prod URL.
6. **После каждой фазы** предложи пользователю собрать и протестировать приложение.
7. **Логируй** debugPrint в сервисах для отладки server/push/onboarding.
8. **Минимальный diff** — не рефактори unrelated код.

---

*Документ сгенерирован на основе референс-проекта zaimymigom_zeroseven. Версия референса: 1.3.2+.*
