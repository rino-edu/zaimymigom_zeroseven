# Firebase Integration Guide

## Обзор

В проекте реализована интеграция с Firebase Firestore для работы с тремя коллекциями:
- `settings` - настройки приложения
- `boy_offers_[код_региона]` - офферы для определенного региона
- `vpn_offers` - VPN офферы

## Структура

### Модели данных

#### 1. FirebaseSettings (`lib/models/firebase_settings.dart`)

Модель для работы с коллекцией `settings`, документ `general`.

**Поля:**
- `checkInternet: bool` - проверять ли интернет
- `checkLocation: bool` - проверять ли локацию
- `checkSIM: bool` - проверять ли SIM-карту
- `checkVPN: bool` - проверять ли VPN
- `location: String` - текущая локация

**Методы:**
- `fromFirestore(Map<String, dynamic>)` - создание объекта из Firestore
- `toFirestore()` - преобразование в Map для Firestore
- `logData()` - вывод данных в лог

#### 2. Offer (`lib/models/offer.dart`)

Модель для работы с коллекциями `boy_offers_[код_региона]` и `vpn_offers`.

**Основные поля:**
- `id: int` - ID оффера (для сортировки)
- `isShow: bool` - показывать ли на витрине
- `link: String` - ссылка для WebView
- `image: String` - URL логотипа (PNG/SVG)
- `buttonText: String` - текст на кнопке
- `name: String` - название оффера
- `stars: String` - рейтинг (поддержка дробных чисел)
- `field1Name/field1Value` ... `field8Name/field8Value` - дополнительные поля

**Полезные методы:**
- `fromFirestore(Map<String, dynamic>, String)` - создание из Firestore
- `toFirestore()` - преобразование в Map
- `getFields()` - получить список всех полей (List<OfferField>)
- `isSvgImage` - проверка, является ли изображение SVG
- `isPngImage` - проверка, является ли изображение PNG
- `starsAsDouble` - получить рейтинг как число double
- `logData()` - вывод данных в лог

### Сервис Firebase

#### FirebaseService (`lib/services/firebase_service.dart`)

Singleton-сервис для работы с Firebase Firestore.

**Инициализация:**
```dart
final firebaseService = FirebaseService();
await firebaseService.initialize();
```

**Основные методы:**

##### Settings (Настройки)

```dart
// Получить настройки один раз
final settings = await firebaseService.getSettings();

// Слушать изменения в реальном времени
firebaseService.watchSettings().listen((settings) {
  if (settings != null) {
    //print('Settings updated: ${settings.location}');
  }
});
```

##### Boy Offers (Офферы для региона)

```dart
// Получить все офферы для региона
final allOffers = await firebaseService.getBoyOffers('RU');

// Получить только видимые офферы (is_show = true)
final visibleOffers = await firebaseService.getVisibleBoyOffers('RU');

// Слушать все офферы
firebaseService.watchBoyOffers('RU').listen((offers) {
  //print('Offers: ${offers.length}');
});

// Слушать только видимые офферы
firebaseService.watchVisibleBoyOffers('RU').listen((offers) {
  //print('Visible offers: ${offers.length}');
});
```

##### VPN Offers (VPN офферы)

```dart
// Получить все VPN офферы
final allVpnOffers = await firebaseService.getVpnOffers();

// Получить только видимые VPN офферы
final visibleVpnOffers = await firebaseService.getVisibleVpnOffers();

// Слушать все VPN офферы
firebaseService.watchVpnOffers().listen((offers) {
  //print('VPN offers: ${offers.length}');
});

// Слушать только видимые VPN офферы
firebaseService.watchVisibleVpnOffers().listen((offers) {
  //print('Visible VPN offers: ${offers.length}');
});
```

##### Утилиты

```dart
// Проверить соединение с Firestore (простой метод)
final isConnected = await firebaseService.checkConnection();

// Получить детальный статус подключения
final status = await firebaseService.getConnectionStatus();
if (status.isConnected) {
  //print('Подключено, время ответа: ${status.responseTimeMs}ms');
} else {
  //print('Ошибка: ${status.errorMessage}');
}

// Быстрая проверка инициализации (синхронно, без async)
if (firebaseService.isInitialized) {
  //print('Firebase инициализирован');
}

// Полная диагностика - загрузить и вывести ВСЕ данные из Firestore
await firebaseService.runFullDiagnostics(regionCode: 'RU');
// Это выведет:
// - Статус подключения
// - Все настройки из settings
// - Все офферы из boy_offers_RU (с полными полями)
// - Все VPN офферы из vpn_offers (с полными полями)
```

## Логирование подключения

Сервис автоматически выводит подробные логи при инициализации и проверке подключения:

### При инициализации (main.dart)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Starting Firebase initialization...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📱 Step 1: Initializing Firebase Core...
✅ Firebase Core initialized successfully
🗄️  Step 2: Getting Firestore instance...
✅ Firestore instance obtained
🔌 Step 3: Testing Firestore connection...
   ✓ Successfully connected to Firestore
   ✓ Settings document EXISTS
   ✓ Document has 5 fields
   📄 Document content:
      • checkInternet: true
      • checkLocation: true
      • checkSIM: false
      • checkVPN: true
      • location: RU
   📋 Parsed settings:
=== Firebase Settings ===
checkInternet: true
checkLocation: true
checkSIM: false
checkVPN: true
location: RU
========================
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Firebase Firestore connection SUCCESSFUL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Теперь при инициализации ты видишь:**
- ✅ Сырые данные из документа (Document content)
- ✅ Распарсенные настройки (Parsed settings)

### При проверке подключения (checkConnection)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔌 Checking Firestore connection...
✅ Firestore connection SUCCESSFUL
   ✓ Response time: 245ms
   ✓ Settings document EXISTS
   ✓ Document has 5 fields
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### При ошибке подключения

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ Firebase initialization FAILED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Error type: FirebaseException
Error message: [firebase_core/no-app] No Firebase App...
Stack trace: ...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Получение детального статуса

```dart
final status = await FirebaseService().getConnectionStatus();
status.logStatus(); // Выводит:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Connection Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Initialized: ✅ YES
Connected: ✅ YES
Response time: 312 ms
Settings document exists: ✅ YES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Примеры использования

### 1. В StatefulWidget с FutureBuilder

```dart
class OffersScreen extends StatelessWidget {
  final String regionCode;
  
  const OffersScreen({required this.regionCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Офферы')),
      body: FutureBuilder<List<Offer>>(
        future: FirebaseService().getVisibleBoyOffers(regionCode),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }
          
          final offers = snapshot.data ?? [];
          
          if (offers.isEmpty) {
            return Center(child: Text('Нет офферов'));
          }
          
          return ListView.builder(
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              return Card(
                child: ListTile(
                  leading: offer.isSvgImage
                      ? SvgPicture.network(offer.image, width: 50, height: 50)
                      : Image.network(offer.image, width: 50, height: 50),
                  title: Text(offer.name),
                  subtitle: Text('⭐ ${offer.starsAsDouble}'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // Открыть WebView с offer.link
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WebViewScreen(url: offer.link),
                        ),
                      );
                    },
                    child: Text(offer.buttonText),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

### 2. В StatefulWidget со StreamBuilder

```dart
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Настройки')),
      body: StreamBuilder<FirebaseSettings?>(
        stream: FirebaseService().watchSettings(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }
          
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          
          final settings = snapshot.data!;
          
          return ListView(
            children: [
              SwitchListTile(
                title: Text('Проверка интернета'),
                value: settings.checkInternet,
                onChanged: null, // read-only
              ),
              SwitchListTile(
                title: Text('Проверка локации'),
                value: settings.checkLocation,
                onChanged: null,
              ),
              SwitchListTile(
                title: Text('Проверка SIM'),
                value: settings.checkSIM,
                onChanged: null,
              ),
              SwitchListTile(
                title: Text('Проверка VPN'),
                value: settings.checkVPN,
                onChanged: null,
              ),
              ListTile(
                title: Text('Локация'),
                subtitle: Text(settings.location),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

### 3. Карточка оффера с полями

```dart
class OfferCard extends StatelessWidget {
  final Offer offer;
  
  const OfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    final fields = offer.getFields();
    
    return Card(
      margin: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Изображение
          if (offer.isSvgImage)
            SvgPicture.network(offer.image, height: 100)
          else
            Image.network(offer.image, height: 100),
          
          // Название и рейтинг
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.name,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 20),
                    SizedBox(width: 4),
                    Text('${offer.starsAsDouble}'),
                  ],
                ),
              ],
            ),
          ),
          
          // Дополнительные поля
          if (fields.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: fields.map((field) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          field.name,
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          field.value,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          
          // Кнопка
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                // Открыть WebView с offer.link
              },
              child: Text(offer.buttonText),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

## Логирование

Все методы сервиса выводят подробную информацию в консоль:

```
Initializing Firebase...
Firebase initialized successfully
Fetching settings from Firestore...
Settings loaded successfully:
=== Firebase Settings ===
checkInternet: true
checkLocation: true
checkSIM: false
checkVPN: true
location: RU
========================

Fetching boy offers from collection: boy_offers_RU...
Found 5 boy offers
=== Offer ===
id: 1
isShow: true
link: https://example.com/offer1
image: https://example.com/logo1.png (SVG: false, PNG: true)
buttonText: Получить
name: Offer 1
stars: 4.5 (4.5)
Fields:
  1. Макс. сумма: 30000₽
  2. Время одобрения: 5 минут
=============
```

## Обработка ошибок

Сервис обрабатывает ошибки и возвращает безопасные значения:
- Методы `get*()` возвращают `null` или пустой список при ошибке
- Stream-методы `watch*()` отправляют ошибки в `onError` callback
- Все ошибки логируются в консоль

```dart
try {
  final settings = await firebaseService.getSettings();
  if (settings == null) {
    // Обработать отсутствие данных
  }
} catch (e) {
  //print('Error: $e');
}

// Для Stream
firebaseService.watchSettings().listen(
  (settings) {
    // Обработать данные
  },
  onError: (error) {
    //print('Stream error: $error');
  },
);
```

## Дополнительные возможности

### Поддержка SVG и PNG

Модель `Offer` автоматически определяет тип изображения:

```dart
if (offer.isSvgImage) {
  // Использовать flutter_svg
  SvgPicture.network(offer.image);
} else if (offer.isPngImage) {
  // Использовать стандартный Image
  Image.network(offer.image);
}
```

### Поддержка дробных рейтингов

```dart
// stars хранится как String для гибкости
final stars = offer.stars; // "4.5"

// Можно получить как double
final starsDouble = offer.starsAsDouble; // 4.5

// Для отображения звезд
Row(
  children: List.generate(5, (index) {
    if (index < starsDouble.floor()) {
      return Icon(Icons.star, color: Colors.amber);
    } else if (index < starsDouble) {
      return Icon(Icons.star_half, color: Colors.amber);
    } else {
      return Icon(Icons.star_border, color: Colors.amber);
    }
  }),
);
```

### Работа с регионами

```dart
// Получить офферы для разных регионов
final ruOffers = await firebaseService.getVisibleBoyOffers('RU');
final usOffers = await firebaseService.getVisibleBoyOffers('US');
final deOffers = await firebaseService.getVisibleBoyOffers('DE');

// Имя коллекции формируется автоматически:
// boy_offers_RU, boy_offers_US, boy_offers_DE
```

## Интеграция с другими сервисами

### С ViewModel (Provider)

```dart
class OffersViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  List<Offer> _offers = [];
  bool _loading = false;
  String? _error;
  
  List<Offer> get offers => _offers;
  bool get loading => _loading;
  String? get error => _error;
  
  Future<void> loadOffers(String regionCode) async {
    _loading = true;
    _error = null;
    notifyListeners();
    
    try {
      _offers = await _firebaseService.getVisibleBoyOffers(regionCode);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
  
  void watchOffers(String regionCode) {
    _firebaseService.watchVisibleBoyOffers(regionCode).listen(
      (offers) {
        _offers = offers;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }
}
```

## Зависимости

Убедитесь, что в `pubspec.yaml` присутствуют:

```yaml
dependencies:
  firebase_core: ^4.1.1
  cloud_firestore: ^6.0.0
  flutter_svg: ^2.0.10+1  # для SVG изображений
  cached_network_image: ^3.3.1  # для кеширования изображений
```

## Дополнительная информация

- Подробные примеры использования: `lib/services/firebase_service_example.dart`
- Конфигурация Firebase: `lib/firebase_options.dart`
- Инициализация в приложении: `lib/main.dart`

