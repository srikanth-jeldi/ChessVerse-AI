import 'package:flutter/material.dart';

import 'coin_balance_badge.dart';

/// Animates confirmed balance changes without covering the shop controls.
class AnimatedCoinRewardBalance extends StatefulWidget {
  const AnimatedCoinRewardBalance({required this.balance, super.key});

  final int balance;

  @override
  State<AnimatedCoinRewardBalance> createState() =>
      _AnimatedCoinRewardBalanceState();
}

class _AnimatedCoinRewardBalanceState extends State<AnimatedCoinRewardBalance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
    value: 1,
  );
  late int _from = widget.balance;
  int _gain = 0;

  @override
  void didUpdateWidget(AnimatedCoinRewardBalance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.balance == widget.balance) return;
    _from = oldWidget.balance;
    _gain = widget.balance - oldWidget.balance;
    if (_gain > 0 && !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward(from: 0);
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final double progress = _controller.value;
      final double countProgress = Curves.easeOutCubic.transform(
        (progress / 0.65).clamp(0.0, 1.0),
      );
      final int amount = _gain > 0
          ? (_from + _gain * countProgress).round()
          : widget.balance;
      final double opacity = progress < 0.65
          ? 1
          : ((1 - progress) / 0.35).clamp(0.0, 1.0);
      return Stack(
        alignment: Alignment.center,
        children: [
          // Reserve room so the reward never covers neighbouring buttons.
          Padding(
            padding: const EdgeInsets.only(top: 28),
            child: Transform.scale(
              scale: 1 + (_gain > 0 ? 0.06 * (1 - progress) : 0),
              child: CoinBalanceBadge(balance: amount),
            ),
          ),
          if (_gain > 0 && progress < 1)
            Positioned(
              top: 0,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.translate(
                      offset: Offset(0, 12 * (1 - progress)),
                      child: Text(
                        '+${formatCoinAmount(_gain)}',
                        key: const ValueKey('coin-reward-gain'),
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          color: Color(0xFFFFD66B),
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
