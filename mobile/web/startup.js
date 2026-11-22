// Keep this script readable by older browsers so they can show the help
// screen even when they cannot run the Flutter runtime.
(function () {
  var splash = document.getElementById('splash');
  var help = document.getElementById('startup-help');
  var message = document.getElementById('startup-message');
  var retry = document.getElementById('startup-retry');
  var timer;
  var ready = false;

  function showHelp(text, canRetry) {
    if (ready) return;
    window.clearTimeout(timer);
    splash.hidden = true;
    message.textContent = text;
    retry.hidden = !canRetry;
    help.hidden = false;
  }

  window.chessverseStartupFailed = function () {
    showHelp('The game could not start. Check your connection and try again.', true);
  };
  retry.onclick = function () { window.location.reload(); };

  var wasm = window.WebAssembly;
  if (typeof window.Promise !== 'function' ||
      typeof window.fetch !== 'function' ||
      !wasm || typeof wasm.instantiate !== 'function') {
    showHelp('Update your browser to play ChessVerseAI. Open the site in Chrome, Edge, Firefox or Safari.', false);
    return;
  }

  window.addEventListener('flutter-first-frame', function () {
    ready = true;
    window.clearTimeout(timer);
    splash.hidden = true;
    help.hidden = true;
    document.body.style.background = 'transparent';
  });
  timer = window.setTimeout(function () {
    showHelp('The game is taking longer than expected. You can wait or try again.', true);
  }, 30000);

  var script = document.createElement('script');
  script.src = 'flutter_bootstrap.js?v=20261122-daily3';
  script.async = true;
  script.onerror = window.chessverseStartupFailed;
  document.head.appendChild(script);
}());
