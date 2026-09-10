import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Виджет-обертка, который слушает изменения подключения к интернету
/// и показывает попап при потере соединения.
///
/// На iOS Simulator / при hot restart `onConnectivityChanged` часто кратко
/// отдаёт `none`, хотя сеть есть — поэтому перед показом диалога ждём
/// debounce и перепроверяем статус.
class ConnectivityListener extends StatefulWidget {
  final Widget child;

  const ConnectivityListener({
    super.key,
    required this.child,
  });

  @override
  State<ConnectivityListener> createState() => _ConnectivityListenerState();
}

class _ConnectivityListenerState extends State<ConnectivityListener> {
  static const _offlineConfirmDelay = Duration(milliseconds: 1500);

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _offlineConfirmTimer;
  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();

    _subscription = Connectivity()
        .onConnectivityChanged
        .listen(_handleConnectivityChange);
  }

  bool _isOffline(List<ConnectivityResult> results) {
    return results.isEmpty ||
        results.every((result) => result == ConnectivityResult.none);
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    if (!_isOffline(results)) {
      _offlineConfirmTimer?.cancel();
      _offlineConfirmTimer = null;
      // Сеть вернулась — разрешаем показать попап при следующей реальной потере
      _isDialogOpen = false;
      return;
    }

    if (_isDialogOpen || !mounted) return;

    // Краткий none при старте/hot restart не должен сразу показывать диалог
    _offlineConfirmTimer?.cancel();
    _offlineConfirmTimer = Timer(_offlineConfirmDelay, _confirmOfflineAndShowDialog);
  }

  Future<void> _confirmOfflineAndShowDialog() async {
    if (!mounted || _isDialogOpen) return;

    final current = await Connectivity().checkConnectivity();
    if (!_isOffline(current) || !mounted || _isDialogOpen) return;

    _isDialogOpen = true;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('connection.lost_title'.tr()),
          content: Text('connection.lost_message'.tr()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: Text('connection.lost_ok'.tr()),
            ),
          ],
        );
      },
    ).then((_) {
      _isDialogOpen = false;
    });
  }

  @override
  void dispose() {
    _offlineConfirmTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
