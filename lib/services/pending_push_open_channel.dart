import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Результат открытия push, сохранённого native до готовности Dart.
class PendingPushOpen {
  const PendingPushOpen({this.payload});

  final String? payload;
}

/// Native-буфер для tap по push до готовности Dart (cold start).
class PendingPushOpenChannel {
  PendingPushOpenChannel._();

  static const MethodChannel _channel = MethodChannel(
    'com.kredit7.dney/pending_push_open',
  );

  static Future<PendingPushOpen?> consumeLaunchPush() async {
    try {
      final result = await _channel.invokeMethod<Object?>(
        'consumePendingPushOpen',
      );
      if (result is! Map) return null;
      if (result['opened'] != true) return null;

      final payload = result['payload'];
      if (payload is String && payload.trim().isNotEmpty) {
        return PendingPushOpen(payload: payload.trim());
      }
      return const PendingPushOpen();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PendingPushOpenChannel: consume error: $e');
      }
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      await _channel.invokeMethod<void>('clearPendingPushOpen');
    } catch (_) {}
  }
}
