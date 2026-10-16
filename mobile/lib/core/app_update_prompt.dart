import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_language.dart';
import 'app_preferences.dart';
import 'app_update_strings.dart';

class AppUpdatePrompt {
  AppUpdatePrompt({
    Future<int?> Function()? check,
    Future<bool> Function()? openStore,
    DateTime Function()? now,
    this.timeout = const Duration(seconds: 5),
  }) : _check = check ?? _checkPlay,
       _openStore = openStore ?? _openPlayStore,
       _now = now ?? DateTime.now;

  static const _channel = MethodChannel('com.epitomehub.chessverse/app_update');
  static const _preferences = AppPreferences();
  static const reminderKey = 'appUpdatePromptAt';
  final Future<int?> Function() _check;
  final Future<bool> Function() _openStore;
  final DateTime Function() _now;
  final Duration timeout;
  bool _started = false;

  static Future<int?> _checkPlay() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    return _channel.invokeMethod<int>('availableVersionCode');
  }

  static Future<bool> _openPlayStore() => launchUrl(
    Uri.parse(
      'https://play.google.com/store/apps/details?id=com.epitomehub.chessverse',
    ),
    mode: LaunchMode.externalApplication,
  );

  Future<void> maybeShow(
    BuildContext context, {
    required bool Function() canShow,
  }) async {
    if (_started) return;
    _started = true;
    try {
      final last = DateTime.tryParse(
        await _preferences
            .readString(reminderKey, fallback: '')
            .timeout(timeout),
      );
      final now = _now().toUtc();
      if (last != null && now.difference(last) < const Duration(days: 1)) {
        return;
      }
      final version = await _check().timeout(timeout);
      if (version == null || version <= 0 || !context.mounted || !canShow()) {
        return;
      }
      if (ModalRoute.of(context)?.isCurrent != true ||
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        return;
      }
      final language = AppLanguageController.resolveCode(
        AppLanguageController.effectiveLanguageChanges.value ?? 'system',
      );
      final words = appUpdateStrings(language);
      // Persist before showing, so dismissal/back and app restarts don't nag.
      await _preferences
          .writeString(reminderKey, now.toIso8601String())
          .timeout(timeout);
      if (!context.mounted ||
          !canShow() ||
          ModalRoute.of(context)?.isCurrent != true ||
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        return;
      }
      final update = await showDialog<bool>(
        context: context,
        builder: (context) => Directionality(
          textDirection: const {'ar', 'fa', 'he', 'ur'}.contains(language)
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: AlertDialog(
            scrollable: true,
            key: const ValueKey('app-update-dialog'),
            icon: const Icon(Icons.system_update_rounded),
            title: Text(words[0]),
            content: Text(words[1]),
            actions: [
              TextButton(
                key: const ValueKey('app-update-later'),
                onPressed: () => Navigator.pop(context, false),
                child: Text(words[3]),
              ),
              FilledButton(
                key: const ValueKey('app-update-now'),
                onPressed: () => Navigator.pop(context, true),
                child: Text(words[2]),
              ),
            ],
          ),
        ),
      );
      if (update != true) return;
      bool opened = false;
      try {
        opened = await _openStore().timeout(timeout, onTimeout: () => false);
      } on Object {
        /* Show a non-blocking message below. */
      }
      if (!opened && context.mounted && canShow()) {
        ScaffoldMessenger.maybeOf(context)
            ?.showSnackBar(SnackBar(content: Text(words[4])));
      }
    } on Object {
      // Update checks, storage errors and missing plugins never block startup.
    }
  }
}
