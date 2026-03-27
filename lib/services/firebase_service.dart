import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import '../models/firebase_settings.dart';
import '../models/offer.dart';
import 'firebase_crashlytics_service.dart';

/// Сервис для работы с Firebase Firestore
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();
  final FirebaseCrashlyticsService _crashlyticsService =
  FirebaseCrashlyticsService();
  late final FirebaseFirestore _firestore;
  bool _initialized = false;
  bool _firestoreInitialized = false;
  Completer<void>? _initializationCompleter;
  FirebaseCrashlyticsService get crashlytics => _crashlyticsService;
  /// Инициализация Firebase
  Future<void> initialize() async {
    // Если инициализация уже запущена, возвращаем существующий Completer
    if (_initializationCompleter != null) {
      return _initializationCompleter!.future;
    }

    // Если уже инициализирован, создаём завершённый Completer
    if (_initialized) {
      print('⚠️  Firebase already initialized');
      _initializationCompleter = Completer<void>()..complete();
      return;
    }

    // Создаём новый Completer для синхронизации
    _initializationCompleter = Completer<void>();

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🚀 Starting Firebase initialization...');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      // ВАЖНО: Firebase Core должен быть инициализирован ДО Crashlytics,
      // иначе получим `No Firebase App '[DEFAULT]' has been created`.
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      // Инициализируем Crashlytics
      await _crashlyticsService.init();

      // НЕ инициализируем Firestore здесь - это будет сделано лениво
      // когда он реально понадобится (в AppModeService или LoansScreen)
      _initialized = true;
      print('✅ Firebase base initialization completed');
      print('   ℹ️  Firestore will be initialized lazily when needed');

      // Завершаем Completer успехом
      _initializationCompleter!.complete();
    } catch (e, stackTrace) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ Firebase initialization FAILED');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stackTrace');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      // Попытка записать ошибку в Crashlytics, если он уже инициализирован
      try {
        print("Попытка отправить репорт в крешлитикс.");
        await _crashlyticsService.recordError(e, stackTrace);
      } catch (_) {
        // Игнорируем ошибки при попытке записи в Crashlytics
      }

      // Завершаем Completer ошибкой
      _initializationCompleter!.completeError(e, stackTrace);
      rethrow;
    }
  }

  /// Проверка базовой инициализации
  void _ensureInitialized() {
    if (!_initialized) {
      throw Exception(
        'FirebaseService not initialized. Call initialize() first.',
      );
    }
  }

  /// Ленивая инициализация Firestore (вызывается только когда нужен)
  Future<void> _ensureFirestoreInitialized() async {
    if (_firestoreInitialized) {
      return;
    }

    // Ждём завершения базовой инициализации через Completer
    if (_initializationCompleter != null) {
      try {
        await _initializationCompleter!.future;
      } catch (e) {
        // Если базовая инициализация упала, пробуем инициализировать сами
        print('⚠️  Base initialization failed, trying to initialize...');
        try {
          await initialize();
        } catch (initError) {
          // Если повторная инициализация тоже упала, всё равно пробуем получить Firestore
          // так как Firebase Core уже инициализирован в main()
          print('⚠️  Retry initialization failed, but Firebase Core is ready, continuing...');
        }
      }
    } else {
      // Если инициализация ещё не запущена, запускаем сами
      await initialize();
    }

    // Firebase Core уже инициализирован в main() через Firebase.initializeApp()
    // поэтому FirebaseFirestore.instance безопасен
    print('🗄️  Lazy initialization: Getting Firestore instance...');
    _firestore = FirebaseFirestore.instance;
    _firestoreInitialized = true;
    print('✅ Firestore instance obtained (lazy init)');
  }

  // ========== SETTINGS ==========

  /// Получение настроек из коллекции settings, документ general
  Future<FirebaseSettings?> getSettings() async {
    await _ensureFirestoreInitialized();

    try {
      print('Fetching settings from Firestore...');
      // Увеличено время ожидания для медленного интернета (2G)
      final doc = await _firestore
          .collection('settings')
          .doc('general')
          .get()
          .timeout(const Duration(seconds: 30));

      if (!doc.exists) {
        print('Settings document does not exist');
        return null;
      }

      final data = doc.data();
      if (data == null) {
        print('Settings document has no data');
        return null;
      }

      final settings = FirebaseSettings.fromFirestore(data);
      print('Settings loaded successfully:');
      settings.logData();

      return settings;
    } catch (e) {
      print('Error fetching settings: $e');
      return null;
    }
  }

  /// Слушать изменения настроек в реальном времени
  Stream<FirebaseSettings?> watchSettings() {
    // Инициализируем Firestore асинхронно перед возвратом Stream
    return Stream.fromFuture(_ensureFirestoreInitialized()).asyncExpand((_) {
      return _firestore.collection('settings').doc('general').snapshots().map((
        snapshot,
      ) {
        if (!snapshot.exists || snapshot.data() == null) {
          print('Settings document does not exist or has no data');
          return null;
        }

        final settings = FirebaseSettings.fromFirestore(snapshot.data()!);
        print('Settings updated:');
        settings.logData();

        return settings;
      });
    });
  }

  // ========== BOY OFFERS ==========

  /// Получение офферов для региона из коллекции boy_offers_[regionCode]
  /// Сортировка по полю id по возрастанию
  Future<List<Offer>> getBoyOffers(String regionCode) async {
    await _ensureFirestoreInitialized();

    try {
      final collectionName = 'boy_offers_$regionCode';
      print('Fetching boy offers from collection: $collectionName...');

      final querySnapshot = await _firestore
          .collection(collectionName)
          .orderBy('id', descending: false)
          .get();

      print('Found ${querySnapshot.docs.length} boy offers');

      final offers = <Offer>[];
      for (var doc in querySnapshot.docs) {
        final offer = Offer.fromFirestore(doc.data(), doc.id);
        offer.logData();
        offers.add(offer);
      }

      return offers;
    } catch (e) {
      print('Error fetching boy offers: $e');
      return [];
    }
  }

  /// Получение только видимых офферов для региона (is_show = true)
  Future<List<Offer>> getVisibleBoyOffers(String regionCode) async {
    await _ensureFirestoreInitialized();

    try {
      final collectionName = 'boy_offers_$regionCode';
/*      print(
        'Fetching all boy offers from collection: $collectionName (will filter on client)...',
      );*/

      // Загружаем все офферы без фильтрации и сортировки
      // Увеличено время ожидания для медленного интернета (2G)
      final querySnapshot = await _firestore
          .collection(collectionName)
          .get()
          .timeout(const Duration(seconds: 30));

      print('Found ${querySnapshot.docs.length} total boy offers');

      final offers = <Offer>[];
      for (var doc in querySnapshot.docs) {
        final offer = Offer.fromFirestore(doc.data(), doc.id);
        offer.logData();
        offers.add(offer);
      }

      // Фильтруем и сортируем на клиенте
      final visibleOffers = offers.where((offer) => offer.isShow).toList()
        ..sort((a, b) => a.id.compareTo(b.id));

      print('Found ${visibleOffers.length} visible boy offers after filtering');

      return visibleOffers;
    } catch (e) {
      print('Error fetching boy offers: $e');
      return [];
    }
  }

  /// Слушать изменения офферов для региона в реальном времени
  Stream<List<Offer>> watchBoyOffers(String regionCode) {
    return Stream.fromFuture(_ensureFirestoreInitialized()).asyncExpand((_) {
      final collectionName = 'boy_offers_$regionCode';
      print('Watching boy offers from collection: $collectionName');

      return _firestore
          .collection(collectionName)
          .orderBy('id', descending: false)
          .snapshots()
          .map((snapshot) {
            print('Boy offers updated: ${snapshot.docs.length} offers');

            final offers = <Offer>[];
            for (var doc in snapshot.docs) {
              final offer = Offer.fromFirestore(doc.data(), doc.id);
              offer.logData();
              offers.add(offer);
            }

            return offers;
          });
    });
  }

  /// Слушать изменения только видимых офферов для региона
  Stream<List<Offer>> watchVisibleBoyOffers(String regionCode) {
    return Stream.fromFuture(_ensureFirestoreInitialized()).asyncExpand((_) {
      final collectionName = 'boy_offers_$regionCode';
      print('Watching visible boy offers from collection: $collectionName');

      return _firestore
          .collection(collectionName)
          .where('is_show', isEqualTo: true)
          .orderBy('id', descending: false)
          .snapshots()
          .map((snapshot) {
            print('Visible boy offers updated: ${snapshot.docs.length} offers');

            final offers = <Offer>[];
            for (var doc in snapshot.docs) {
              final offer = Offer.fromFirestore(doc.data(), doc.id);
              offer.logData();
              offers.add(offer);
            }

            return offers;
          });
    });
  }

  // ========== VPN OFFERS ==========

  /// Получение VPN офферов из коллекции vpn_offers
  /// Сортировка по полю id по возрастанию
  Future<List<Offer>> getVpnOffers() async {
    await _ensureFirestoreInitialized();

    try {
      print('Fetching VPN offers...');

      final querySnapshot = await _firestore
          .collection('vpn_offers')
          .orderBy('id', descending: false)
          .get();

      print('Found ${querySnapshot.docs.length} VPN offers');

      final offers = <Offer>[];
      for (var doc in querySnapshot.docs) {
        final offer = Offer.fromFirestore(doc.data(), doc.id);
        offer.logData();
        offers.add(offer);
      }

      return offers;
    } catch (e) {
      print('Error fetching VPN offers: $e');
      return [];
    }
  }

  /// Получение только видимых VPN офферов (is_show = true)
  Future<List<Offer>> getVisibleVpnOffers() async {
    await _ensureFirestoreInitialized();

    try {
      print('Fetching all VPN offers (will filter on client)...');

      // Загружаем все офферы без фильтрации и сортировки
      final querySnapshot = await _firestore.collection('vpn_offers').get();

      print('Found ${querySnapshot.docs.length} total VPN offers');

      final offers = <Offer>[];
      for (var doc in querySnapshot.docs) {
        final offer = Offer.fromFirestore(doc.data(), doc.id);
        offer.logData();
        offers.add(offer);
      }

      // Фильтруем и сортируем на клиенте
      final visibleOffers = offers.where((offer) => offer.isShow).toList()
        ..sort((a, b) => a.id.compareTo(b.id));

      print('Found ${visibleOffers.length} visible VPN offers after filtering');

      return visibleOffers;
    } catch (e) {
      print('Error fetching VPN offers: $e');
      return [];
    }
  }

  /// Слушать изменения VPN офферов в реальном времени
  Stream<List<Offer>> watchVpnOffers() {
    return Stream.fromFuture(_ensureFirestoreInitialized()).asyncExpand((_) {
      print('Watching VPN offers');

      return _firestore
          .collection('vpn_offers')
          .orderBy('id', descending: false)
          .snapshots()
          .map((snapshot) {
            print('VPN offers updated: ${snapshot.docs.length} offers');

            final offers = <Offer>[];
            for (var doc in snapshot.docs) {
              final offer = Offer.fromFirestore(doc.data(), doc.id);
              offer.logData();
              offers.add(offer);
            }

            return offers;
          });
    });
  }

  /// Слушать изменения только видимых VPN офферов
  Stream<List<Offer>> watchVisibleVpnOffers() {
    return Stream.fromFuture(_ensureFirestoreInitialized()).asyncExpand((_) {
      print('Watching visible VPN offers');

      return _firestore
          .collection('vpn_offers')
          .where('is_show', isEqualTo: true)
          .orderBy('id', descending: false)
          .snapshots()
          .map((snapshot) {
            print('Visible VPN offers updated: ${snapshot.docs.length} offers');

            final offers = <Offer>[];
            for (var doc in snapshot.docs) {
              final offer = Offer.fromFirestore(doc.data(), doc.id);
              offer.logData();
              offers.add(offer);
            }

            return offers;
          });
    });
  }

  // ========== UTILITY METHODS ==========

  /// Проверка доступности Firestore
  Future<bool> checkConnection() async {
    await _ensureFirestoreInitialized();

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔌 Checking Firestore connection...');

    try {
      final startTime = DateTime.now();

      // Увеличено время ожидания для медленного интернета (2G)
      final doc = await _firestore
          .collection('settings')
          .doc('general')
          .get()
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Connection timeout after 30 seconds');
            },
          );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;

      print('✅ Firestore connection SUCCESSFUL');
      print('   ✓ Response time: ${duration}ms');
      print('   ✓ Settings document ${doc.exists ? "EXISTS" : "NOT FOUND"}');
      if (doc.exists && doc.data() != null) {
        print('   ✓ Document has ${doc.data()!.length} fields');
      }
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return true;
    } catch (e) {
      print('❌ Firestore connection FAILED');
      print('   ✗ Error type: ${e.runtimeType}');
      print('   ✗ Error message: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return false;
    }
  }

  /// Получение всех доступных коллекций boy_offers
  Future<List<String>> getBoyOffersCollections() async {
    _ensureInitialized();

    try {
      print('Fetching all boy offers collections...');
      // Firestore не позволяет получить список всех коллекций на клиенте
      // Нужно использовать Admin SDK на сервере или хранить список коллекций
      // в отдельном документе
      print('Note: Cannot list collections from client SDK');
      return [];
    } catch (e) {
      print('Error fetching boy offers collections: $e');
      return [];
    }
  }

  /// Получить детальную информацию о статусе подключения
  Future<ConnectionStatus> getConnectionStatus() async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📊 Getting connection status...');

    if (!_initialized) {
      print('❌ Firebase not initialized');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return ConnectionStatus(
        isInitialized: false,
        isConnected: false,
        errorMessage: 'Firebase not initialized',
      );
    }

    try {
      await _ensureFirestoreInitialized();

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

      print('✅ Connection status: CONNECTED');
      print('   ✓ Initialized: YES');
      print('   ✓ Response time: ${responseTime}ms');
      print('   ✓ Document exists: ${doc.exists}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      return ConnectionStatus(
        isInitialized: true,
        isConnected: true,
        responseTimeMs: responseTime,
        documentExists: doc.exists,
      );
    } catch (e) {
      print('❌ Connection status: DISCONNECTED');
      print('   ✗ Error: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

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
    await _ensureFirestoreInitialized();

    print('');
    print('═══════════════════════════════════════════════════════════');
    print('🔍 FIREBASE FIRESTORE - FULL DIAGNOSTICS');
    print('═══════════════════════════════════════════════════════════');
    print('');

    // 1. Проверка подключения
    print('━━━ 1. CONNECTION CHECK ━━━');
    final connectionStatus = await getConnectionStatus();
    connectionStatus.logStatus();

    if (!connectionStatus.isConnected) {
      print('❌ Cannot continue diagnostics - not connected');
      print('═══════════════════════════════════════════════════════════');
      return;
    }

    print('');

    // 2. Загрузка Settings
    print('━━━ 2. SETTINGS COLLECTION ━━━');
    try {
      final settings = await getSettings();
      if (settings != null) {
        print('✅ Settings loaded successfully');
        settings.logData();
      } else {
        print('⚠️  Settings not found');
      }
    } catch (e) {
      print('❌ Error loading settings: $e');
    }

    print('');

    // 3. Загрузка Boy Offers
    print('━━━ 3. BOY OFFERS (region: $regionCode) ━━━');
    try {
      final boyOffers = await getBoyOffers(regionCode);
      print('✅ Total boy offers: ${boyOffers.length}');

      if (boyOffers.isNotEmpty) {
        print('');
        print('📋 All boy offers:');
        for (var i = 0; i < boyOffers.length; i++) {
          print('');
          print('--- Offer ${i + 1}/${boyOffers.length} ---');
          boyOffers[i].logData();
        }
      } else {
        print('⚠️  No boy offers found for region $regionCode');
      }
    } catch (e) {
      print('❌ Error loading boy offers: $e');
    }

    print('');

    // 4. Загрузка VPN Offers
    print('━━━ 4. VPN OFFERS ━━━');
    try {
      final vpnOffers = await getVpnOffers();
      print('✅ Total VPN offers: ${vpnOffers.length}');

      if (vpnOffers.isNotEmpty) {
        print('');
        print('📋 All VPN offers:');
        for (var i = 0; i < vpnOffers.length; i++) {
          print('');
          print('--- VPN Offer ${i + 1}/${vpnOffers.length} ---');
          vpnOffers[i].logData();
        }
      } else {
        print('⚠️  No VPN offers found');
      }
    } catch (e) {
      print('❌ Error loading VPN offers: $e');
    }

    print('');
    print('═══════════════════════════════════════════════════════════');
    print('✅ DIAGNOSTICS COMPLETE');
    print('═══════════════════════════════════════════════════════════');
    print('');
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
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📊 Connection Status');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('Initialized: ${isInitialized ? "✅ YES" : "❌ NO"}');
    print('Connected: ${isConnected ? "✅ YES" : "❌ NO"}');
    if (responseTimeMs != null) {
      print('Response time: $responseTimeMs ms');
    }
    if (documentExists != null) {
      print('Settings document exists: ${documentExists! ? "✅ YES" : "❌ NO"}');
    }
    if (errorMessage != null) {
      print('Error: $errorMessage');
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  @override
  String toString() {
    return 'ConnectionStatus(initialized: $isInitialized, connected: $isConnected, responseTime: $responseTimeMs ms, error: $errorMessage)';
  }
}
