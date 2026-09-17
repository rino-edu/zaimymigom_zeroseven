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
