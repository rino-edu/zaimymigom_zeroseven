import 'package:flutter/foundation.dart';
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
  static const String _logTag = 'WebViewDebug';

  void _logCurrentUrl(String source, String url) {
    if (url.isEmpty) return;
    debugPrint('[$_logTag][$source] $url');
  }

  @override
  void initState() {
    super.initState();
    _logCurrentUrl('initial', widget.url);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            _logCurrentUrl('navigation', request.url);
            return NavigationDecision.navigate;
          },
          onUrlChange: (UrlChange change) {
            final url = change.url ?? '';
            if (url.isEmpty || url == 'about:blank') return;
            _logCurrentUrl('urlChange', url);
          },
          onPageStarted: (String url) {
            _logCurrentUrl('pageStarted', url);
            if (!mounted) return;
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            _logCurrentUrl('pageFinished', url);
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
