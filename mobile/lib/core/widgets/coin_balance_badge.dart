import 'package:flutter/material.dart';

class CoinBalanceBadge extends StatelessWidget {
  const CoinBalanceBadge({
    required this.balance,
    this.expandedLabel = false,
    this.compact = false,
    super.key,
  });

  final int? balance;
  final bool expandedLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final String amount = balance == null ? '—' : formatCoinAmount(balance!);
    return Semantics(
      label: balance == null ? 'Coin balance loading' : 'Your coins $amount',
      child: Container(
        key: const ValueKey<String>('global-coin-balance'),
        constraints: BoxConstraints(
          minWidth: expandedLabel ? 152 : (compact ? 68 : 82),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: expandedLabel ? 16 : (compact ? 10 : 12),
          vertical: expandedLabel ? 10 : 8,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFF17334B), Color(0xFF071A2B)],
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE7B54D), width: 1.2),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x33E7B54D),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: expandedLabel ? 25 : 22,
              height: expandedLabel ? 25 : 22,
              decoration: const BoxDecoration(
                color: Color(0xFFFFC84D),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.attach_money_rounded,
                color: const Color(0xFF092037),
                size: expandedLabel ? 18 : 16,
              ),
            ),
            SizedBox(width: expandedLabel ? 8 : 6),
            if (expandedLabel)
              const Text(
                'Your Coins: ',
                style: TextStyle(
                  color: Color(0xFFDCE8F0),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            Text(
              amount,
              maxLines: 1,
              style: TextStyle(
                color: const Color(0xFFFFD66B),
                fontSize: expandedLabel ? 15 : 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String formatCoinAmount(int value) {
  final String digits = value.clamp(0, 999999999).toString();
  return digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
}
