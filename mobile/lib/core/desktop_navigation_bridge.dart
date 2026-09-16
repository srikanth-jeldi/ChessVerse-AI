import 'package:flutter/material.dart';

/// Bridges full-screen desktop routes back to the authenticated app shell.
///
/// Primary destinations use indexes 0-5. Six opens My Games and seven opens
/// the Collection/rewards centre.
abstract final class DesktopNavigationBridge {
  static final ValueNotifier<int?> request = ValueNotifier<int?>(null);
  static final ValueNotifier<int?> coinBalance = ValueNotifier<int?>(null);

  static void open(BuildContext context, int destination) {
    Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
    request.value = destination;
  }
}
