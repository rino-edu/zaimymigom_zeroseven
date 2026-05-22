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

  const WebViewScreen({super.key, required this.offer, this.url_link});

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
          onNavigationRequest: (NavigationRequest request) {
            final String url = request.url;

            // Проверяем кастомные схемы магазинов приложений
            if (url.contains("rustore.ru") ||
                url.contains("play.google.com/store/apps") ||
                url.contains("appgallery.huawei") ||
                url.contains("apps.apple.com") ||
                url.contains("tel:") || url.contains("vk.com") || url.contains("ok.ru")
            ) {
              developer.log("App store scheme detected: $url", name: _logTag);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
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
          onPageFinished: (String url) async {
            developer.log("Page finished loading: $url", name: _logTag);

            if (url == 'about:blank') return;

            developer.log("Page finished loading: $url", name: _logTag);
            _currentUrl = url;

            // Инжектируем JavaScript для улучшения работы с файлами
            try {
              await controller.runJavaScript('''
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
            developer.log("WebView error: ${error.description}", name: _logTag);
/*            developer.log(
              "WebView error code: ${error.errorCode}",
              name: _logTag,
            );*/

            String error_name = error.description;

            if (_isErrorState) return;

            // Логируем все ошибки для диагностики
            /*developer.log(
              "WebView: обработка ошибки: $error_name",
              name: _logTag,
            );*/

            if (error_name.contains('ERR_BLOCKED_BY_ORB') ||
                error_name.contains('net::ERR_NAME_NOT_RESOLVED')
                || error_name.contains('net::ERR_TIMED_OUT')) {
/*              developer.log(
                "Ignoring ${error.description} for URL: ${error.url}",
                name: _logTag,
              );*/
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

  /// Загрузить начальный URL
  Future<void> _loadInitialUrl() async {
    // Используем url_link если он передан, иначе используем offer.link
    final urlToLoad = widget.url_link ?? widget.offer.link;
    if (urlToLoad.isNotEmpty) {
      try {
        final uri = Uri.parse(urlToLoad);
        if (uri.hasScheme) {
          _initialUrl = urlToLoad;
          developer.log(
            "Loading initial URL: $urlToLoad",
            name: _logTag,
          );
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
    if (_hideLeading) return null;
    return IconButton(
      icon: const Icon(Icons.close),
      onPressed: () => Navigator.of(context).pop(),
      tooltip: 'Закрыть',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
              title: Text(AppStrings.appName, style: const TextStyle(fontSize: 14)),
              centerTitle: true,
              leading: _buildLeading() ??
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
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
            ),
      body: Stack(
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
    );
  }

  @override
  void dispose() {
    // Контроллер будет автоматически очищен системой
    super.dispose();
  }
}
