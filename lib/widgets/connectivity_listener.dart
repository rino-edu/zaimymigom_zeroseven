import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Виджет-обертка, который слушает изменения подключения к интернету
/// и показывает попап при потере соединения.
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
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();

    _subscription = Connectivity()
        .onConnectivityChanged
        .listen(_handleConnectivityChange);
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    // Берём последний результат из списка (актуальное состояние)
    final latest = results.isNotEmpty ? results.last : ConnectivityResult.none;
    final isOffline = latest == ConnectivityResult.none;
    if (!isOffline) {
      // Как только интернет появился — просто сбрасываем флаг,
      // чтобы при следующей потере снова показать попап
      _isDialogOpen = false;
      return;
    }

    if (_isDialogOpen || !mounted) return;

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
      // Когда диалог закрыли вручную — разрешаем повторный показ
      _isDialogOpen = false;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}


