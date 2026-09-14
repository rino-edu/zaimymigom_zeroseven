/// Точка входа в историю WebView (не каждый редирект).
class WebViewHistoryEntry {
  WebViewHistoryEntry({required this.requested, required this.resolved});

  /// URL, который пользователь реально открыл.
  final String requested;

  /// Куда в итоге привела цепочка редиректов.
  String resolved;
}

class PopupIntent {
  PopupIntent({required this.url, required this.deadline});

  String url;
  DateTime deadline;
}

/// Нормализация и сравнение URL (как в браузере).
class WebViewUrlUtils {
  static String normalize(String? url) {
    if (url == null || url.isEmpty) return '';
    try {
      return Uri.parse(url).toString();
    } catch (_) {
      return url;
    }
  }

  /// http и https считаем эквивалентными — иначе ATS-upgrade ломает popup-intent.
  static String _schemeAgnostic(String url) {
    final normalized = normalize(url);
    if (normalized.startsWith('http://')) {
      return 'https://${normalized.substring('http://'.length)}';
    }
    return normalized;
  }

  static bool same(String? a, String? b) =>
      _schemeAgnostic(a ?? '') == _schemeAgnostic(b ?? '');

  static bool startsWith(String? url, String? prefix) {
    final nUrl = _schemeAgnostic(url ?? '');
    final nPrefix = _schemeAgnostic(prefix ?? '');
    if (nPrefix.isEmpty) return false;
    return nUrl.startsWith(nPrefix);
  }

  static String hostOf(String? url) {
    final uri = Uri.tryParse(_schemeAgnostic(url ?? ''));
    if (uri == null || uri.host.isEmpty) return '';
    var host = uri.host.toLowerCase();
    if (host.startsWith('www.')) {
      host = host.substring(4);
    }
    return host;
  }

  /// Другой host после «устаканившейся» страницы = клик по офферу
  /// (в т.ч. из iframe, где GESTURE до main frame не доходит).
  static bool differentHost(String? a, String? b) {
    final ha = hostOf(a);
    final hb = hostOf(b);
    if (ha.isEmpty || hb.isEmpty) return false;
    return ha != hb;
  }
}


/// Стек точек входа + защита от подмены вкладки после window.open.
class WebViewNavigationStack {
  WebViewNavigationStack(String initialUrl) {
    final normalized = WebViewUrlUtils.normalize(initialUrl);
    entries = [
      WebViewHistoryEntry(requested: normalized, resolved: normalized),
    ];
  }

  static const int maxEntries = 60;
  static const Duration popupIntentTtl = Duration(milliseconds: 6000);
  static const Duration userGestureTtl = Duration(milliseconds: 2500);

  late List<WebViewHistoryEntry> entries;
  int index = 0;

  String? pendingNav;
  bool chainLoading = false;
  PopupIntent? popupIntent;
  DateTime lastGestureAt = DateTime.fromMillisecondsSinceEpoch(0);

  bool get canGoBack => index > 0;
  bool get canGoForward => index < entries.length - 1;
  bool get isAtHome => index == 0;

  WebViewHistoryEntry get current => entries[index];

  void reset(String url) {
    final normalized = WebViewUrlUtils.normalize(url);
    entries = [
      WebViewHistoryEntry(requested: normalized, resolved: normalized),
    ];
    index = 0;
    pendingNav = null;
    chainLoading = false;
    popupIntent = null;
    lastGestureAt = DateTime.fromMillisecondsSinceEpoch(0);
  }

  void markGesture() {
    lastGestureAt = DateTime.now();
  }

  void clearPopupIntent() {
    popupIntent = null;
  }

  int findEntryIndex(String target) {
    return entries.indexWhere(
      (e) =>
          WebViewUrlUtils.same(e.resolved, target) ||
          WebViewUrlUtils.same(e.requested, target),
    );
  }

  void updateResolved(String target) {
    if (target.isEmpty || target.startsWith('about:')) return;
    current.resolved = WebViewUrlUtils.normalize(target);
  }

  void pushEntry(String target) {
    if (target.isEmpty || target.startsWith('about:')) return;
    final normalized = WebViewUrlUtils.normalize(target);
    entries = entries.sublist(0, index + 1);
    entries.add(
      WebViewHistoryEntry(requested: normalized, resolved: normalized),
    );
    index = entries.length - 1;

    if (entries.length > maxEntries) {
      // Нулевую запись (исходный оффер) не вытесняем.
      entries.removeAt(1);
      index -= 1;
    }
  }

  /// Заявка на «новую вкладку»: защищает текущую страницу от подмены.
  ///
  /// [forceLoad] == false: JS уже начал переход через location.replace.
  bool openAsNewEntry(String? targetUrl, {bool forceLoad = false}) {
    final nextUrl = WebViewUrlUtils.normalize(targetUrl?.trim());
    if (nextUrl.isEmpty) return false;

    final intent = popupIntent;
    if (intent != null && WebViewUrlUtils.same(intent.url, nextUrl)) {
      intent.deadline = DateTime.now().add(popupIntentTtl);
    } else {
      popupIntent = PopupIntent(
        url: nextUrl,
        deadline: DateTime.now().add(popupIntentTtl),
      );
    }

    final alreadyRecorded = WebViewUrlUtils.same(current.requested, nextUrl) ||
        WebViewUrlUtils.same(current.resolved, nextUrl);

    if (!alreadyRecorded) {
      lastGestureAt = DateTime.fromMillisecondsSinceEpoch(0);
      pushEntry(nextUrl);
    }

    pendingNav = nextUrl;
    return forceLoad;
  }

  /// true = разрешить навигацию, false = заблокировать подмену вкладки.
  bool shouldAllowNavigation(String requestUrl, {required bool isMainFrame}) {
    if (!isMainFrame) return true;

    final pending = pendingNav;
    if (pending != null && WebViewUrlUtils.startsWith(requestUrl, pending)) {
      return true;
    }

    final intent = popupIntent;
    if (intent == null || DateTime.now().isAfter(intent.deadline)) {
      return true;
    }

    if (requestUrl.startsWith('about:') ||
        WebViewUrlUtils.startsWith(requestUrl, intent.url)) {
      return true;
    }

    if (findEntryIndex(requestUrl) != -1) {
      return true;
    }

    return false;
  }

  void onNavUrlSeen(String url) {
    final intent = popupIntent;
    if (intent != null && WebViewUrlUtils.startsWith(url, intent.url)) {
      clearPopupIntent();
    }
  }

  /// Обработка начала загрузки top-level страницы.
  void onLoadStart(String newUrl) {
    if (newUrl.isEmpty) return;

    final intent = popupIntent;
    if (intent != null && WebViewUrlUtils.startsWith(newUrl, intent.url)) {
      clearPopupIntent();
    }

    if (pendingNav != null) {
      pendingNav = null;
      updateResolved(newUrl);
    } else {
      final gestureFresh =
          DateTime.now().difference(lastGestureAt) < userGestureTtl;
      final chainActive = chainLoading;
      // Клик по офферу с веб-витрины часто идёт через iframe → main frame,
      // GESTURE на родителе нет. После pageFinished смена host = новая точка.
      final crossHostAfterSettle = !chainActive &&
          WebViewUrlUtils.differentHost(current.resolved, newUrl);

      if (!chainActive && (gestureFresh || crossHostAfterSettle)) {
        lastGestureAt = DateTime.fromMillisecondsSinceEpoch(0);
        pushEntry(newUrl);
      } else {
        final existing = findEntryIndex(newUrl);
        if (!chainActive && existing != -1 && existing != index) {
          index = existing;
          entries[existing].resolved = WebViewUrlUtils.normalize(newUrl);
        } else {
          updateResolved(newUrl);
        }
      }
    }

    chainLoading = true;
  }

  void onLoadEnd() {
    chainLoading = false;
  }

  /// Цель для перехода по стеку (назад/вперёд).
  String? goToEntry(int nextIndex) {
    if (nextIndex < 0 || nextIndex >= entries.length) return null;
    clearPopupIntent();
    lastGestureAt = DateTime.fromMillisecondsSinceEpoch(0);
    index = nextIndex;
    final entry = entries[nextIndex];
    final target = entry.resolved.isNotEmpty ? entry.resolved : entry.requested;
    pendingNav = target;
    return target;
  }
}
