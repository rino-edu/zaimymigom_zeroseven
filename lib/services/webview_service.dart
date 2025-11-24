import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:image_picker/image_picker.dart';

/// Сервис для работы с WebView
class WebViewService {
  static final WebViewService _instance = WebViewService._internal();
  factory WebViewService() => _instance;
  WebViewService._internal();

  final ImagePicker _imagePicker = ImagePicker();
  WebViewController? _controller;

  /// Получить контроллер WebView
  WebViewController getController() {
    _controller ??= WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Можно добавить индикатор загрузки
          },
          onPageStarted: (String url) {
            // Страница начала загружаться
          },
          onPageFinished: (String url) {
            // Страница загружена
          },
          onWebResourceError: (WebResourceError error) {
            // Обработка ошибок
          },
          onNavigationRequest: (NavigationRequest request) {
            // Можно контролировать навигацию
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'FileUpload',
        onMessageReceived: (JavaScriptMessage message) {
          _handleFileUploadRequest(message.message);
        },
      );
    return _controller!;
  }

  /// Загрузить URL в WebView
  Future<void> loadUrl(String url) async {
    final controller = getController();
    await controller.loadRequest(Uri.parse(url));

    // Инжектируем JavaScript для обработки файлов
    await _injectFileUploadScript();
  }

  /// Инжектировать JavaScript для обработки загрузки файлов
  Future<void> _injectFileUploadScript() async {
    final controller = getController();
    await controller.runJavaScript('''
      // Создаем глобальную функцию для обработки результатов
      window.handleFileUploadResult = function(callbackId, result) {
        // Находим элемент по callbackId и вызываем callback
        const element = document.querySelector('[data-callback-id="' + callbackId + '"]');
        if (element && element.onFileUploadResult) {
          element.onFileUploadResult(result);
        }
      };

      // Перехватываем клики по input[type="file"]
      document.addEventListener('click', function(e) {
        const target = e.target;
        if (target.tagName === 'INPUT' && target.type === 'file') {
          e.preventDefault();
          e.stopPropagation();
          
          // Генерируем уникальный ID для callback
          const callbackId = 'callback_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
          target.setAttribute('data-callback-id', callbackId);
          
          // Отправляем запрос в Flutter
          FileUpload.postMessage('pickImage|' + callbackId);
        }
      }, true);

      // Перехватываем изменения в input[type="file"]
      document.addEventListener('change', function(e) {
        const target = e.target;
        if (target.tagName === 'INPUT' && target.type === 'file') {
          e.preventDefault();
          e.stopPropagation();
          
          // Генерируем уникальный ID для callback
          const callbackId = 'callback_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
          target.setAttribute('data-callback-id', callbackId);
          
          // Отправляем запрос в Flutter
          FileUpload.postMessage('pickImage|' + callbackId);
        }
      }, true);
    ''');
  }

  /// Навигация назад
  Future<bool> goBack() async {
    final controller = getController();
    if (await controller.canGoBack()) {
      await controller.goBack();
      return true;
    }
    return false;
  }

  /// Навигация вперед
  Future<bool> goForward() async {
    final controller = getController();
    if (await controller.canGoForward()) {
      await controller.goForward();
      return true;
    }
    return false;
  }

  /// Обновить страницу
  Future<void> reload() async {
    final controller = getController();
    await controller.reload();
  }

  /// Проверить, можно ли идти назад
  Future<bool> canGoBack() async {
    final controller = getController();
    return await controller.canGoBack();
  }

  /// Проверить, можно ли идти вперед
  Future<bool> canGoForward() async {
    final controller = getController();
    return await controller.canGoForward();
  }

  /// Получить текущий URL
  Future<String?> getCurrentUrl() async {
    final controller = getController();
    return await controller.currentUrl();
  }

  /// Выбрать изображение из галереи
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      return image;
    } catch (e) {
      //debugPrint('Ошибка при выборе изображения из галереи: $e');
      return null;
    }
  }

  /// Сделать фото с камеры
  Future<XFile?> takePhotoFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      return image;
    } catch (e) {
      //debugPrint('Ошибка при съемке фото: $e');
      return null;
    }
  }

  /// Показать диалог выбора источника изображения
  Future<XFile?> showImageSourceDialog(BuildContext context) async {
    return showDialog<XFile?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выберите источник'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Галерея'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final image = await pickImageFromGallery();
                  if (context.mounted) {
                    Navigator.of(context).pop(image);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Камера'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final image = await takePhotoFromCamera();
                  if (context.mounted) {
                    Navigator.of(context).pop(image);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
          ],
        );
      },
    );
  }

  /// Обработка запроса на загрузку файла
  Future<void> _handleFileUploadRequest(String message) async {
    try {
      // Парсим сообщение от JavaScript
      final request = message.split('|');
      if (request.length < 2) return;

      final action = request[0];
      final callbackId = request[1];

      if (action == 'pickImage') {
        // Показываем диалог выбора источника
        final image = await _showImageSourceDialogSync();
        if (image != null) {
          // Читаем файл как base64
          final bytes = await image.readAsBytes();
          final base64 = base64Encode(bytes);

          // Создаем File объект в JavaScript
          final controller = getController();
          await controller.runJavaScript('''
            // Создаем File объект из base64 данных
            function base64ToFile(base64, filename, mimeType) {
              const byteCharacters = atob(base64);
              const byteNumbers = new Array(byteCharacters.length);
              for (let i = 0; i < byteCharacters.length; i++) {
                byteNumbers[i] = byteCharacters.charCodeAt(i);
              }
              const byteArray = new Uint8Array(byteNumbers);
              return new File([byteArray], filename, { type: mimeType });
            }
            
            // Создаем File объект
            const file = base64ToFile('$base64', '${image.name}', '${image.mimeType}');
            
            // Находим input элемент по callbackId
            const input = document.querySelector('[data-callback-id="$callbackId"]');
            if (input) {
              // Создаем DataTransfer объект для симуляции выбора файла
              const dataTransfer = new DataTransfer();
              dataTransfer.items.add(file);
              input.files = dataTransfer.files;
              
              // Триггерим событие change
              const changeEvent = new Event('change', { bubbles: true });
              input.dispatchEvent(changeEvent);
            }
          ''');
        }
      }
    } catch (e) {
      //debugPrint('Ошибка при обработке загрузки файла: $e');
    }
  }

  /// Показать диалог выбора источника изображения (синхронная версия)
  Future<XFile?> _showImageSourceDialogSync() async {
    try {
      final context = _getCurrentContext();
      if (context == null) return null;

      // Показываем диалог выбора источника
      return await showDialog<XFile?>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Выберите источник'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Галерея'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final image = await _imagePicker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop(image);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Камера'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final image = await _imagePicker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 80,
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop(image);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Отмена'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      //debugPrint('Ошибка при выборе изображения: $e');
      return null;
    }
  }

  /// Получить текущий контекст
  BuildContext? _getCurrentContext() {
    return _currentContext;
  }

  /// Установить контекст для показа диалогов
  void setContext(BuildContext context) {
    _currentContext = context;
  }

  BuildContext? _currentContext;

  /// Очистить контроллер (для освобождения ресурсов)
  void dispose() {
    _controller = null;
  }
}
