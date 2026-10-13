import 'package:flutter/material.dart';

/// Persistent feedback beside the video button, clear of bottom ads/insets.
class CoinRewardNotice extends StatelessWidget {
  const CoinRewardNotice({required this.message, super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      width: 330,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF102B3B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x805DE9D3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFFFD66B),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFE3EDF3),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
