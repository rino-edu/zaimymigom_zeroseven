import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../constants/app_strings.dart';
import '../../models/offer.dart';
import '../../services/appmetrica_service.dart';
import 'webview_comebacker_bridge.dart';
import 'webview_navigation_stack.dart';

/// Экран WebView для отображения веб-страниц офферов.
///
/// Защита от камбекеров — порт логики React OfferWebViewPane:
/// JS-мост перехватывает window.open / target=_blank, а Flutter блокирует
/// подмену вкладки и ведёт собственный стек точек входа (не каждый редирект).
class WebViewScreen extends StatefulWidget {
  final Offer offer;
  final String? url_link;

  /// Корневая веб-витрина: нельзя закрыть через leading (нет куда pop).
  final bool isRootShowcase;

  /// Если false — без собственного AppBar (вкладка MainScreen).
  final bool withAppBar;

  const WebViewScreen({
    super.key,
    required this.offer,
    this.url_link,
    this.isRootShowcase = false,
    this.withAppBar = true,
  });

  /// Заглушка-оффер для веб-витрины (WebViewScreen требует Offer).
  static Offer showcasePlaceholderOffer({required String link}) {
    return Offer(
      id: 0,
      isShow: true,
      link: link,
      image: '',
      buttonText: '',
      name: 'Showcase',
      stars: '0',
    );
  }

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  late final WebViewNavigationStack _navStack;
  late final String _initialUrl;

  bool _isLoading = true;
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _isErrorState = false;
  bool _firstRedirectHandled = false;
  String? _firstRedirectUrl;
  String _currentUrl = '';
  String _urlAtLastGesture = '';
  bool _bridgeInjecting = false;

  /// Только на время открытия анкеты (логирование / будущие нюансы).
  bool _guardFormOpen = false;

  final ImagePicker _picker = ImagePicker();
  static const String _logTag = 'WebViewDebug';
  static const String _bridgeChannel = 'FlutterBridge';

  /// CPA/витрины, на которые не пускаем main-frame (доп. denylist).
  static const Set<String> _partnerShowcaseHosts = {
    'happyzaym.ru',
    'clickstats.ru',
    'captchacheck.ru',
    'greenzaem.ru',
  };

  static const Set<String> _partnerShowcasePathMarkers = {
    '/promo/cmb',
    '/cmb-cpa',
    '/back-cpa',
  };

  /// UA как у мобильного Safari — меньше детекта in-app WebView.
  static const String _safariMobileUserAgent =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) '
      'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 '
      'Mobile/15E148 Safari/604.1';

  @override
  void initState() {
    super.initState();
    _initialUrl = widget.url_link ?? widget.offer.link;
    _navStack = WebViewNavigationStack(_initialUrl);
    _currentUrl = _initialUrl;
    _initializeWebView();
    AppMetricaService.reportScreen('webview_offer');
  }

  bool _isOfferFormHost(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    return host == 'registration.wbbankir.ru' ||
        host.endsWith('.registration.wbbankir.ru');
  }

  bool _isRegistrationBridge(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    if (host != 'auth.wb-digital.ru' && !host.endsWith('.auth.wb-digital.ru')) {
      return false;
    }
    return uri.path.toLowerCase().contains('/registration');
  }

  bool _isPartnerShowcaseDetour(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();

    if (_partnerShowcaseHosts.any((h) => host == h || host.endsWith('.$h'))) {
      return true;
    }

    if (host.contains('wbbankir.ru') || host.contains('wb-digital.ru')) {
      if (_partnerShowcasePathMarkers.any(path.contains)) {
        return true;
      }
    }

    if (path.contains('/cmb-cpa') || path.contains('/back-cpa')) {
      return true;
    }

    return false;
  }

  void _beginFormOpenGuard(String url) {
    if (_guardFormOpen) return;
    _guardFormOpen = true;
    debugPrint('[$_logTag] form-open guard ON: $url');
  }

  void _endFormOpenGuard(String url) {
    if (!_guardFormOpen) return;
    _guardFormOpen = false;
    debugPrint('[$_logTag] form-open guard OFF: $url');
  }

  bool _isCancelledOrIgnorableError(WebResourceError error) {
    final description = error.description.toLowerCase();
    final code = error.errorCode;
    if (code == -999 || code == 102) return true;
    if (description.contains('cancel')) return true;
    if (description.contains('interrupted')) return true;
    if (description.contains('прерван')) return true;
    if (description.contains('err_aborted')) return true;
    if (description.contains('err_blocked_by_orb')) return true;
    if (description.contains('err_name_not_resolved')) return true;
    if (description.contains('err_timed_out')) return true;
    if (error.url == 'about:blank') return true;
    if (error.isForMainFrame == false) return true;
    return false;
  }

  bool _isExternalAppScheme(String url) {
    return url.contains('rustore.ru') ||
        url.contains('play.google.com/store/apps') ||
        url.contains('appgallery.huawei') ||
        url.contains('apps.apple.com') ||
        url.contains('tel:') ||
        url.contains('vk.com') ||
        url.contains('ok.ru');
  }

  void _syncNavButtons() {
    if (!mounted) return;
    setState(() {
      _canGoBack = _navStack.canGoBack;
      _canGoForward = _navStack.canGoForward;
    });
  }

  Future<void> _injectComebackerBridge() async {
    if (_bridgeInjecting) return;
    _bridgeInjecting = true;
    try {
      await _controller.runJavaScript(kWebViewComebackerBridgeJs);
    } catch (e, st) {
      developer.log(
        'bridge inject failed: $e',
        name: _logTag,
        error: e,
        stackTrace: st,
      );
    } finally {
      _bridgeInjecting = false;
    }
  }

  Future<void> _injectFileHelpers() async {
    try {
      await _controller.runJavaScript('''
        (function() {
          if (window.__flutterFileHelpersInstalled) return;
          window.__flutterFileHelpersInstalled = true;
          const originalClick = HTMLElement.prototype.click;
          HTMLElement.prototype.click = function() {
            if (this.tagName === 'INPUT' && this.type === 'file') {
              console.log('[WebViewDebug] File input clicked');
            }
            return originalClick.apply(this, arguments);
          };
        })();
      ''');
    } catch (_) {}
  }

  void _handleBridgeMessage(String raw) {
    try {
      final data = jsonDecode(raw);
      if (data is! Map) return;
      final type = data['type'];
      if (type == 'GESTURE') {
        _navStack.markGesture();
        _urlAtLastGesture = _currentUrl;
        return;
      }
      if (type == 'OPEN_URL' && data['url'] is String) {
        final url = data['url'] as String;
        debugPrint('[$_logTag] bridge OPEN_URL: $url');
        _navStack.openAsNewEntry(url, forceLoad: false);
        _syncNavButtons();

        // JS уже делает location.replace — не дублируем загрузку.
        // Reclaim только если рекламный URL уже успел подменить вкладку.
        final current = _currentUrl;
        final onTarget = WebViewUrlUtils.startsWith(current, url);
        final stillOnOpener = WebViewUrlUtils.same(current, _urlAtLastGesture) ||
            current.isEmpty ||
            current.startsWith('about:');
        if (!onTarget && !stillOnOpener) {
          debugPrint('[$_logTag] reclaim after tab-replace: $url (was $current)');
          _navStack.pendingNav = url;
          _loadUrl(url);
        }
      }
    } catch (_) {
      // чужое сообщение — игнорируем
    }
  }

  Future<void> _loadUrl(String url) async {
    if (url.isEmpty || url == 'about:blank') return;
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _isErrorState = false;
          _currentUrl = url;
        });
      }
      await _controller.loadRequest(Uri.parse(url));
    } catch (e) {
      developer.log('loadUrl failed: $e', name: _logTag, error: e);
    }
  }

  void _initializeWebView() {
    developer.log('Initializing WebView controller', name: _logTag);

    late final PlatformWebViewControllerCreationParams params;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
      );
    } else if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setUserAgent(_safariMobileUserAgent)
      ..addJavaScriptChannel(
        _bridgeChannel,
        onMessageReceived: (JavaScriptMessage message) {
          _handleBridgeMessage(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final String url = request.url;
            _logCurrentUrl(
              request.isMainFrame ? 'navigation' : 'navigation(iframe)',
              url,
            );

            if (!request.isMainFrame) {
              return NavigationDecision.navigate;
            }

            // iOS ATS: cleartext HTTP → HTTPS (HSTS / HTTPS-First).
            if (url.startsWith('http://')) {
              final httpsUrl = 'https://${url.substring('http://'.length)}';
              debugPrint('[$_logTag] upgrade http→https: $httpsUrl');
              Future.microtask(() async {
                try {
                  await controller.loadRequest(Uri.parse(httpsUrl));
                } catch (e) {
                  developer.log(
                    'http→https upgrade failed: $e',
                    name: _logTag,
                    error: e,
                  );
                }
              });
              return NavigationDecision.prevent;
            }

            if (_isExternalAppScheme(url)) {
              developer.log('App store scheme detected: $url', name: _logTag);
              return NavigationDecision.prevent;
            }

            if (_isRegistrationBridge(url) || _isOfferFormHost(url)) {
              _beginFormOpenGuard(url);
            }

            // Denylist известных CPA-витрин (доп. защита).
            if (_isPartnerShowcaseDetour(url)) {
              debugPrint('[$_logTag] blocked denylist: $url');
              return NavigationDecision.prevent;
            }

            // Главная защита от камбекеров: пока активен popup-intent,
            // любой другой top-level URL считаем подменой вкладки.
            if (!_navStack.shouldAllowNavigation(
              url,
              isMainFrame: request.isMainFrame,
            )) {
              debugPrint('[$_logTag] blocked tab-replace: $url');
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onUrlChange: (UrlChange change) {
            final String url = change.url ?? '';
            if (url.isEmpty || url == 'about:blank') return;

            _logCurrentUrl('urlChange', url);
            _currentUrl = url;
            _navStack.onNavUrlSeen(url);
            _updateLeadingVisibility(url);

            if (_isRegistrationBridge(url) || _isOfferFormHost(url)) {
              _beginFormOpenGuard(url);
            }
          },
          onPageStarted: (String url) {
            _logCurrentUrl('pageStarted', url);
            _currentUrl = url;

            if (_isRegistrationBridge(url) || _isOfferFormHost(url)) {
              _beginFormOpenGuard(url);
            }

            if (url != 'about:blank') {
              _navStack.onLoadStart(url);
              _syncNavButtons();
              if (_navStack.canGoBack) {
                debugPrint(
                  '[$_logTag] nav stack: index=${_navStack.index} '
                  'back=${_navStack.canGoBack} entries=${_navStack.entries.length}',
                );
              }
              _updateLeadingVisibility(url);
              // Инжектим мост как можно раньше на каждом документе.
              _injectComebackerBridge();
              if (mounted) {
                setState(() {
                  _isErrorState = false;
                  _isLoading = true;
                });
              }
            }
          },
          onPageFinished: (String url) async {
            _logCurrentUrl('pageFinished', url);
            if (url == 'about:blank') return;

            _currentUrl = url;
            _navStack.onLoadEnd();

            if (_isOfferFormHost(url)) {
              _endFormOpenGuard(url);
            }

            await _injectComebackerBridge();
            await _injectFileHelpers();

            if (mounted) {
              setState(() => _isLoading = false);
            }
            _syncNavButtons();
            _updateLeadingVisibility(url);
          },
          onProgress: (int progress) {
            // Повторная ранняя инъекция на старте загрузки документа.
            if (progress > 0 && progress < 40) {
              _injectComebackerBridge();
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint(
              '[$_logTag] resource error: ${error.description} '
              'code=${error.errorCode} url=${error.url} '
              'mainFrame=${error.isForMainFrame}',
            );

            if (_guardFormOpen || _isCancelledOrIgnorableError(error)) {
              debugPrint('[$_logTag] ignore resource error');
              return;
            }

            if (_isErrorState) return;

            final errorUrl = error.url ?? '';
            final isAtsHttpBlock = error.errorCode == -1022 ||
                error.description.contains('App Transport Security') ||
                error.description.contains('secure connection');
            if (isAtsHttpBlock && errorUrl.startsWith('http://')) {
              final httpsUrl =
                  'https://${errorUrl.substring('http://'.length)}';
              debugPrint('[$_logTag] ATS http block → retry https: $httpsUrl');
              Future.microtask(() async {
                try {
                  await controller.loadRequest(Uri.parse(httpsUrl));
                } catch (e) {
                  developer.log(
                    'ATS https retry failed: $e',
                    name: _logTag,
                    error: e,
                  );
                }
              });
              return;
            }

            final errorName = error.description;
            if (errorName.contains('ERR_BLOCKED_BY_ORB') ||
                errorName.contains('net::ERR_NAME_NOT_RESOLVED') ||
                errorName.contains('net::ERR_TIMED_OUT')) {
              return;
            }

            setState(() {
              _isLoading = false;
              _isErrorState = true;
            });

            _controller.loadRequest(Uri.parse('about:blank'));
            if (mounted) {
              _showUnifiedLoadErrorDialog(errorMessage: error.description);
            }
          },
        ),
      );

    if (controller.platform is AndroidWebViewController) {
      developer.log('Configuring Android WebViewController', name: _logTag);
      final androidController = controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
      try {
        androidController.setOnShowFileSelector(_handleFileSelector);
      } catch (_) {}
    }

    if (controller.platform is WebKitWebViewController) {
      final wkController = controller.platform as WebKitWebViewController;
      // Свайп «назад» использует нативную историю WKWebView и рассинхронизирует
      // наш стек точек входа + защиту от подмены вкладки.
      wkController.setAllowsBackForwardNavigationGestures(false);
    }

    _controller = controller;
    _loadInitialUrl();
  }

  void _updateLeadingVisibility(String url) {
    if (!mounted || url.isEmpty || url.startsWith('about:')) return;

    // Запоминаем первую «реальную» страницу после affiliate-редиректа
    // (для home на веб-витрине и отладки).
    if (!_firstRedirectHandled &&
        _initialUrl.isNotEmpty &&
        url != _initialUrl) {
      setState(() {
        _firstRedirectHandled = true;
        _firstRedirectUrl = url;
      });
    } else if (widget.isRootShowcase && mounted) {
      // Обновить leading (home) при SPA-переходах.
      setState(() {});
    }
  }

  void _logCurrentUrl(String source, String url) {
    if (url.isEmpty) return;
    debugPrint('[$_logTag][$source] $url');
    developer.log('[$source] $url', name: _logTag);
  }

  Future<void> _loadInitialUrl() async {
    if (_initialUrl.isEmpty) return;
    try {
      final uri = Uri.parse(_initialUrl);
      if (!uri.hasScheme) {
        developer.log('Invalid URL scheme: $_initialUrl', name: _logTag);
        return;
      }
      _logCurrentUrl('initial', _initialUrl);
      await _controller.loadRequest(uri);
    } catch (e) {
      developer.log(
        'Error parsing URL: $_initialUrl, error: $e',
        name: _logTag,
      );
    }
  }

  void _showUnifiedLoadErrorDialog({String? errorMessage}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ошибка соединения'),
          content: const Text(
            'Извините, возникла ошибка интернет соединения. '
            'Проверьте подключение к интернету и попробуйте снова.',
          ),
          actions: [
            TextButton(
              child: const Text('Попробовать снова'),
              onPressed: () async {
                Navigator.of(context).pop();
                final String urlToLoad = _currentUrl.isNotEmpty
                    ? _currentUrl
                    : _initialUrl;
                if (urlToLoad.isNotEmpty && urlToLoad != 'about:blank') {
                  try {
                    await _controller.loadRequest(Uri.parse(urlToLoad));
                  } catch (e) {
                    developer.log('Retry load failed: $e', name: _logTag);
                  }
                } else {
                  _controller.reload();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<List<String>> _handleFileSelector(FileSelectorParams params) async {
    developer.log(
      'File selector called with params: acceptTypes=${params.acceptTypes}, '
      'isCaptureEnabled=${params.isCaptureEnabled}',
      name: _logTag,
    );

    if (!mounted) return [];

    final bool isImageOnly = params.acceptTypes.isNotEmpty &&
        params.acceptTypes.every(
          (type) => type.isEmpty || type == '*/*' || type.startsWith('image/'),
        );

    final bool acceptAll = params.acceptTypes.isEmpty ||
        params.acceptTypes.any((type) => type.isEmpty || type == '*/*');

    if (isImageOnly && params.isCaptureEnabled) {
      try {
        final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
        if (photo != null) {
          return [Uri.file(photo.path).toString()];
        }
      } catch (e) {
        developer.log('Error capturing image: $e', name: _logTag, error: e);
      }
      return [];
    }

    if (isImageOnly) {
      ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Сделать фото'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Выбрать из галереи'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );

      if (source != null) {
        try {
          final XFile? photo = await _picker.pickImage(source: source);
          if (photo != null) {
            return [Uri.file(photo.path).toString()];
          }
        } catch (e) {
          developer.log('Error picking image: $e', name: _logTag, error: e);
        }
      }
      return [];
    }

    try {
      FileType fileType = FileType.any;
      List<String>? allowedExtensions;

      if (!acceptAll && params.acceptTypes.isNotEmpty) {
        final types = params.acceptTypes
            .where((type) => type.isNotEmpty && type != '*/*')
            .toList();

        if (types.isNotEmpty) {
          final extensions = <String>[];
          for (final type in types) {
            if (!type.contains('/')) continue;
            final parts = type.split('/');
            if (parts.length != 2) continue;
            final subtype = parts[1];
            if (subtype == 'pdf') {
              extensions.add('pdf');
            } else if (subtype == 'msword' ||
                subtype ==
                    'vnd.openxmlformats-officedocument.wordprocessingml.document') {
              extensions.addAll(['doc', 'docx']);
            } else if (subtype == 'vnd.ms-excel' ||
                subtype ==
                    'vnd.openxmlformats-officedocument.spreadsheetml.sheet') {
              extensions.addAll(['xls', 'xlsx']);
            } else if (subtype == 'jpeg' || subtype == 'jpg') {
              extensions.addAll(['jpg', 'jpeg']);
            } else if (subtype == 'png') {
              extensions.add('png');
            } else if (subtype == 'gif') {
              extensions.add('gif');
            } else if (subtype == 'plain' || subtype == 'text') {
              extensions.add('txt');
            }
          }

          if (extensions.isNotEmpty) {
            allowedExtensions = extensions;
            fileType = FileType.custom;
          }
        }
      }

      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: fileType,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return [Uri.file(result.files.single.path!).toString()];
      }
    } catch (e) {
      developer.log('Error picking file: $e', name: _logTag, error: e);
    }

    return [];
  }

  /// Назад по стеку точек входа (не нативная история WebView).
  /// На корне оффера — закрываем экран (как раньше при пустой history).
  Future<void> _goBack() async {
    if (!_navStack.canGoBack) {
      if (!widget.isRootShowcase && mounted) {
        Navigator.of(context).pop();
      }
      return;
    }
    final target = _navStack.goToEntry(_navStack.index - 1);
    if (target == null) return;
    debugPrint('[$_logTag] goBack -> $target');
    _syncNavButtons();
    await _loadUrl(target);
  }

  Future<void> _goForward() async {
    if (!_navStack.canGoForward) return;
    final target = _navStack.goToEntry(_navStack.index + 1);
    if (target == null) return;
    debugPrint('[$_logTag] goForward -> $target');
    _syncNavButtons();
    await _loadUrl(target);
  }

  Future<void> _goHome() async {
    final home = _firstRedirectUrl ?? _initialUrl;
    if (home.isEmpty) return;
    debugPrint('[$_logTag] goHome -> $home');
    _navStack.reset(home);
    _syncNavButtons();
    await _loadUrl(home);
  }

  Future<void> _reload() async {
    await _controller.reload();
  }

  Widget? _buildLeading() {
    if (widget.isRootShowcase) {
      final showHome = _firstRedirectHandled &&
          _firstRedirectUrl != null &&
          _currentUrl != _firstRedirectUrl;
      if (!showHome) return null;
      return IconButton(
        icon: const Icon(Icons.home),
        onPressed: _goHome,
        tooltip: 'На главную',
      );
    }

    // Оффер с нативной витрины: крестик всегда виден.
    return IconButton(
      icon: const Icon(Icons.close),
      onPressed: () => Navigator.of(context).pop(),
      tooltip: 'Закрыть',
    );
  }

  @override
  Widget build(BuildContext context) {
    final webViewBody = Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Загрузка...'),
              ],
            ),
          ),
      ],
    );

    if (!widget.withAppBar) {
      return Scaffold(body: webViewBody);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.appName, style: const TextStyle(fontSize: 14)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: _buildLeading(),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            // На корне оффера назад закрывает экран (escape hatch).
            onPressed: (_canGoBack || !widget.isRootShowcase) ? _goBack : null,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _canGoForward ? _goForward : null,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reload),
        ],
      ),
      body: webViewBody,
    );
  }
}
