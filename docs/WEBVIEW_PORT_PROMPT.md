# Промпт для порта WebView (камбекеры + Keitaro + навигация)

**Как пользоваться:** скопируй всё от маркера `<<<PROMPT_START>>>` до `<<<PROMPT_END>>>` и вставь агенту в целевом Flutter-проекте. Код ниже — эталон «как в референс-проекте», его нужно портировать с адаптацией импортов/моделей, **без упрощения логики**.

<<<PROMPT_START>>>

Ты портируешь в ЭТОТ Flutter-проект проверенную реализацию in-app WebView для CPA/Keitaro-витрины офферов. Нужно получить ТО ЖЕ поведение, что в референсе ниже — не «похожее» и не упрощённое.

## Контекст продукта

- Приложение показывает витрину кредитных офферов.
- `nativeVitrina == false` → витрина внутри WebView (`showCaseLink`).
- `nativeVitrina == true` → нативный список; каждый оффер открывается в отдельном WebView.
- Клики/показы логируются в Keitaro через cloaker/tracker (часто host вроде `crapinka.ru`) по `aff_sub4`:
  - `boy` — загрузка веб-витрины (не путать с именем оффера);
  - имя оффера (`webbankir`, `ukki`, …) — клик по офферу.
- На десктопе оффер = новая вкладка; в Telegram WebView клик с витрины = 1 хит.
  Цель: как Telegram — **ровно 1 клик в Keitaro при переходе с витрины на оффер**; «назад» внутри оффера **не** должен снова грузить click-URL.

## Неторгуемые требования

### 1) Борьба с камбекерами

Типичный паттерн: `window.open(правильный URL)` и сразу `location = реклама/витрина конкурента`. В одном WebView оба попадают в одну «вкладку».

Обязательно:

- JS-мост: перехват `window.open` и `<a target="_blank"|_new>`, **один** `location.replace` на правильный URL, `postMessage` с `OPEN_URL` / `GESTURE`.
- Flutter: **popup-intent** (~6 с). Пока активен — блокировать top-level навигацию на чужой URL (`tab-replace`). Iframe не трогать.
- Reclaim click-URL **только если** камбекер **вернул** на opener после ухода. Запрещено крутить `location.replace(click-URL)` в цикле, пока Keitaro редиректит на оффер (иначе 2–20 кликов).
- Дедуп `claimUrl` за 2 с (`window.open` + `target=_blank` на один тап).
- На `OPEN_URL` Flutter **не** вызывает `loadRequest` — JS уже сделал один replace. Повторный load = второй клик в Keitaro.

### 2) Правильное логирование кликов (Keitaro)

- С витрины на оффер click-URL загружается **ровно один раз**.
- Стрелки назад/вперёд **никогда** не грузят сырой click-URL (`requested`). Грузят `landing` = первый URL на **другом host**, чем click-URL.
- Если у записи стека ещё нет `landing` — пропуск к витрине / соседней реальной странице.
- Домик на веб-витрине → стартовая страница после первого редиректа + `reset` стека.
- Веб-витрина: `aff_sub4=boy`. Офферные клики — `aff_sub4` из ссылки оффера на стороне трекера.

### 3) Навигация (свой стек, не history WKWebView)

- Стек «точек входа», не каждый редирект.
- Entry: `requested` (часто click-URL), `resolved`, `landing`.
- Новая точка: свежий GESTURE (<2.5 с) **или** после `pageFinished` смена host (клик из iframe без GESTURE на main frame — Займер/leadgid).
- Редиректы только `updateResolved` (+ `landing` при смене host).
- Обновлять `resolved`/`landing` и на `urlChange` (iOS часто не шлёт `pageStarted` на каждый hop).
- iOS: `setAllowsBackForwardNavigationGestures(false)`.
- Крестик на оффере с нативной витрины **всегда** виден; на корне оффера «назад» может закрывать экран.

### 4) Прочее

- `http://` → `https://` (iOS ATS).
- Safari mobile UA.
- Denylist известных CMB/CPA path (доп. защита).
- File picker на Android.
- Игнорировать отмены навигации (-999, 102, ORB, …).
- Логи `[WebViewDebug]`.

### 5) Запрещено

- Нативный `goBack`/`goForward` как основной стек.
- Повторный `loadRequest` click-URL из Flutter на `OPEN_URL`.
- Interval с `replace(click-URL)`, пока href «не prefix target» после ухода на leadgid/оффер.
- Прятать крестик на лендинге оффера при `canGoBack == false`.
- `aff_sub4=boy_showcase` для веб-витрины (нужен `boy`).

## Архитектура файлов

Создай аналоги:

1. `webview_comebacker_bridge.dart`
2. `webview_navigation_stack.dart`
3. `webview_screen.dart`
4. Интеграция витрины: `isRootShowcase` + `generateModifiedShowCaseLink`
5. Нативные офферы: `generateModifiedOfferLink` + открытие `WebViewScreen`

Адаптируй импорты/модели/аналитику под ЭТОТ репозиторий. Логику WebView не упрощай.

После внедрения: `dart analyze`, пройди чеклист, дай короткий отчёт.

## Чеклист тестов

- [ ] Веб-витрина: 1 загрузка → 1 `boy` в Keitaro
- [ ] Клик оффер без внутренних переходов → 1 клик `aff_sub4=<оффер>`
- [ ] Оффер → внутрь → назад → домик: всё ещё 1 клик оффера (не 2)
- [ ] CTA (Joymoney и т.п.) не уводит на витрину конкурента (`blocked tab-replace`)
- [ ] Iframe→main (Займер): после клика с витрины активна стрелка назад
- [ ] http-редирект оффера открывается (upgrade https)
- [ ] Крестик на оффере с нативной витрины всегда доступен
- [ ] Домик на веб-витрине возвращает на лендинг витрины

## Таблица «симптом → правило»

| Симптом | Причина | Правило |
|--------|---------|---------|
| 2–20 кликов на 1 тап | Цикл replace click-URL после редиректа | Reclaim только после возврата на opener |
| 2-й клик по «назад» | Стек грузил requested | Назад только landing |
| Нет стрелки (Займер) | iframe без GESTURE | После settle смена host = entry |
| Камбекер вместо анкеты | open(good)+location=bad | JS claim + popup-intent |
| Двойной клик на OPEN_URL | Flutter load + JS replace | Flutter не load'ит на OPEN_URL |
| Stuck без крестика | hideLeading + пустой стек | Крестик всегда на оффере |
| iOS ATS http | cleartext | upgrade https |
| Свайп ломает стек | WK gestures | gestures=false |

## Зависимости

- `webview_flutter: ^4.13.0` (+ android/wkwebview)
- `image_picker`, `file_picker` (Android file chooser)

## ЭТАЛОННЫЙ КОД — портируй логику 1:1

### `lib/views/webview/webview_comebacker_bridge.dart`

```dart
/// JS-мост против камбекеров (порт логики из React OfferWebViewPane).
///
/// Витрины часто делают `window.open(правильный URL)` и сразу
/// `window.location.href = рекламный URL`. Мост:
/// 1) один раз уводит вкладку на click-URL через location.replace;
/// 2) шлёт OPEN_URL / GESTURE в Flutter (popup-intent блокирует подмену);
/// 3) reclaim только если камбекер ВЕРНУЛ на opener после ухода.
///
/// Повторный replace click-URL = лишние клики в Keitaro — запрещён.
const String kWebViewComebackerBridgeJs = r'''
(function() {
  if (window.__faBridgeInstalled) { return; }
  window.__faBridgeInstalled = true;

  function send(payload) {
    try {
      if (window.FlutterBridge && window.FlutterBridge.postMessage) {
        window.FlutterBridge.postMessage(JSON.stringify(payload));
      }
    } catch (e) {}
  }

  function absolute(url) {
    try { return new URL(String(url), document.baseURI).href; }
    catch (e) { return String(url); }
  }

  function reportGesture() { send({type: 'GESTURE'}); }
  document.addEventListener('click', reportGesture, true);
  document.addEventListener('touchend', reportGesture, true);
  document.addEventListener('submit', reportGesture, true);

  function samePage(a, b) {
    try {
      var ua = new URL(String(a));
      var ub = new URL(String(b));
      return ua.origin === ub.origin && ua.pathname === ub.pathname;
    } catch (e) {
      return String(a) === String(b);
    }
  }

  function claimUrl(rawUrl) {
    if (!rawUrl) { return; }
    var target = absolute(rawUrl);
    var now = Date.now();

    // window.open + target=_blank часто срабатывают вместе на один клик.
    if (window.__faClaimedUrl === target &&
        window.__faClaimedAt &&
        (now - window.__faClaimedAt) < 2000) {
      return;
    }

    var openerHref = String(window.location.href);
    window.__faClaimedUrl = target;
    window.__faClaimedAt = now;
    window.__faClaimOpener = openerHref;
    send({type: 'OPEN_URL', url: target});

    // Ровно один переход на click-URL — Keitaro должен увидеть 1 клик.
    try { window.location.replace(rawUrl); } catch (e) {}

    var attempts = 0;
    var leftOpener = false;
    var reclaimed = false;
    var timer = setInterval(function() {
      attempts += 1;
      var claimed = window.__faClaimedUrl;
      if (claimed !== target || attempts > 20) {
        clearInterval(timer);
        return;
      }

      var href = String(window.location.href);
      var onOpener = samePage(href, openerHref);

      if (!onOpener) {
        // Ушли с витрины (click-URL / оффер / редирект) — не трогаем.
        leftOpener = true;
        return;
      }

      // Снова на opener только после ухода = камбекер вернул вкладку.
      if (leftOpener && !reclaimed) {
        reclaimed = true;
        try { window.location.replace(target); } catch (e) {}
        clearInterval(timer);
      }
      // Пока ещё не уходили с opener — ждём первый replace, не дублируем.
    }, 50);
  }

  var nativeOpen = window.open;
  window.open = function(url) {
    if (url) {
      claimUrl(url);
      return null;
    }
    if (typeof nativeOpen === 'function') {
      return nativeOpen.apply(window, arguments);
    }
    return null;
  };

  document.addEventListener('click', function(e) {
    var el = e.target;
    while (el && el.tagName !== 'A') { el = el.parentElement; }
    if (!el || !el.href) { return; }
    var target = (el.getAttribute('target') || '').toLowerCase();
    if (target === '_blank' || target === '_new') {
      e.preventDefault();
      e.stopPropagation();
      claimUrl(el.href);
    }
  }, true);
})();
''';

```

### `lib/views/webview/webview_navigation_stack.dart`

```dart
/// Точка входа в историю WebView (не каждый редирект).
class WebViewHistoryEntry {
  WebViewHistoryEntry({required this.requested, required this.resolved});

  /// URL, с которого открыли точку входа (часто Keitaro click-URL).
  final String requested;

  /// Последний URL цепочки редиректов / текущей страницы.
  String resolved;

  /// Первый URL после ухода с host [requested] — лендинг оффера.
  /// Именно его грузим при «назад», а не click-URL (иначе второй клик в Keitaro).
  String? landing;
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
          WebViewUrlUtils.same(e.requested, target) ||
          (e.landing != null && WebViewUrlUtils.same(e.landing, target)),
    );
  }

  void updateResolved(String target) {
    if (target.isEmpty || target.startsWith('about:')) return;
    final normalized = WebViewUrlUtils.normalize(target);
    current.resolved = normalized;

    // Фиксируем лендинг оффера: первый URL на другом host, чем click-URL.
    // Его же используем при «назад», чтобы не бить Keitaro повторно.
    if (current.landing == null &&
        WebViewUrlUtils.differentHost(current.requested, normalized)) {
      current.landing = normalized;
    }
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
      // Нулевую запись (исходная витрина) не вытесняем.
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
        WebViewUrlUtils.same(current.resolved, nextUrl) ||
        (current.landing != null &&
            WebViewUrlUtils.same(current.landing, nextUrl));

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
    if (url.isEmpty || url.startsWith('about:')) return;

    final intent = popupIntent;
    if (intent != null && WebViewUrlUtils.startsWith(url, intent.url)) {
      clearPopupIntent();
    }

    // iOS часто не шлёт pageStarted на каждый hop редиректа — обновляем
    // resolved/landing здесь, иначе «назад» снова откроет click-URL.
    updateResolved(url);
  }

  /// URL для стрелок назад/вперёд: лендинг оффера, никогда сырой click-URL.
  String? _historyTargetFor(WebViewHistoryEntry entry) {
    if (entry.landing != null && entry.landing!.isNotEmpty) {
      return entry.landing;
    }
    if (WebViewUrlUtils.differentHost(entry.requested, entry.resolved)) {
      return entry.resolved;
    }
    // Остались только на click-URL — повторно его не грузим.
    return null;
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
          updateResolved(newUrl);
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
  ///
  /// Не возвращает Keitaro click-URL: только landing/resolved на другом host.
  /// Если у записи ещё нет лендинга — пропускаем её к предыдущей/следующей.
  String? goToEntry(int nextIndex, {required bool goingBack}) {
    if (nextIndex < 0 || nextIndex >= entries.length) return null;
    clearPopupIntent();
    lastGestureAt = DateTime.fromMillisecondsSinceEpoch(0);

    var i = nextIndex;
    while (i >= 0 && i < entries.length) {
      final target = _historyTargetFor(entries[i]);
      if (target != null) {
        index = i;
        pendingNav = target;
        return target;
      }
      // Запись = только click-URL без лендинга: как в Telegram WebView,
      // возвращаемся на витрину / соседнюю «реальную» страницу.
      i = goingBack ? i - 1 : i + 1;
    }

    index = 0;
    final home = entries[0].landing ?? entries[0].resolved;
    pendingNav = home;
    return home;
  }
}

```

### `lib/views/webview/webview_screen.dart`

```dart
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
        return;
      }
      if (type == 'OPEN_URL' && data['url'] is String) {
        final url = data['url'] as String;
        debugPrint('[$_logTag] bridge OPEN_URL: $url');
        _navStack.openAsNewEntry(url, forceLoad: false);
        _syncNavButtons();
        // Не вызываем loadRequest: JS уже сделал один location.replace.
        // Повторный load click-URL = второй клик в Keitaro.
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
    final target = _navStack.goToEntry(
      _navStack.index - 1,
      goingBack: true,
    );
    if (target == null) return;
    debugPrint('[$_logTag] goBack -> $target');
    _syncNavButtons();
    await _loadUrl(target);
  }

  Future<void> _goForward() async {
    if (!_navStack.canGoForward) return;
    final target = _navStack.goToEntry(
      _navStack.index + 1,
      goingBack: false,
    );
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

```

### Интеграция веб-витрины (`showcase_screen.dart`)

Ключ: `generateModifiedShowCaseLink` → `WebViewScreen(isRootShowcase: true, ...)`.

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/combat_onboarding/services/combat_settings_resolver.dart';
import '../../services/app_mode_service.dart';
import '../../services/appmetrica_service.dart';
import '../../services/combat_showcase_analytics.dart';
import '../../services/firebase_analytics_service.dart';
import '../../services/web_link_service.dart';
import 'loans_screen.dart';
import '../webview/webview_screen.dart';

/// Точка входа витрины: нативная ([LoansScreen]) или веб ([WebViewScreen])
/// в зависимости от `nativeVitrina` / `showCaseLink` из settings.
class ShowcaseScreen extends StatefulWidget {
  final bool withScaffold;

  /// Если задан — логируем `show_case_onboarding_*` и пишем aff_sub10.
  final CombatLoansShowCaseReason? showCaseOnboardingReason;

  /// WebView без AppBar (вкладка MainScreen уже даёт свой AppBar).
  final bool embedInParent;

  const ShowcaseScreen({
    super.key,
    this.withScaffold = true,
    this.showCaseOnboardingReason,
    this.embedInParent = false,
  });

  @override
  State<ShowcaseScreen> createState() => _ShowcaseScreenState();
}

class _ShowcaseScreenState extends State<ShowcaseScreen> {
  final _settingsResolver = CombatSettingsResolver();
  final _webLinkService = WebLinkService();
  final _appModeService = AppModeService();

  Widget? _resolved;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _saveOnboardingReason(CombatLoansShowCaseReason reason) async {
    final String sub10Value;
    switch (reason) {
      case CombatLoansShowCaseReason.afterOnboardingFinish:
        sub10Value = 'onboarding_finish';
      case CombatLoansShowCaseReason.afterOnboardingClose:
        sub10Value = 'onboarding_close';
      case CombatLoansShowCaseReason.withoutOnboarding:
        sub10Value = 'onboarding_none';
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(WebLinkService.prefSub10Key, sub10Value);
      debugPrint('ShowcaseScreen: Сохранён aff_sub10=$sub10Value');
    } catch (e) {
      debugPrint('ShowcaseScreen: Ошибка при сохранении aff_sub10: $e');
    }
  }

  void _reportShowCaseAnalytics(CombatLoansShowCaseReason reason) {
    FirebaseAnalyticsService.logLoansShowCaseIfNeeded(reason);
    switch (reason) {
      case CombatLoansShowCaseReason.afterOnboardingFinish:
        AppMetricaService.reportEvent('show_case_onboarding_finish');
      case CombatLoansShowCaseReason.afterOnboardingClose:
        AppMetricaService.reportEvent('show_case_onboarding_close');
      case CombatLoansShowCaseReason.withoutOnboarding:
        AppMetricaService.reportEvent('show_case_onboarding_none');
    }
  }

  Future<void> _resolve() async {
    final isCombat = _appModeService.currentMode == AppMode.combat;
    final showCaseReason = widget.showCaseOnboardingReason;

    final settings = await _settingsResolver.resolveSettings();
    final useNative = settings?.nativeVitrina ?? true;

    debugPrint(
      'ShowcaseScreen: nativeVitrina=$useNative, '
      'showCaseLink=${settings?.showCaseLink}',
    );

    if (!mounted) return;

    if (useNative) {
      setState(() {
        _resolved = LoansScreen(
          withScaffold: widget.withScaffold,
          showCaseOnboardingReason: widget.showCaseOnboardingReason,
        );
      });
      return;
    }

    // Веб-витрина: aff_sub10 до модификации ссылки
    if (showCaseReason != null) {
      await _saveOnboardingReason(showCaseReason);
      _reportShowCaseAnalytics(showCaseReason);
    }

    if (isCombat) {
      CombatShowcaseSession.markLoansScreenOpenedCombat();
    }

    final url = await _webLinkService.generateModifiedShowCaseLink(
      settings?.showCaseLink,
    );

    if (isCombat) {
      CombatShowcaseAnalytics.reportShown();
      AppMetricaService.reportScreen('loans_combat_mode_webview');
    } else {
      AppMetricaService.reportScreen('loans_non_combat_mode_webview');
    }

    if (!mounted) return;

    final offer = WebViewScreen.showcasePlaceholderOffer(link: url);
    setState(() {
      _resolved = WebViewScreen(
        offer: offer,
        url_link: url,
        isRootShowcase: !widget.embedInParent,
        withAppBar: !widget.embedInParent,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return _resolved ??
        const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
  }
}

```

### Трекинг-ссылки (фрагмент `web_link_service.dart`)

Веб-витрина: `aff_sub4=boy`. Офферы: добавить `aff_sub6`/`aff_sub10`, не ломая `aff_sub4` оффера.

```dart
  /// Запасной URL веб-витрины, если `showCaseLink` пустой/невалидный.
  static const String fallbackShowCaseLink =
      'https://crapinka.ru/Zp7h5HDc?aff_sub1=com.kredit7.dney';

  /// Нормализует схему URL (добавляет https:// при необходимости).
  String _ensureHttpsScheme(String link) {
    try {
      final uri = Uri.parse(link);
      if (!uri.hasScheme) {
        return 'https://$link';
      }
      return link;
    } catch (_) {
      return link;
    }
  }

  /// Ставит/заменяет query-параметр в URL.
  String _upsertQueryParam(String link, String key, String value) {
    final uri = Uri.parse(link);
    final params = Map<String, String>.from(uri.queryParameters);
    params[key] = value;
    return uri.replace(queryParameters: params).toString();
  }

  /// Модифицирует ссылку веб-витрины: те же трекинг-параметры, что у офферов,
  /// плюс `aff_sub4=boy` (боевой) / `aff_sub4=vpn` (небоевой).
  Future<String> generateModifiedShowCaseLink(String? showCaseLink) async {
    final raw = (showCaseLink ?? '').trim();
    var link = _ensureHttpsScheme(raw.isNotEmpty ? raw : fallbackShowCaseLink);
    debugPrint('WebLinkService: Модификация showCaseLink: $link');

    if (_currentAppMode == null) {
      final AppMode? modeResult = AppModeService().currentMode;
      isBoyMode = modeResult == AppMode.combat;
      _currentAppMode = modeResult;
      debugPrint('WebLinkService: Режим определён как ${modeResult?.name}');
    }

    final affSub4 = isBoyMode ? 'boy' : 'vpn';
    link = _upsertQueryParam(link, 'aff_sub4', affSub4);
    debugPrint('WebLinkService: Установлен aff_sub4=$affSub4');

    // Как у офферов: aff_sub6 / aff_sub10 только в боевом режиме.
    if (!isBoyMode) {
      debugPrint(
        'WebLinkService: VPN режим — showCaseLink без aff_sub6/aff_sub10: $link',
      );
      return link;
    }

    if ((_linkParams['sub6'] ?? '').isEmpty) {
      _linkParams['sub6'] = await AppMetricaService.getDeviceIdHash();
      await _saveParamsToPrefs();
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String sub6 = _linkParams['sub6'] ?? '';
    if (sub6.isEmpty) {
      final String? prefSub6 = prefs.getString(_prefSub6Key);
      if (prefSub6 != null && prefSub6.isNotEmpty) {
        sub6 = prefSub6;
      }
    }
    if (sub6.isNotEmpty) {
      link = _upsertQueryParam(link, 'aff_sub6', sub6);
      debugPrint('WebLinkService: Установлен aff_sub6=$sub6');
    }

    if (await _shouldAttachAffSub10(prefs)) {
      final String sub10 = prefs.getString(prefSub10Key)!;
      link = _upsertQueryParam(link, 'aff_sub10', sub10);
      await _markAffSub10Applied(prefs);
      debugPrint('WebLinkService: Установлен aff_sub10=$sub10');
    } else {
      debugPrint(
        'WebLinkService: aff_sub10 не добавлен (уже подставляли или пусто)',
      );
    }

    debugPrint('WebLinkService: Итоговая showCaseLink: $link');
    return link;
  }

  /// Модифицирует предоставленную ссылку оффера, добавляя трекинг-параметры
  Future<String> generateModifiedOfferLink(String offerLink) async {
    debugPrint('WebLinkService: Начало модификации ссылки оффера: $offerLink');
    debugPrint('WebLinkService: Текущий режим boy: $isBoyMode');

    // Если режим не определен, определяем его
    if (_currentAppMode == null) {
      final AppMode? modeResult = AppModeService().currentMode;
      isBoyMode = modeResult == AppMode.combat;
      debugPrint('WebLinkService: Режим определен как ${modeResult?.name}');
    }

    // Проверяем текущий режим приложения
    if (!isBoyMode) {
      debugPrint(
        'WebLinkService: VPN режим - возвращаем оригинальную ссылку без модификации: $offerLink',
      );

      // Проверяем валидность ссылки
      try {
        final uri = Uri.parse(offerLink);
        if (!uri.hasScheme) {
          debugPrint(
            'WebLinkService: Ссылка не имеет схемы, добавляем https://',
          );
          return 'https://$offerLink';
        }
        return offerLink;
      } catch (e) {
        debugPrint('WebLinkService: Ошибка парсинга ссылки: $e');
        return offerLink;
      }
    }

    // Получаем параметры, если они еще не загружены.
    if ((_linkParams['sub6'] ?? '').isEmpty) {
      _linkParams['sub6'] = await AppMetricaService.getDeviceIdHash();
      await _saveParamsToPrefs();
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String modifiedLink = offerLink;

    // Добавляем sub6
    String sub6 = _linkParams['sub6'] ?? '';
    if (sub6.isEmpty) {
      final String? prefSub6 = prefs.getString(_prefSub6Key);
      if (prefSub6 != null && prefSub6.isNotEmpty) {
        sub6 = prefSub6;
      }
    }
    if (sub6.isNotEmpty) {
      modifiedLink += "&aff_sub6=$sub6";
      debugPrint('WebLinkService: Добавлен aff_sub6=$sub6');
    }

    // aff_sub10 — один раз на первый оффер (или main), в любой сессии
    if (await _shouldAttachAffSub10(prefs)) {
      final String sub10 = prefs.getString(prefSub10Key)!;
      modifiedLink += "&aff_sub10=$sub10";
      await _markAffSub10Applied(prefs);
      debugPrint('WebLinkService: Добавлен aff_sub10=$sub10');
    } else {
      debugPrint(
        'WebLinkService: aff_sub10 не добавлен (уже подставляли или пусто)',
      );
    }

    debugPrint(
      'WebLinkService: Итоговая модифицированная ссылка оффера: $modifiedLink',
    );
    return modifiedLink;
  }
}
```

Сделай порт сейчас: создай файлы, подключи к навигации/витрине проекта, поправь импорты под локальные модели/сервисы, проверь analyze и опиши, что изменил.

<<<PROMPT_END>>>
