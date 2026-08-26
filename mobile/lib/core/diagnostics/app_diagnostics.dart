import 'dart:async';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Privacy-safe diagnostics shared by Crashlytics and Help & Support.
abstract final class AppDiagnostics {
  static const int _maximumEntries = 80;
  static final List<String> _entries = <String>[];
  static bool _crashlyticsReady = false;

  static Future<void> initialize() async {
    if (!kIsWeb) {
      try {
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(!kDebugMode);
        _crashlyticsReady = true;
      } on Object {
        _crashlyticsReady = false;
      }
    }

    final FlutterExceptionHandler? previousFlutterHandler =
        FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      previousFlutterHandler?.call(details);
      unawaited(recordError(
        details.exception,
        details.stack,
        reason: 'Flutter framework error',
        fatal: true,
      ));
    };
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      unawaited(recordError(
        error,
        stack,
        reason: 'Uncaught platform error',
        fatal: true,
      ));
      return true;
    };
    log('diagnostics_initialized');
  }

  static void log(String event, [Map<String, Object?> data = const {}]) {
    final String fields = data.entries
        .map((entry) => '${entry.key}=${redact('${entry.value}')}')
        .join(' ');
    final String line = '${DateTime.now().toUtc().toIso8601String()} '
        '${redact(event)}${fields.isEmpty ? '' : ' $fields'}';
    _entries.add(line);
    if (_entries.length > _maximumEntries) {
      _entries.removeRange(0, _entries.length - _maximumEntries);
    }
    if (_crashlyticsReady) {
      unawaited(FirebaseCrashlytics.instance.log(line));
    }
  }

  static Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required String reason,
    bool fatal = false,
  }) async {
    final String safeError = redact(error.toString());
    log('error', <String, Object?>{'reason': reason, 'message': safeError});
    if (!_crashlyticsReady) return;
    await FirebaseCrashlytics.instance.recordError(
      safeError,
      stack,
      reason: redact(reason),
      fatal: fatal,
    );
  }

  static String redact(String value) {
    String safe = value;
    safe = safe.replaceAll(
      RegExp(
        r'(authorization\s*[:=]\s*bearer\s+)[^\s,;]+',
        caseSensitive: false,
      ),
      r'$1[REDACTED]',
    );
    safe = safe.replaceAll(
      RegExp(
        r'''(password|passcode|secret|access[_-]?token|id[_-]?token|refresh[_-]?token|client[_-]?token|api[_-]?key)\s*[:=]\s*["']?[^\s,"'}&]+''',
        caseSensitive: false,
      ),
      r'$1=[REDACTED]',
    );
    safe = safe.replaceAll(
      RegExp(r'\beyJ[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+\b'),
      '[REDACTED_TOKEN]',
    );
    safe = safe.replaceAllMapped(
      RegExp(r'\b([A-Z0-9._%+-]{1,64})@([A-Z0-9.-]+\.[A-Z]{2,})\b',
          caseSensitive: false),
      (Match match) {
        final String local = match.group(1)!;
        return '${local.substring(0, 1)}***@${match.group(2)}';
      },
    );
    return safe;
  }

  static Future<String> buildReport() async {
    final PackageInfo package = await PackageInfo.fromPlatform();
    final BaseDeviceInfo info = await DeviceInfoPlugin().deviceInfo;
    final Map<String, dynamic> device = info.data;
    final String platform = kIsWeb ? 'web' : defaultTargetPlatform.name;
    final String model = _firstNonEmpty(<Object?>[
      device['model'],
      device['product'],
      device['computerName'],
      device['browserName'],
    ]);
    final String os = _firstNonEmpty(<Object?>[
      device['version'] is Map ? (device['version'] as Map)['release'] : null,
      device['systemVersion'],
      device['osRelease'],
      device['platform'],
    ]);
    return <String>[
      'ChessVerseAI diagnostic report',
      'Generated: ${DateTime.now().toUtc().toIso8601String()}',
      'App: ${package.version} (${package.buildNumber})',
      'Platform: $platform',
      if (model.isNotEmpty) 'Device model: ${redact(model)}',
      if (os.isNotEmpty) 'OS: ${redact(os)}',
      'Crash reporting: ${_crashlyticsReady ? 'enabled' : 'unavailable'}',
      '',
      'Recent safe events:',
      if (_entries.isEmpty) 'No diagnostic events recorded.' else ..._entries,
    ].join('\n');
  }

  static String _firstNonEmpty(List<Object?> values) {
    for (final Object? value in values) {
      final String candidate = value?.toString().trim() ?? '';
      if (candidate.isNotEmpty && candidate != 'null') return candidate;
    }
    return '';
  }
}
