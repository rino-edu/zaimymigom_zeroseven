import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import '../models/firebase_settings.dart';
import '../models/offer.dart';

/// Сервис для работы с Firebase Firestore
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  late final FirebaseFirestore _firestore;
  bool _initialized = false;

  /// Инициализация Firebase
  Future<void> initialize() async {
    if (_initialized) {
      //print('⚠️  Firebase already initialized');
      return;
    }

    //print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    //print('🚀 Starting Firebase initialization...');
    //print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      // Шаг 1: Инициализация Firebase Core
      //print('📱 Step 1: Initializing Firebase Core...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      //print('✅ Firebase Core initialized successfully');

      // Шаг 2: Получение инстанса Firestore
      //print('🗄️  Step 2: Getting Firestore instance...');
      _firestore = FirebaseFirestore.instance;
      _initialized = true;
      //print('✅ Firestore instance obtained');

      // Шаг 3: Проверка реального подключения к Firestore
      //print('🔌 Step 3: Testing Firestore connection...');
      final connectionSuccessful = await _testFirestoreConnection();

      if (connectionSuccessful) {
        //print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        //print('✅ Firebase Firestore connection SUCCESSFUL');
        //print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      } else {
        //print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        //print('⚠️  Firebase initialized but Firestore connection FAILED');
        //print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
    } catch (e, stackTrace) {
      //print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      //print('❌ Firebase initialization FAILED');
      //print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      //print('Error type: ${e.runtimeType}');
      //print('Error message: $e');
      //print('Stack trace: $stackTrace');
      //print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  /// Тестирование реального подключения к Firestore
  Future<bool> _testFirestoreConnection() async {
    try {
      // Пытаемся получить доступ к коллекции settings
      final doc = await _firestore
          .collection('settings')
          .doc('general')
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Connection timeout after 10 seconds');
            },
          );

      //print('   ✓ Successfully connected to Firestore');
      //print('   ✓ Settings document ${doc.exists ? "EXISTS" : "NOT FOUND"}');

      // Если документ существует, выводим его содержимое
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        //print('   ✓ Document has ${data.length} fields');
        //print('   📄 Document content:');
        data.forEach((key, value) {
          //print('      • $key: $value');
        });

        // Создаем объект настроек и выводим через logData()
        final settings = FirebaseSettings.fromFirestore(data);
        //print('   📋 Parsed settings:');
        settings.logData();
      } else {
        //print('   ⚠️  Settings document is empty or does not exist');
      }

      return true;
    } catch (e) {
      //print('   ✗ Firestore connection test failed: $e');
      return false;
    }
  }

  /// Проверка инициализации
  void _ensureInitialized() {
    if (!_initialized) {
      throw Exception(
        'FirebaseService not initialized. Call initialize() first.',
      );
    }
  }

  // ========== SETTINGS ==========

  /// Получение настроек из коллекции settings, документ general
  Future<FirebaseSettings?> getSettings() async {
    _ensureInitialized();

    try {
      //print('Fetching settings from Firestore...');
      final doc = await _firestore.collection('settings').doc('general').get();

      if (!doc.exists) {
        //print('Settings document does not exist');
        return null;
      }

      final data = doc.data();
      if (data == null) {
        //print('Settings document has no data');
        return null;
      }

      final settings = FirebaseSettings.fromFirestore(data);
      //print('Settings loaded successfully:');
      settings.logData();

      return settings;
    } catch (e) {
      //print('Error fetching settings: $e');
      return null;
    }
  }

  /// Слушать изменения настроек в реальном времени
  Stream<FirebaseSettings?> watchSettings() {
    _ensureInitialized();

    return _firestore.collection('settings').doc('general').snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists || snapshot.data() == null) {
        //print('Settings document does not exist or has no data');
        return null;
      }

      final settings = FirebaseSettings.fromFirestore(snapshot.data()!);
      //print('Settings updated:');
      settings.logData();

      return settings;
    });
  }

  // ========== BOY OFFERS ==========

  /// Получение офферов для региона из коллекции boy_offers_[regionCode]
  /// Сортировка по полю id по возрастанию
  Future<List<Offer>> getBoyOffers(String regionCode) async {
    _ensureInitialized();

    try {
      final collectionName = 'boy_offers_$regionCode';
      //print('Fetching boy offers from collection: $collectionName...');

      final querySnapshot = await _firestore
          .collection(collectionName)
          .orderBy('id', descending: false)
          .get();

      //print('Found ${querySnapshot.docs.length} boy offers');

      final offers = <Offer>[];
      for (var doc in querySnapshot.docs) {
        final offer = Offer.fromFirestore(doc.data(), doc.id);
        offer.logData();
        offers.add(offer);
      }

      return offers;
    } catch (e) {
      //print('Error fetching boy offers: $e');
      return [];
    }
  }

  /// Получение только видимых офферов для региона (is_show = true)
  Future<List<Offer>> getVisibleBoyOffers(String regionCode) async {
    _ensureInitialized();

    try {
      final collectionName = 'boy_offers_$regionCode';
/*      //print(
        'Fetching all boy offers from collection: $collectionName (will filter on client)...',
      );*/

      // Загружаем все офферы без фильтрации и сортировки
      final querySnapshot = await _firestore.collection(collectionName).get();

      //print('Found ${querySnapshot.docs.length} total boy offers');

      final offers = <Offer>[];
      for (var doc in querySnapshot.docs) {
        final offer = Offer.fromFirestore(doc.data(), doc.id);
        offer.logData();
        offers.add(offer);
      }

      // Фильтруем и сортируем на клиенте
      final visibleOffers = offers.where((offer) => offer.isShow).toList()
        ..sort((a, b) => a.id.compareTo(b.id));

      //print('Found ${visibleOffers.length} visible boy offers after filtering');

      return visibleOffers;
    } catch (e) {
      //print('Error fetching boy offers: $e');
      return [];
    }
  }

  /// Слушать изменения офферов для региона в реальном времени
  Stream<List<Offer>> watchBoyOffers(String regionCode) {
    _ensureInitialized();

    final collectionName = 'boy_offers_$regionCode';
    //print('Watching boy offers from collection: $collectionName');

    return _firestore
        .collection(collectionName)
        .orderBy('id', descending: false)
        .snapshots()
        .map((snapshot) {
          //print('Boy offers updated: ${snapshot.docs.length} offers');

          final offers = <Offer>[];
          for (var doc in snapshot.docs) {
            final offer = Offer.fromFirestore(doc.data(), doc.id);
            offer.logData();
            offers.add(offer);
          }

          return offers;
        });
  }

  /// Слушать изменения только видимых офферов для региона
  Stream<List<Offer>> watchVisibleBoyOffers(String regionCode) {
    _ensureInitialized();

    final collectionName = 'boy_offers_$regionCode';
    //print('Watching visible boy offers from collection: $collectionName');

    return _firestore
        .collection(collectionName)
        .where('is_show', isEqualTo: true)
        .orderBy('id', descending: false)
        .snapshots()
        .map((snapshot) {
          //print('Visible boy offers updated: ${snapshot.docs.length} offers');

          final offers = <Offer>[];
          for (var doc in snapshot.docs) {
            final offer = Offer.fromFirestore(doc.data(), doc.id);
            offer.logData();
            offers.add(offer);
          }

          return offers;
        });
  }

  // ========== VPN OFFERS ==========

  /// Получение VPN офферов из коллекции vpn_offers
  /// Сортировка по полю id по возрастанию
  Future<List<Offer>> getVpnOffers() async {
    _ensureInitialized();

    try {
      //print('Fetching VPN offers...');

      final querySnapshot = await _firestore
          .collection('vpn_offers')
          .orderBy('id', descending: false)
          .get();

      //print('Found ${querySnapshot.docs.length} VPN offers');

      final offers = <Offer>[];
      for (var doc in querySnapshot.docs) {
        final offer = Offer.fromFirestore(doc.data(), doc.id);
        offer.logData();
        offers.add(offer);
      }

      return offers;
    } catch (e) {
      //print('Error fetching VPN offers: $e');
      return [];
    }
  }

  /// Получение только видимых VPN офферов (is_show = true)
  Future<List<Offer>> getVisibleVpnOffers() async {
    _ensureInitialized();

    try {
      //print('Fetching all VPN offers (will filter on client)...');

      // Загружаем все офферы без фильтрации и сортировки
      final querySnapshot = await _firestore.collection('vpn_offers').get();

      //print('Found ${querySnapshot.docs.length} total VPN offers');

      final offers = <Offer>[];
      for (var doc in querySnapshot.docs) {
        final offer = Offer.fromFirestore(doc.data(), doc.id);
        offer.logData();
        offers.add(offer);
      }

      // Фильтруем и сортируем на клиенте
      final visibleOffers = offers.where((offer) => offer.isShow).toList()
        ..sort((a, b) => a.id.compareTo(b.id));

      //print('Found ${visibleOffers.length} visible VPN offers after filtering');

      return visibleOffers;
    } catch (e) {
      //print('Error fetching VPN offers: $e');
      return [];
    }
  }

  /// Слушать изменения VPN офферов в реальном времени
  Stream<List<Offer>> watchVpnOffers() {
    _ensureInitialized();

    //print('Watching VPN offers');

    return _firestore
        .collection('vpn_offers')
        .orderBy('id', descending: false)
        .snapshots()
        .map((snapshot) {
          //print('VPN offers updated: ${snapshot.docs.length} offers');

          final offers = <Offer>[];
          for (var doc in snapshot.docs) {
            final offer = Offer.fromFirestore(doc.data(), doc.id);
            offer.logData();
            offers.add(offer);
          }

          return offers;
        });
  }

  /// Слушать изменения только видимых VPN офферов
  Stream<List<Offer>> watchVisibleVpnOffers() {
    _ensureInitialized();

    //print('Watching visible VPN offers');

    return _firestore
        .collection('vpn_offers')
        .where('is_show', isEqualTo: true)
        .orderBy('id', descending: false)
        .snapshots()
        .map((snapshot) {
          //print('Visible VPN offers updated: ${snapshot.docs.length} offers');

          final offers = <Offer>[];
          for (var doc in snapshot.docs) {
            final offer = Offer.fromFirestore(doc.data(), doc.id);
            offer.logData();
            offers.add(offer);
          }

          return offers;
        });
  }

  // ========== UTILITY METHODS ==========

  /// Проверка доступности Firestore
  Future<bool> checkConnection() async {
    _ensureInitialized();

    //print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    //print('🔌 Checking Firestore connection...');

    try {
      final startTime = DateTime.now();

      final doc = await _firestore
          .collection('settings')
          .doc('general')
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Connection timeout after 10 seconds');
            },
          );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;

      //print('✅ Firestore connection SUCCESSFUL');
      //print('   ✓ Response time: ${duration}ms');
      //print('   ✓ Settings document ${doc.exists ? "EXISTS" : "NOT FOUND"}');
      if (doc.exists && doc.data() != null) {
        //print('   ✓ Document has ${doc.data()!.length} fields');
      }
      //print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return true;
    } catch (e) {
      //print('❌ Firestore connection FAILED');
      //print('   ✗ Error type: ${e.runtimeType}');
      //print('   ✗ Error message: $e');
      //print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return false;
    }
  }

  /// Получение всех доступных коллекций boy_offers
  Future<List<String>> getBoyOffersCollections() async {
    _ensureInitialized();

    try {
      //print('Fetching all boy offers collections...');
      // Firestore не позволяет получить список всех коллекций на клиенте
      // Нужно использовать Admin SDK на сервере или хранить список коллекций
      // в отдельном документе
      //print('Note: Cannot list collections from client SDK');
      return [];
    } catch (e) {
      //print('Error fetching boy offers collections: $e');
      return [];
    }
  }

  /// Получить детальную информацию о статусе подключения
  Future<ConnectionStatus> getConnectionStatus() async {
    //print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    //print('📊 Getting connection status...');

    if (!_initialized) {
      //print('❌ Firebase not initialized');
      //print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return ConnectionStatus(
        isInitialized: false,
        isConnected: false,
        errorMessage: 'Firebase not initialized',
      );
    }

    try {
      final startTime = DateTime.now();

      final doc = await _firestore
          .collection('settings')
          .doc('general')
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Connection timeout');
            },
          );

      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime).inMilliseconds;

      //print('✅ Connection status: CONNECTED');
      //print('   ✓ Initialized: YES');
      //print('   ✓ Response time: ${responseTime}ms');
      //print('   ✓ Document exists: ${doc.exists}');
      //print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      return ConnectionStatus(
        isInitialized: true,
        isConnected: true,
        responseTimeMs: responseTime,
        documentExists: doc.exists,
      );
    } catch (e) {
      //print('❌ Connection status: DISCONNECTED');
      //print('   ✗ Error: $e');
      //print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      return ConnectionStatus(
        isInitialized: true,
        isConnected: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Получить информацию об инициализации (синхронный метод)
  bool get isInitialized => _initialized;

  /// Полная диагностика - загружает и выводит все данные из Firestore
  Future<void> runFullDiagnostics({String regionCode = 'RU'}) async {
    _ensureInitialized();

    //print('');
    //print('═══════════════════════════════════════════════════════════');
    //print('🔍 FIREBASE FIRESTORE - FULL DIAGNOSTICS');
    //print('═══════════════════════════════════════════════════════════');
    //print('');

    // 1. Проверка подключения
    //print('━━━ 1. CONNECTION CHECK ━━━');
    final connectionStatus = await getConnectionStatus();
    connectionStatus.logStatus();

    if (!connectionStatus.isConnected) {
      //print('❌ Cannot continue diagnostics - not connected');
      //print('═══════════════════════════════════════════════════════════');
      return;
    }

    //print('');

    // 2. Загрузка Settings
    //print('━━━ 2. SETTINGS COLLECTION ━━━');
    try {
      final settings = await getSettings();
      if (settings != null) {
        //print('✅ Settings loaded successfully');
        settings.logData();
      } else {
        //print('⚠️  Settings not found');
      }
    } catch (e) {
      //print('❌ Error loading settings: $e');
    }

    //print('');

    // 3. Загрузка Boy Offers
    //print('━━━ 3. BOY OFFERS (region: $regionCode) ━━━');
    try {
      final boyOffers = await getBoyOffers(regionCode);
      //print('✅ Total boy offers: ${boyOffers.length}');

      if (boyOffers.isNotEmpty) {
        //print('');
        //print('📋 All boy offers:');
        for (var i = 0; i < boyOffers.length; i++) {
          //print('');
          //print('--- Offer ${i + 1}/${boyOffers.length} ---');
          boyOffers[i].logData();
        }
      } else {
        //print('⚠️  No boy offers found for region $regionCode');
      }
    } catch (e) {
      //print('❌ Error loading boy offers: $e');
    }

    //print('');

    // 4. Загрузка VPN Offers
    //print('━━━ 4. VPN OFFERS ━━━');
    try {
      final vpnOffers = await getVpnOffers();
      //print('✅ Total VPN offers: ${vpnOffers.length}');

      if (vpnOffers.isNotEmpty) {
        //print('');
        //print('📋 All VPN offers:');
        for (var i = 0; i < vpnOffers.length; i++) {
          //print('');
          //print('--- VPN Offer ${i + 1}/${vpnOffers.length} ---');
          vpnOffers[i].logData();
        }
      } else {
        //print('⚠️  No VPN offers found');
      }
    } catch (e) {
      //print('❌ Error loading VPN offers: $e');
    }

    //print('');
    //print('═══════════════════════════════════════════════════════════');
    //print('✅ DIAGNOSTICS COMPLETE');
    //print('═══════════════════════════════════════════════════════════');
    //print('');
  }
}

/// Класс для хранения информации о статусе подключения
class ConnectionStatus {
  final bool isInitialized;
  final bool isConnected;
  final int? responseTimeMs;
  final bool? documentExists;
  final String? errorMessage;

  ConnectionStatus({
    required this.isInitialized,
    required this.isConnected,
    this.responseTimeMs,
    this.documentExists,
    this.errorMessage,
  });

  /// Логирование статуса подключения
  void logStatus() {
    //print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    //print('📊 Connection Status');
    //print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    //print('Initialized: ${isInitialized ? "✅ YES" : "❌ NO"}');
    //print('Connected: ${isConnected ? "✅ YES" : "❌ NO"}');
    if (responseTimeMs != null) {
      //print('Response time: $responseTimeMs ms');
    }
    if (documentExists != null) {
      //print('Settings document exists: ${documentExists! ? "✅ YES" : "❌ NO"}');
    }
    if (errorMessage != null) {
      //print('Error: $errorMessage');
    }
    //print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  @override
  String toString() {
    return 'ConnectionStatus(initialized: $isInitialized, connected: $isConnected, responseTime: $responseTimeMs ms, error: $errorMessage)';
  }
}
