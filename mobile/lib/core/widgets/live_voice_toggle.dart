import 'package:flutter/material.dart';

import '../app_ui_localizations.dart';

class LiveVoiceToggle extends StatelessWidget {
  const LiveVoiceToggle({
    super.key,
    required this.enabled,
    required this.onChanged,
  });
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF061527),
    borderRadius: BorderRadius.circular(14),
    child: SwitchListTile.adaptive(
      title: Text(uiText(context, 'Automatic voice coach')),
      subtitle: Text(
        uiText(
          context,
          'Short cloud voice tips after reviewed moves. Internet required.',
        ),
      ),
      value: enabled,
      onChanged: onChanged,
    ),
  );
}
