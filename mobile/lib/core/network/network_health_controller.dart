import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../diagnostics/app_diagnostics.dart';

enum NetworkHealth { checking, online, slow, offline, apiUnavailable }

class NetworkHealthController extends ChangeNotifier {
  NetworkHealthController._();

  static final NetworkHealthController instance = NetworkHealthController._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _probeTimer;
  NetworkHealth _health = NetworkHealth.checking;
  bool _initialized = false;
  bool _checking = false;
  bool _apiUnavailableDismissed = false;
  Duration? _lastLatency;

  NetworkHealth get health => _health;
  Duration? get lastLatency => _lastLatency;
  bool get showApiUnavailableScreen =>
      _health == NetworkHealth.apiUnavailable && !_apiUnavailableDismissed;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _subscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivity,
      onError: (_) => unawaited(checkNow()),
    );
    await checkNow();
    _probeTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(checkNow()),
    );
  }

  Future<void> _handleConnectivity(List<ConnectivityResult> results) async {
    if (results.isEmpty ||
        results.every((item) => item == ConnectivityResult.none)) {
      _setHealth(NetworkHealth.offline);
      return;
    }
    await checkNow();
  }

  Future<void> checkNow() async {
    if (_checking) return;
    _checking = true;
    try {
      final List<ConnectivityResult> connectivity =
          await _connectivity.checkConnectivity();
      if (connectivity.isEmpty ||
          connectivity.every((item) => item == ConnectivityResult.none)) {
        _lastLatency = null;
        _setHealth(NetworkHealth.offline);
        return;
      }
      final Stopwatch watch = Stopwatch()..start();
      final http.Response response = await http
          .get(Uri.parse('${AppConfig.apiBaseUrl}/actuator/health/readiness'))
          .timeout(const Duration(seconds: 8));
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
      _lastLatency = const Duration(seconds: 8);
      _setHealth(NetworkHealth.slow);
    } on Object catch (error, stack) {
      _lastLatency = null;
      _setHealth(NetworkHealth.apiUnavailable);
      unawaited(AppDiagnostics.recordError(
        error,
        stack,
        reason: 'API health probe failed',
      ));
    } finally {
      _checking = false;
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
    _subscription?.cancel();
    _probeTimer?.cancel();
    super.dispose();
  }
}
