import 'package:flutter/material.dart';

import '../app_ui_localizations.dart';

class LiveVoiceToggle extends StatelessWidget {
  const LiveVoiceToggle({
    super.key,
    required this.enabled,
    required this.onChanged,
    this.onExpand,
    this.expanded = false,
  });
  final bool enabled;
  final VoidCallback? onExpand;
  final bool expanded;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF061527),
    borderRadius: BorderRadius.circular(14),
    child: SwitchListTile.adaptive(
      title: Text(uiText(context, 'Automatic voice coach')),
      dense: !enabled,
      secondary: !enabled && onExpand != null ? IconButton(
        key: const ValueKey('toggle-text-coach'),
        tooltip: uiText(context, 'AI Coach'),
        onPressed: onExpand,
        icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
      ) : null,
      subtitle: !enabled ? null : Text(
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
