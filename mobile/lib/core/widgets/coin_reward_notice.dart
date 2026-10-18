import 'package:flutter/material.dart';

/// Persistent feedback beside the video button, clear of bottom ads/insets.
class CoinRewardNotice extends StatelessWidget {
  const CoinRewardNotice({required this.message, super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 480),
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            message.startsWith('+')
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded,
            color: Color(0xFFFFD66B),
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFE3EDF3),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
