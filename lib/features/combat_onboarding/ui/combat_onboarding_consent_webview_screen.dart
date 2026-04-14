import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CombatOnboardingConsentWebViewScreen extends StatefulWidget {
  final String url;

  const CombatOnboardingConsentWebViewScreen({super.key, required this.url});

  @override
  State<CombatOnboardingConsentWebViewScreen> createState() =>
      _CombatOnboardingConsentWebViewScreenState();
}

class _CombatOnboardingConsentWebViewScreenState
    extends State<CombatOnboardingConsentWebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Политика конфиденциальности'),
        centerTitle: true,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

