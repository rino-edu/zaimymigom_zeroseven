/// JS-мост против камбекеров (порт логики из React OfferWebViewPane).
///
/// Витрины часто делают `window.open(правильный URL)` и сразу
/// `window.location.href = рекламный URL`. Мост:
/// 1) синхронно «захватывает» правильный URL через location.replace;
/// 2) шлёт OPEN_URL / GESTURE в Flutter;
/// 3) ~1с удерживает адрес от повторной подмены.
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

  function claimUrl(rawUrl) {
    if (!rawUrl) { return; }
    var target = absolute(rawUrl);
    window.__faClaimedUrl = target;
    send({type: 'OPEN_URL', url: target});

    try { window.location.replace(rawUrl); } catch (e) {}

    var attempts = 0;
    var timer = setInterval(function() {
      attempts += 1;
      var claimed = window.__faClaimedUrl;
      if (claimed !== target || attempts > 20) {
        clearInterval(timer);
        return;
      }
      if (String(window.location.href).indexOf(target) !== 0) {
        try { window.location.replace(target); } catch (e) {}
      } else {
        clearInterval(timer);
      }
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
