import 'dart:async';

import 'package:flutter/material.dart';

/// Keeps Android's transient surface-resize frames from exposing stretched UI.
///
/// The child continues to receive every constraint update immediately. Only a
/// solid, non-directional cover is shown while window metrics are changing, so
/// the settled portrait or landscape layout is never delayed.
class RotationSafeFrame extends StatefulWidget {
  const RotationSafeFrame({
    required this.child,
    this.color = const Color(0xFF0B1814),
    super.key,
  });

  final Widget child;
  final Color color;

  @override
  State<RotationSafeFrame> createState() => _RotationSafeFrameState();
}

class _RotationSafeFrameState extends State<RotationSafeFrame>
    with WidgetsBindingObserver {
  Timer? _settleTimer;
  bool _coverVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    _settleTimer?.cancel();
    if (!_coverVisible && mounted) {
      setState(() => _coverVisible = true);
    }
    _settleTimer = Timer(const Duration(milliseconds: 320), () {
      if (mounted) {
        setState(() => _coverVisible = false);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        widget.child,
        if (_coverVisible)
          Positioned.fill(
            child: ColoredBox(
              color: widget.color,
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Color(0xFFD6A84F),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
