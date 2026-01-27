# 🎯 Система Режимов Работы Приложения

## Обзор

Приложение имеет два режима работы:

- **🔥 Боевой режим (Combat Mode)** - показывается только экран займов
- **🛡️ Небоевой режим (Non-Combat Mode)** - показывается полное приложение с VPN офферами

## Алгоритм Определения Режима

Система проходит через 8 последовательных проверок:

### 1. 📡 Проверка Интернета
```dart
// Проверяет подключение к интернету
final hasInternet = await _checkInternetConnection();
```
**Результат**: Если нет интернета → **небоевой режим**

### 2. 🔥 Проверка Firebase Firestore
```dart
// Проверяет подключение к Firebase
final hasFirebaseConnection = await _firebaseService.checkConnection();
```
**Результат**: Если нет подключения к Firebase → **небоевой режим**

### 3. ⚙️ Загрузка Настроек Firebase
```dart
// Получает настройки из settings/general
final settings = await _firebaseService.getSettings();
```
**Результат**: Если не удалось загрузить настройки → **небоевой режим**

### 4. 🔒 Проверка VPN
```dart
// Проверяет статус VPN (с учетом настроек)
final hasVpn = await _checkVpnStatus(settings.checkVPN);
```
**Особенности**:
- Если `checkVPN = false` в настройках → VPN считается выключенным
- Если `checkVPN = true` → проверяется реальный статус VPN
**Результат**: Если VPN **включен** → **небоевой режим** (блокирует боевой режим)

### 5. 📍 Проверка Настройки checkLocation
```dart
// Проверяет включена ли проверка локации
final locationCheckEnabled = settings.checkLocation;
```
**Результат**: Если `checkLocation = false` → **небоевой режим**

### 6. 🌍 Определение Страны Пользователя
```dart
// Определяет страну по IP адресу
final userCountry = await _getUserCountryByIp();
```
**Результат**: Если не удалось определить страну → **небоевой режим**

### 7. ✅ Проверка Разрешенных Стран
```dart
// Проверяет есть ли страна в списке разрешенных
final allowedCountries = settings.location.split('/');
// Приводим все к нижнему регистру для сравнения
final allowedCountriesLower = allowedCountries.map((c) => c.toLowerCase()).toList();
final isAllowed = allowedCountriesLower.contains(userCountry);
```
**Особенности**:
- Сравнение происходит **независимо от регистра**
- `"RU/KZ"` в настройках → `["ru", "kz"]` для сравнения
- `"ru"` от API → совпадает с `"ru"` из настроек
**Результат**: Если страна не в списке разрешенных → **небоевой режим**

### 8. 💼 Проверка Коллекции boy_offers
```dart
// Проверяет наличие коллекции boy_offers_new_[код_страны]
final hasBoyOffers = await _checkBoyOffersCollection(userCountry);
```
**Результат**: Если коллекция не найдена → **небоевой режим**

### 🎯 Финальный Результат
Если все 8 проверок пройдены → **боевой режим**

## Структура Настроек Firebase

```json
// settings/general
{
  "checkInternet": true,    // Проверять интернет
  "checkLocation": true,    // Проверять локацию
  "checkSIM": true,         // Проверять SIM-карту
  "checkVPN": true,         // Проверять VPN
  "location": "RU/KZ"       // Разрешенные страны (через /)
}
```

## Использование

### Инициализация
```dart
void main() async {
  // ... другая инициализация
  
  // Определение режима работы
  final appModeService = AppModeService();
  await appModeService.determineAppMode();
  
  runApp(MyApp());
}
```

### В UI
```dart
class HomeScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    final appModeService = AppModeService();
    
    if (appModeService.currentMode == AppMode.combat) {
      // Боевой режим - только экран займов
      return LoansScreen();
    } else {
      // Небоевой режим - полное приложение
      return FullAppScreen();
    }
  }
}
```

### В Экране Займов
```dart
class LoansScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    final isCombatMode = AppModeService().currentMode == AppMode.combat;
    
    if (isCombatMode) {
      // Показать информацию о займах
      return _buildCombatModeContent();
    } else {
      // Показать VPN офферы
      return _buildNonCombatModeContent();
    }
  }
}
```

## Логирование

Каждое определение режима логируется с детальной информацией:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 APP MODE DETERMINATION RESULT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Mode: 🔥 COMBAT
Reason: All checks passed - combat mode enabled

Check Details:
  ✅ Internet Connection: true
  ✅ Firebase Connection: true
  🔴 VPN Status: false (VPN OFF - allows combat mode)
  ✅ Location Check Enabled: true
  ✅ User Country: ru
  ✅ User Country Allowed: true
  ✅ Boy Offers Collection: true
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Или когда VPN блокирует боевой режим:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 APP MODE DETERMINATION RESULT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Mode: 🛡️ NON-COMBAT
Reason: VPN is enabled (blocks combat mode)

Check Details:
  ✅ Internet Connection: true
  ✅ Firebase Connection: true
  🔴 VPN Status: true (VPN ON - blocks combat mode)
  ❌ Location Check Enabled: true
  ❌ User Country: ru
  ❌ User Country Allowed: true
  ❌ Boy Offers Collection: true
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Или когда страна не в списке разрешенных:**
```
✅ Step 7: Checking allowed countries...
   📍 User country: "us"
   📍 Allowed countries (original): [RU, KZ]
   📍 Allowed countries (lowercase): [ru, kz]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 APP MODE DETERMINATION RESULT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Mode: 🛡️ NON-COMBAT
Reason: User country "us" is not in allowed list: [ru, kz]

Check Details:
  ✅ Internet Connection: true
  ✅ Firebase Connection: true
  🔴 VPN Status: false (VPN OFF - allows combat mode)
  ✅ Location Check Enabled: true
  ✅ User Country: us
  ❌ User Country Allowed: false
  ❌ Boy Offers Collection: true
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## API Сервиса

### AppModeService

```dart
class AppModeService {
  // Определить режим работы
  Future<AppModeResult> determineAppMode();
  
  // Получить текущий режим
  AppMode? get currentMode;
  
  // Получить последний результат
  AppModeResult? get lastResult;
  
  // Установить режим вручную (для тестирования)
  void setMode(AppMode mode, {String reason = 'Manual override'});
  
  // Сбросить режим
  void resetMode();
}
```

### AppModeResult

```dart
class AppModeResult {
  final AppMode mode;           // Режим работы
  final String reason;          // Причина определения
  final Map<String, dynamic> checks; // Детали проверок
  
  void logResult(); // Логирование результата
}
```

## Тестирование

### Ручная Установка Режима
```dart
final appModeService = AppModeService();

// Установить боевой режим
appModeService.setMode(AppMode.combat, reason: 'Testing combat mode');

// Установить небоевой режим
appModeService.setMode(AppMode.nonCombat, reason: 'Testing non-combat mode');

// Сбросить для автоматического определения
appModeService.resetMode();
```

### Проверка Текущего Режима
```dart
final currentMode = AppModeService().currentMode;
final lastResult = AppModeService().lastResult;

if (currentMode == AppMode.combat) {
  //print('🔥 Combat mode active');
  //print('Reason: ${lastResult?.reason}');
} else {
  //print('🛡️ Non-combat mode active');
}
```

## Особенности Реализации

### VPN Детектор
- Использует пакет `vpn_detector`
- Создается экземпляр `VpnDetector()` для проверки
- Учитывает настройку `checkVPN` из Firebase

### Определение Страны
- Использует API `https://ipapi.co/json/`
- Извлекает `country_code` из JSON ответа
- Приводит к нижнему регистру

### Проверка Коллекций
- Проверяет наличие коллекции `boy_offers_new_[код_страны]`
- Использует метод `getBoyOffers()` из FirebaseService
- Считает коллекцию существующей если есть видимые офферы

## Безопасность

- Все проверки выполняются последовательно
- При любой ошибке включается небоевой режим
- Детальное логирование для отладки
- Возможность ручной установки режима для тестирования

## Производительность

- Проверки выполняются один раз при запуске
- Результат кэшируется в `_currentMode`
- Можно принудительно переопределить режим
- Минимальное влияние на UI

---

**Примечание**: Эта система обеспечивает гибкое управление режимами работы приложения в зависимости от различных условий и настроек Firebase.
