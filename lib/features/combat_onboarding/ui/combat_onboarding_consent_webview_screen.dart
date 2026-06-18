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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _isLoading = false);
          },
          onWebResourceError: (_) {
            if (!mounted) return;
            setState(() => _isLoading = false);
          },
        ),
      )
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
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
