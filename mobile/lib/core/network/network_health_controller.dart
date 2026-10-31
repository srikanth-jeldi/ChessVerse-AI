import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../diagnostics/app_diagnostics.dart';
import 'transport_error.dart';

enum NetworkHealth { checking, online, slow, offline, apiUnavailable }

class NetworkHealthController extends ChangeNotifier
    with WidgetsBindingObserver {
  NetworkHealthController._();

  @visibleForTesting
  NetworkHealthController.forTesting(NetworkHealth health) : _health = health;

  static final NetworkHealthController instance = NetworkHealthController._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _probeTimer;
  NetworkHealth _health = NetworkHealth.checking;
  bool _initialized = false;
  bool _checking = false;
  bool _apiUnavailableDismissed = false;
  Duration? _lastLatency;
  bool _disposed = false;
  bool _background = false;
  int _probeEpoch = 0;
  http.Client? _activeClient;

  NetworkHealth get health => _health;
  Duration? get lastLatency => _lastLatency;
  bool get showApiUnavailableScreen =>
      _health == NetworkHealth.apiUnavailable && !_apiUnavailableDismissed;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _background = state != null && state != AppLifecycleState.resumed;
    _subscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivity,
      onError: (_) => unawaited(checkNow()),
    );
    await checkNow();
    if (_disposed) return;
    _probeTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(checkNow()),
    );
  }

  Future<void> _handleConnectivity(List<ConnectivityResult> results) async {
    if (_disposed || _background) return;
    if (results.isEmpty ||
        results.every((item) => item == ConnectivityResult.none)) {
      _setHealth(NetworkHealth.offline);
      return;
    }
    await checkNow();
  }

  Future<void> checkNow() async {
    if (_checking || _disposed || _background) return;
    _checking = true;
    final epoch = ++_probeEpoch;
    http.Client? client;
    bool current() => !_disposed && !_background && epoch == _probeEpoch;
    try {
      final List<ConnectivityResult> connectivity = await _connectivity
          .checkConnectivity()
          .timeout(const Duration(seconds: 2));
      if (!current()) return;
      if (connectivity.isEmpty ||
          connectivity.every((item) => item == ConnectivityResult.none)) {
        _lastLatency = null;
        _setHealth(NetworkHealth.offline);
        return;
      }
      final Stopwatch watch = Stopwatch()..start();
      client = http.Client();
      _activeClient = client;
      final http.Response response = await client
          // Actuator is intentionally outside the backend's browser CORS
          // mapping. Use the public API health route so Flutter Web can read
          // the response instead of treating a healthy server as unavailable.
          .get(Uri.parse('${AppConfig.apiBaseUrl}/api/v1/health'))
          .timeout(const Duration(seconds: 8));
      if (!current()) return;
      watch.stop();
      _lastLatency = watch.elapsed;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _setHealth(NetworkHealth.apiUnavailable);
      } else if (watch.elapsed >= const Duration(milliseconds: 2500)) {
        _setHealth(NetworkHealth.slow);
      } else {
        _setHealth(NetworkHealth.online);
      }
    } on TimeoutException {
      if (!current()) return;
      _lastLatency = const Duration(seconds: 8);
      _setHealth(NetworkHealth.slow);
    } on http.ClientException catch (error) {
      if (!current()) return;
      // An interface (Wi-Fi/mobile) can exist without a usable connection.
      // A failed transport is not an HTTP response proving a server outage.
      // Keep local play available and let the existing connectivity/periodic
      // probes restore online status. Preserve a breadcrumb for diagnosis.
      _lastLatency = null;
      _setHealth(NetworkHealth.offline);
      AppDiagnostics.log('network_probe_transport_unavailable', {
        'type': error.runtimeType.toString(),
      });
    } on Object catch (error, stack) {
      if (!current()) return;
      _lastLatency = null;
      // A rejected certificate must never be bypassed. Keep local gameplay
      // available, preserve TLS diagnostics, and retry a verified connection.
      if (isNativeTransportError(error)) {
        _setHealth(NetworkHealth.offline);
        AppDiagnostics.log('network_probe_transport_unavailable', {
          'type': error.runtimeType.toString(),
        });
        if (!isTlsTransportError(error)) return;
      } else {
        _setHealth(NetworkHealth.apiUnavailable);
      }
      unawaited(
        AppDiagnostics.recordError(
          error,
          stack,
          reason: 'API health probe failed',
        ),
      );
    } finally {
      client?.close();
      if (identical(_activeClient, client)) _activeClient = null;
      if (epoch == _probeEpoch) _checking = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _background = state != AppLifecycleState.resumed;
    if (_background) {
      ++_probeEpoch;
      _checking = false;
      _activeClient?.close();
      _activeClient = null;
    } else if (_initialized && !_disposed) {
      unawaited(checkNow());
    }
  }

  void continueOffline() {
    _apiUnavailableDismissed = true;
    notifyListeners();
  }

  void _setHealth(NetworkHealth value) {
    if (value != NetworkHealth.apiUnavailable) {
      _apiUnavailableDismissed = false;
    }
    if (_health == value) return;
    _health = value;
    AppDiagnostics.log('network_health', <String, Object?>{
      'status': value.name,
      'latencyMs': _lastLatency?.inMilliseconds,
    });
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_probeEpoch;
    if (_initialized) WidgetsBinding.instance.removeObserver(this);
    _activeClient?.close();
    _activeClient = null;
    _subscription?.cancel();
    _probeTimer?.cancel();
    super.dispose();
  }
}
