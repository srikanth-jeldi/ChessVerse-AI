import 'dart:async';

import 'package:flutter/material.dart';

import '../../auth/data/auth_session_store.dart';
import '../data/notification_api.dart';

class NotificationBellButton extends StatefulWidget {
  const NotificationBellButton(
      {required this.onPressed, this.filled = false, super.key});
  final VoidCallback onPressed;
  final bool filled;

  @override
  State<NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<NotificationBellButton> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final session = await const AuthSessionStore().read();
      if (session == null) return;
      final inbox = await const NotificationApi().load(session.token);
      NotificationBadgeState.unread.value = inbox.unreadCount;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
      valueListenable: NotificationBadgeState.unread,
      builder: (context, unread, _) =>
          Stack(clipBehavior: Clip.none, children: <Widget>[
            IconButton(
              tooltip: 'Notifications',
              onPressed: () {
                widget.onPressed();
                Future<void>.delayed(const Duration(milliseconds: 400), _load);
              },
              style: widget.filled
                  ? IconButton.styleFrom(
                      backgroundColor: const Color(0xFF102A40),
                      foregroundColor: const Color(0xFFD9E7F0))
                  : null,
              icon: const Icon(Icons.notifications_rounded),
            ),
            if (unread > 0)
              Positioned(
                  right: -2,
                  top: -3,
                  child: Container(
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFF4F67),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF061724), width: 2)),
                    alignment: Alignment.center,
                    child: Text(unread > 99 ? '99+' : '$unread',
                        style: const TextStyle(
                            fontSize: 9, fontWeight: FontWeight.w900)),
                  )),
          ]));
}
