import 'package:flutter/material.dart';

Widget buildGoogleProviderButton(VoidCallback onPressed) {
  return SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.g_mobiledata_rounded),
      label: const Text('Continue with Google'),
    ),
  );
}
