import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/offer.dart';
import '../../services/appmetrica_service.dart';
import 'dart:developer' as developer;
import '../../services/app_mode_service.dart';

/// Экран WebView для отображения веб-страниц
class WebViewScreen extends StatefulWidget {
  final Offer offer;

  const WebViewScreen({super.key, required this.offer});

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

  @override
  void initState() {
    super.initState();
    _initializeWebView();

    // Отправляем событие о просмотре WebView в AppMetrica
    AppMetricaService.reportScreen('webview_offer');
    AppMetricaService.reportEvent(
      'webview_opened',
      parameters: {
        'offer_id': widget.offer.id.toString(),
        'offer_name': widget.offer.name,
        'offer_link': widget.offer.link,
      },
    );
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
      ..setNavigationDelegate(
        NavigationDelegate(
          onUrlChange: (UrlChange change) {
            final String url = change.url ?? '';
            if (url.isEmpty || url == 'about:blank') return;

            developer.log("URL changed to: $url", name: _logTag);
            _currentUrl = url;
          },
          onPageStarted: (String url) {
            developer.log("Page started loading: $url", name: _logTag);

            setState(() {
              _isErrorState = false;
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            developer.log("Page finished loading: $url", name: _logTag);

            if (url == 'about:blank') return;

            developer.log("Page finished loading: $url", name: _logTag);
            _currentUrl = url;

            // Инжектируем JavaScript для улучшения работы с файлами
            controller.runJavaScript('''
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
              
              observer.observe(document.body, { childList: true, subtree: true });
              console.log('WebView JS initialization complete');
            ''');

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
            developer.log("WebView error: ${error.description}", name: _logTag);
            developer.log(
              "WebView error code: ${error.errorCode}",
              name: _logTag,
            );

            String error_name = error.description;

            if (_isErrorState) return;

            // Логируем все ошибки для диагностики
            developer.log(
              "WebView: обработка ошибки: $error_name",
              name: _logTag,
            );

            if (error_name.contains('ERR_BLOCKED_BY_ORB') ||
                error_name.contains('net::ERR_NAME_NOT_RESOLVED')) {
              developer.log(
                "Ignoring ${error.description} for URL: ${error.url}",
                name: _logTag,
              );
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
        developer.log(
          "Error setting file selector: $e",
          name: _logTag,
          error: e,
        );
      }
    }

    _controller = controller;
    _loadInitialUrl();
  }

  /// Загрузить начальный URL
  Future<void> _loadInitialUrl() async {
    if (widget.offer.link.isNotEmpty) {
      try {
        final uri = Uri.parse(widget.offer.link);
        if (uri.hasScheme) {
          _initialUrl = widget.offer.link;
          developer.log(
            "Loading initial URL: ${widget.offer.link}",
            name: _logTag,
          );
          await _controller.loadRequest(uri);
        } else {
          developer.log(
            "Invalid URL scheme: ${widget.offer.link}",
            name: _logTag,
          );
        }
      } catch (e) {
        developer.log(
          "Error parsing URL: ${widget.offer.link}, error: $e",
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

    final bool acceptImage =
        params.acceptTypes.isEmpty ||
        params.acceptTypes.any(
          (type) => type.isEmpty || type == "*/*" || type.startsWith("image/"),
        );

    developer.log("acceptImage=$acceptImage", name: _logTag);

    if (!acceptImage) {
      developer.log("Not an image request, ignoring", name: _logTag);
      return [];
    }

    ImageSource? source;

    final bool captureEnabled = params.isCaptureEnabled;
    developer.log("captureEnabled=$captureEnabled", name: _logTag);

    if (captureEnabled) {
      developer.log("Direct camera capture requested", name: _logTag);
      source = ImageSource.camera;
    } else {
      if (!mounted) {
        developer.log("Widget not mounted, cannot show dialog", name: _logTag);
        return [];
      }

      developer.log("Showing source choice dialog", name: _logTag);
      source = await showModalBottomSheet<ImageSource>(
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

      developer.log("User selected source: $source", name: _logTag);
    }

    if (source != null) {
      try {
        developer.log("Attempting to pick image from $source", name: _logTag);
        final XFile? photo = await _picker.pickImage(source: source);

        if (photo != null) {
          final String filePath = photo.path;
          developer.log("Image picked: $filePath", name: _logTag);

          final String fileUri = Uri.file(filePath).toString();
          developer.log("Returning file URI: $fileUri", name: _logTag);

          return [fileUri];
        } else {
          developer.log("No image selected/captured", name: _logTag);
        }
      } catch (e) {
        developer.log("Error picking image: $e", name: _logTag, error: e);
      }
    } else {
      developer.log("No source selected", name: _logTag);
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

  /// Навигация назад
  Future<void> _goBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      _updateNavigationState();
    } else {
      // Если нельзя идти назад, закрываем экран
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  /// Навигация вперед
  Future<void> _goForward() async {
    if (await _controller.canGoForward()) {
      await _controller.goForward();
      _updateNavigationState();
    }
  }

  /// Обновить страницу
  Future<void> _reload() async {
    await _controller.reload();
    _updateNavigationState();
  }

  /// Построить leading в зависимости от режима и текущей страницы
  Widget? _buildLeading() {
    // Если нужно скрыть — возвращаем null
    if (_hideLeading) return null;
    // В остальных случаях показываем крестик (закрытие)
    final isCombat = AppModeService().currentMode == AppMode.combat;
    if (isCombat &&
        _firstRedirectUrl != null &&
        _firstRedirectUrl!.isNotEmpty) {
      // В боевом режиме: кнопка загружает страницу после первого редиректа
      return IconButton(
        icon: const Icon(Icons.close),
        onPressed: () async {
          try {
            final target = _firstRedirectUrl!;
            developer.log(
              "Leading pressed - loading first redirect: $target",
              name: _logTag,
            );
            final uri = Uri.parse(target);
            await _controller.loadRequest(uri);
            _updateNavigationState();
          } catch (_) {
            // игнорируем ошибки парсинга/загрузки
          }
        },
        tooltip: 'Open',
      );
    }
    return IconButton(
      icon: const Icon(Icons.close),
      onPressed: () => Navigator.of(context).pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCombat = AppModeService().currentMode == AppMode.combat;

    // Вычисляем динамический отступ для bottom bar
    // Высота LiquidGlassBottomBar обычно около 60-80 пикселей
    // Плюс системные отступы (safe area)
    final mediaQuery = MediaQuery.of(context);
    final bottomBarHeight =
        20.0; // Безопасная высота LiquidGlassBottomBar (с учетом всех вариантов)
    final systemBottomPadding = mediaQuery.padding.bottom;
    final totalBottomPadding =
        bottomBarHeight +
        systemBottomPadding +
        4; // +4 для дополнительного отступа

    return Scaffold(
      appBar: isCombat
          ? AppBar(
              title: Text("Быстрый Заём", style: const TextStyle(fontSize: 18)),
              centerTitle: true,
              leading: _buildLeading(),
              actions: [
                // Кнопка назад
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _canGoBack ? _goBack : null,
                ),
                // Кнопка вперед
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _canGoForward ? _goForward : null,
                ),
                // Кнопка обновления
                IconButton(icon: const Icon(Icons.refresh), onPressed: _reload),
              ],
            )
          : null,
      body: Padding(
        padding: EdgeInsets.only(bottom: isCombat ? 0 : totalBottomPadding),
        child: Stack(
          children: [
            // WebView
            WebViewWidget(controller: _controller),

            // Индикатор загрузки
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
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Контроллер будет автоматически очищен системой
    super.dispose();
  }
}
