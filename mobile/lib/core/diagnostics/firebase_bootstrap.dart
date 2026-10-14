import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// All Firebase consumers wait for the same initialization, including when
/// push, analytics and diagnostics start concurrently after the first frame.
abstract final class FirebaseBootstrap {
  static Future<void>? _pending;

  static Future<void> ensureReady() => _pending ??= _initialize();

  static Future<void> _initialize() async {
    try {
      await Future<void>.sync(initializer);
    } on Object {
      _pending = null;
      rethrow;
    }
  }

  @visibleForTesting
  static Future<void> Function() initializer = _defaultInitialize;

  static Future<void> _defaultInitialize() async {
    if (Firebase.apps.isEmpty) await Firebase.initializeApp();
  }

  @visibleForTesting
  static void resetForTesting() {
    _pending = null;
    initializer = _defaultInitialize;
  }
}
