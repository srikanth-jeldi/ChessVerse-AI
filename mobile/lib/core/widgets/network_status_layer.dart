import 'package:flutter/material.dart';

import '../network/network_health_controller.dart';

class NetworkStatusLayer extends StatefulWidget {
  const NetworkStatusLayer({required this.child, super.key});

  final Widget child;

  @override
  State<NetworkStatusLayer> createState() => _NetworkStatusLayerState();
}

class _NetworkStatusLayerState extends State<NetworkStatusLayer> {
  final NetworkHealthController _controller = NetworkHealthController.instance;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_refresh);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final NetworkHealth health = _controller.health;
    return Stack(
      children: <Widget>[
        widget.child,
        if (health == NetworkHealth.offline || health == NetworkHealth.slow)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: _NetworkBanner(
                icon: health == NetworkHealth.offline
                    ? Icons.wifi_off_rounded
                    : Icons.network_check_rounded,
                message: health == NetworkHealth.offline
                    ? 'You are offline. Online features will resume automatically.'
                    : 'Connection is slow. Some actions may take longer.',
                color: health == NetworkHealth.offline
                    ? const Color(0xFFD94B5B)
                    : const Color(0xFFD99A2B),
                onRetry: _controller.checkNow,
              ),
            ),
          ),
        if (_controller.showApiUnavailableScreen)
          Positioned.fill(
            child: ColoredBox(
              color: const Color(0xF2071524),
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(Icons.cloud_off_rounded,
                              size: 68, color: Color(0xFFFFC857)),
                          const SizedBox(height: 20),
                          Text('ChessVerseAI server is unavailable',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 10),
                          const Text(
                            'Your local games and learning progress remain safe. Retry now or continue with offline features.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFFB8C7D6)),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: _controller.checkNow,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry connection'),
                          ),
                          TextButton(
                            onPressed: _controller.continueOffline,
                            child: const Text('Continue offline'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NetworkBanner extends StatelessWidget {
  const _NetworkBanner({
    required this.icon,
    required this.message,
    required this.color,
    required this.onRetry,
  });

  final IconData icon;
  final String message;
  final Color color;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Material(
        color: color,
        elevation: 12,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            children: <Widget>[
              Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
}
