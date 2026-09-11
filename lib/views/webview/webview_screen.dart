import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../constants/app_strings.dart';
import '../../models/offer.dart';
import '../../services/appmetrica_service.dart';
import 'dart:developer' as developer;
import '../../services/app_mode_service.dart';

/// Экран WebView для отображения веб-страниц
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
  bool _isLoading = true;
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _isErrorState = false;
  final ImagePicker _picker = ImagePicker();
  static const String _logTag = "WebViewDebug";
  late final String _initialUrl;
  bool _hideLeading = false;
  bool _firstRedirectHandled = false;
  String? _firstRedirectUrl;
  String _currentUrl = '';

  /// Только на время открытия анкеты (логирование / будущие нюансы).
  /// Denylist витрин действует всегда — не зависит от guard.
  bool _guardFormOpen = false;
  bool _skippingHistory = false;

  /// CPA/витрины, на которые не пускаем main-frame.
  static const Set<String> _partnerShowcaseHosts = {
    'happyzaym.ru',
    'clickstats.ru',
    'captchacheck.ru',
    'greenzaem.ru',
  };

  /// Доп. path-маркеры витрины на доменах Webbankir.
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

    // Webbankir CMB / CPA-пути
    if (host.contains('wbbankir.ru') || host.contains('wb-digital.ru')) {
      if (_partnerShowcasePathMarkers.any(path.contains)) {
        return true;
      }
    }

    // На всякий случай: cmb-cpa / back-cpa на любом хосте
    if (path.contains('/cmb-cpa') || path.contains('/back-cpa')) {
      return true;
    }

    return false;
  }

  bool _isAuthHistoryHop(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    return host == 'auth.wb-digital.ru' || host.endsWith('.auth.wb-digital.ru');
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
    if (code == -999) return true;
    if (description.contains('cancel')) return true;
    if (description.contains('interrupted')) return true;
    if (description.contains('err_aborted')) return true;
    if (description.contains('err_blocked_by_orb')) return true;
    if (description.contains('err_name_not_resolved')) return true;
    if (description.contains('err_timed_out')) return true;
    if (error.url == 'about:blank') return true;
    if (error.isForMainFrame == false) return true;
    return false;
  }

  /// Инициализация WebView
  void _initializeWebView() {
    developer.log("Initializing WebView controller", name: _logTag);

    late final PlatformWebViewControllerCreationParams params;

    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      developer.log("Using Android WebView creation params", name: _logTag);
      params = AndroidWebViewControllerCreationParams();
    } else {
      developer.log("Using default WebView creation params", name: _logTag);
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setUserAgent(_safariMobileUserAgent)
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

            if (url.contains("rustore.ru") ||
                url.contains("play.google.com/store/apps") ||
                url.contains("appgallery.huawei") ||
                url.contains("apps.apple.com") ||
                url.contains("tel:") ||
                url.contains("vk.com") ||
                url.contains("ok.ru")) {
              developer.log("App store scheme detected: $url", name: _logTag);
              return NavigationDecision.prevent;
            }

            if (_isRegistrationBridge(url) || _isOfferFormHost(url)) {
              _beginFormOpenGuard(url);
              return NavigationDecision.navigate;
            }

            // Denylist витрин/CPA — всегда, не только во время открытия анкеты
            if (_isPartnerShowcaseDetour(url)) {
              debugPrint('[$_logTag] blocked denylist: $url');
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onUrlChange: (UrlChange change) {
            final String url = change.url ?? '';
            if (url.isEmpty || url == 'about:blank') return;

            _logCurrentUrl('urlChange', url);
            _currentUrl = url;

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

            if (url != 'about:blank' && mounted) {
              setState(() {
                _isErrorState = false;
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) async {
            _logCurrentUrl('pageFinished', url);

            if (url == 'about:blank') return;

            _currentUrl = url;

            if (_isOfferFormHost(url)) {
              _endFormOpenGuard(url);
            }

            // Инжектируем JavaScript для улучшения работы с файлами
            // и перехвата window.open (форма Webbankir часто в новом окне)
            try {
              await controller.runJavaScript('''
                (function() {
                  if (window.__flutterWindowOpenHooked) return;
                  window.__flutterWindowOpenHooked = true;
                  window.open = function(url, name, specs) {
                    try {
                      if (url && url !== '' && url !== 'about:blank') {
                        console.log('[WebViewDebug] window.open -> same frame:', url);
                        window.location.href = url;
                        return window;
                      }
                      // blank popup: перехватываем последующую установку location
                      var proxy = {
                        closed: false,
                        close: function() { this.closed = true; },
                        focus: function() {},
                        blur: function() {},
                        document: {
                          write: function() {},
                          writeln: function() {},
                          open: function() {},
                          close: function() {}
                        }
                      };
                      var loc = url || 'about:blank';
                      Object.defineProperty(proxy, 'location', {
                        get: function() {
                          return {
                            href: loc,
                            assign: function(v) { window.location.href = v; },
                            replace: function(v) { window.location.replace(v); },
                            toString: function() { return loc; }
                          };
                        },
                        set: function(v) {
                          if (v) { window.location.href = String(v); }
                        }
                      });
                      return proxy;
                    } catch (e) {
                      console.log('[WebViewDebug] window.open hook error', e);
                      return null;
                    }
                  };
                })();

                const originalClick = HTMLElement.prototype.click;
                HTMLElement.prototype.click = function() {
                  console.log('Element clicked:', this.tagName, this.type);
                  if(this.tagName === 'INPUT' && this.type === 'file') {
                    console.log('File input clicked!');
                  }
                  return originalClick.apply(this, arguments);
                };
                
                document.querySelectorAll('input[type="file"]').forEach(input => {
                  console.log('Found file input:', input);
                  input.addEventListener('click', function() {
                    console.log('File input clicked directly');
                  });
                });
                
                const observer = new MutationObserver(mutations => {
                  mutations.forEach(mutation => {
                    if (mutation.type === 'childList') {
                      mutation.addedNodes.forEach(node => {
                        if (node.querySelectorAll) {
                          node.querySelectorAll('input[type="file"]').forEach(input => {
                            console.log('New file input added:', input);
                            input.addEventListener('click', function() {
                              console.log('New file input clicked');
                            });
                          });
                        }
                      });
                    }
                  });
                });
                
                if (document.body) {
                  observer.observe(document.body, { childList: true, subtree: true });
                }
                console.log('WebView JS initialization complete');
              ''');
            } catch (e, st) {
              // На некоторых страницах (особенно iOS/WKWebView) инъекция JS может падать.
              // Это не должно ломать показ WebView и закрытие экрана.
              developer.log(
                'runJavaScript failed: $e',
                name: _logTag,
                error: e,
                stackTrace: st,
              );
            }

            setState(() {
              _isLoading = false;
            });
            _updateNavigationState();

            final isCombat = AppModeService().currentMode == AppMode.combat;
            if (isCombat) {
              if (!_firstRedirectHandled &&
                  _initialUrl.isNotEmpty &&
                  url != _initialUrl) {
                setState(() {
                  _firstRedirectHandled = true;
                  _hideLeading =
                      true; // скрываем крестик на первой странице после редиректа
                  _firstRedirectUrl = url;
                });
              }
              if (url == _firstRedirectUrl) {
                setState(() {
                  _hideLeading = true;
                });
              } else {
                setState(() {
                  _hideLeading = false;
                });
              }
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

            final error_name = error.description;

            if (error_name.contains('ERR_BLOCKED_BY_ORB') ||
                error_name.contains('net::ERR_NAME_NOT_RESOLVED')
                || error_name.contains('net::ERR_TIMED_OUT')) {
              return;
            } else {
              // При любой ошибке показываем единый диалог
              setState(() {
                _isLoading = false;
                _isErrorState = true;
              });

              _controller.loadRequest(Uri.parse('about:blank'));
              if (mounted) {
                _showUnifiedLoadErrorDialog(errorMessage: error.description);
              }
            }
          },
        ),
      );

    // Настройка для Android WebView с поддержкой выбора файлов
    if (controller.platform is AndroidWebViewController) {
      developer.log("Configuring Android WebViewController", name: _logTag);
      final androidController = controller.platform as AndroidWebViewController;

      androidController.setMediaPlaybackRequiresUserGesture(false);

      try {
        developer.log("Setting file selector handler", name: _logTag);
        androidController.setOnShowFileSelector(_handleFileSelector);
      } catch (e) {
/*        developer.log(
          "Error setting file selector: $e",
          name: _logTag,
          error: e,
        );*/
      }
    }

    _controller = controller;
    _loadInitialUrl();
  }

  /// Печать текущего веб-адреса в консоль (Flutter / Xcode / Logcat)
  void _logCurrentUrl(String source, String url) {
    if (url.isEmpty) return;
    debugPrint('[$_logTag][$source] $url');
    developer.log('[$source] $url', name: _logTag);
  }

  /// Загрузить начальный URL
  Future<void> _loadInitialUrl() async {
    // Используем url_link если он передан, иначе используем offer.link
    final urlToLoad = widget.url_link ?? widget.offer.link;
    if (urlToLoad.isNotEmpty) {
      try {
        final uri = Uri.parse(urlToLoad);
        if (uri.hasScheme) {
          _initialUrl = urlToLoad;
          _logCurrentUrl('initial', urlToLoad);
          await _controller.loadRequest(uri);
        } else {
          developer.log(
            "Invalid URL scheme: $urlToLoad",
            name: _logTag,
          );
        }
      } catch (e) {
        developer.log(
          "Error parsing URL: $urlToLoad, error: $e",
          name: _logTag,
        );
      }
    }
  }

  /// Единый диалог ошибок загрузки
  void _showUnifiedLoadErrorDialog({String? errorMessage}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Ошибка соединения"),
          content: Text(
            "Извините, возникла ошибка интернет соединения. Проверьте подключение к интернету и попробуйте снова.",
          ),
          actions: [
            TextButton(
              child: Text("Попробовать снова"),
              onPressed: () async {
                Navigator.of(context).pop();
                // Перезагружаем страницу с ошибкой, если известна, иначе текущую/initial
                final String urlToLoad = _currentUrl.isNotEmpty
                    ? _currentUrl
                    : _initialUrl;
                if (urlToLoad.isNotEmpty && urlToLoad != 'about:blank') {
                  try {
                    await _controller.loadRequest(Uri.parse(urlToLoad));
                  } catch (e) {
                    developer.log("Retry load failed: $e", name: _logTag);
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

  /// Обработка выбора файлов
  Future<List<String>> _handleFileSelector(FileSelectorParams params) async {
    developer.log(
      "File selector called with params: acceptTypes=${params.acceptTypes}, isCaptureEnabled=${params.isCaptureEnabled}",
      name: _logTag,
    );

    if (!mounted) {
      developer.log("Widget not mounted, cannot show file picker", name: _logTag);
      return [];
    }

    // Проверяем, является ли запрос только для изображений
    final bool isImageOnly = params.acceptTypes.isNotEmpty &&
        params.acceptTypes.every(
          (type) => type.isEmpty || type == "*/*" || type.startsWith("image/"),
        );

    // Проверяем, разрешены ли все типы файлов
    final bool acceptAll = params.acceptTypes.isEmpty ||
        params.acceptTypes.any((type) => type.isEmpty || type == "*/*");

    developer.log("isImageOnly=$isImageOnly, acceptAll=$acceptAll", name: _logTag);

    // Если запрос только для изображений и включена камера - используем ImagePicker
    if (isImageOnly && params.isCaptureEnabled) {
      developer.log("Direct camera capture requested", name: _logTag);
      try {
        final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
        if (photo != null) {
          final String fileUri = Uri.file(photo.path).toString();
          developer.log("Image captured: $fileUri", name: _logTag);
          return [fileUri];
        }
      } catch (e) {
        developer.log("Error capturing image: $e", name: _logTag, error: e);
      }
      return [];
    }

    // Если запрос только для изображений - используем ImagePicker с выбором источника
    if (isImageOnly) {
      developer.log("Image file request, showing image picker", name: _logTag);
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
          developer.log("Attempting to pick image from $source", name: _logTag);
          final XFile? photo = await _picker.pickImage(source: source);
          if (photo != null) {
            final String fileUri = Uri.file(photo.path).toString();
            developer.log("Image picked: $fileUri", name: _logTag);
            return [fileUri];
          }
        } catch (e) {
          developer.log("Error picking image: $e", name: _logTag, error: e);
        }
      }
      return [];
    }

    // Для других типов файлов используем FilePicker
    developer.log("Non-image file request, using FilePicker", name: _logTag);
    try {
      // Преобразуем acceptTypes в формат FilePicker
      FileType fileType = FileType.any;
      List<String>? allowedExtensions;

      if (!acceptAll && params.acceptTypes.isNotEmpty) {
        // Пытаемся определить тип файла из acceptTypes
        final types = params.acceptTypes.where((type) => type.isNotEmpty && type != "*/*").toList();
        
        if (types.isNotEmpty) {
          // Проверяем специфичные расширения
          final extensions = <String>[];
          for (final type in types) {
            if (type.contains('/')) {
              final parts = type.split('/');
              if (parts.length == 2) {
                final subtype = parts[1];
                // Обрабатываем известные типы
                if (subtype == 'pdf') {
                  extensions.add('pdf');
                } else if (subtype == 'msword' || subtype == 'vnd.openxmlformats-officedocument.wordprocessingml.document') {
                  extensions.add('doc');
                  extensions.add('docx');
                } else if (subtype == 'vnd.ms-excel' || subtype == 'vnd.openxmlformats-officedocument.spreadsheetml.sheet') {
                  extensions.add('xls');
                  extensions.add('xlsx');
                } else if (subtype == 'jpeg' || subtype == 'jpg') {
                  extensions.add('jpg');
                  extensions.add('jpeg');
                } else if (subtype == 'png') {
                  extensions.add('png');
                } else if (subtype == 'gif') {
                  extensions.add('gif');
                } else if (subtype == 'plain' || subtype == 'text') {
                  extensions.add('txt');
                }
              }
            }
          }
          
          if (extensions.isNotEmpty) {
            allowedExtensions = extensions;
            fileType = FileType.custom;
          } else {
            fileType = FileType.any;
          }
        }
      }

      developer.log("FilePicker params: fileType=$fileType, allowedExtensions=$allowedExtensions", name: _logTag);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: fileType,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final String filePath = result.files.single.path!;
        final String fileUri = Uri.file(filePath).toString();
        developer.log("File picked: $fileUri", name: _logTag);
        return [fileUri];
      } else {
        developer.log("No file selected", name: _logTag);
      }
    } catch (e) {
      developer.log("Error picking file: $e", name: _logTag, error: e);
    }

    developer.log("Returning empty result", name: _logTag);
    return [];
  }

  /// Обновить состояние навигации
  Future<void> _updateNavigationState() async {
    final canGoBack = await _controller.canGoBack();
    final canGoForward = await _controller.canGoForward();

    if (mounted) {
      setState(() {
        _canGoBack = canGoBack;
        _canGoForward = canGoForward;
      });
    }
  }

  /// Навигация назад — обычный history back.
  /// Пропускаем только промежуточные auth.* hop'ы между анкетой и промо.
  Future<void> _goBack() async {
    if (_skippingHistory) return;
    if (!await _controller.canGoBack()) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final startedOnForm = _isOfferFormHost(_currentUrl);
    _skippingHistory = true;
    try {
      await _controller.goBack();
      await Future<void>.delayed(const Duration(milliseconds: 120));

      for (var i = 0; i < 8; i++) {
        final url = await _controller.currentUrl() ?? _currentUrl;
        final skipAuth = _isAuthHistoryHop(url);
        final skipFormHop = startedOnForm && _isOfferFormHost(url);
        if (!skipAuth && !skipFormHop) break;
        if (!await _controller.canGoBack()) break;
        debugPrint('[$_logTag] goBack skip hop: $url');
        await _controller.goBack();
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
    } finally {
      _skippingHistory = false;
      await _updateNavigationState();
    }
  }

  /// Навигация вперед — обычный history forward.
  Future<void> _goForward() async {
    if (!await _controller.canGoForward()) return;
    await _controller.goForward();
    await _updateNavigationState();
  }

  /// Обновить страницу
  Future<void> _reload() async {
    await _controller.reload();
    _updateNavigationState();
  }

  /// Построить leading в зависимости от режима и текущей страницы
  Widget? _buildLeading() {
    if (widget.isRootShowcase || _hideLeading) return null;
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
        automaticallyImplyLeading: !widget.isRootShowcase,
        leading: widget.isRootShowcase
            ? null
            : (_buildLeading() ??
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                )),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _canGoBack ? _goBack : null,
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

  @override
  void dispose() {
    super.dispose();
  }
}
