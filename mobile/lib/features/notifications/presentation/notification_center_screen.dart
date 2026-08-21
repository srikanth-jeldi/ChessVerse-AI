import 'package:flutter/material.dart';

import '../../auth/data/auth_session_store.dart';
import '../data/notification_api.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({this.onAction, super.key});
  final Future<void> Function(PlayerNotificationDto item)? onAction;
  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  static const NotificationApi _api = NotificationApi();
  StoredAuthSession? _session;
  NotificationInboxDto? _inbox;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final StoredAuthSession? session = await const AuthSessionStore().read();
      if (session == null) throw const NotificationException('Sign in to view notifications.');
      final NotificationInboxDto value = await _api.load(session.token);
      if (mounted) setState(() { _session = session; _inbox = value; _error = null; });
    } on NotificationException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _read(PlayerNotificationDto item) async {
    if (_session == null) return;
    if (!item.read) {
      final value = await _api.read(_session!.token, item.id);
      if (mounted) setState(() => _inbox = value);
    }
    if (widget.onAction != null) {
      if (mounted) Navigator.of(context).pop();
      await widget.onAction!(item);
    }
  }

  Future<void> _readAll() async {
    if (_session == null) return;
    final value = await _api.readAll(_session!.token);
    if (mounted) setState(() => _inbox = value);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF020D16),
    appBar: AppBar(
      title: const Text('NOTIFICATIONS', style: TextStyle(fontWeight: FontWeight.w900)),
      actions: <Widget>[if ((_inbox?.unreadCount ?? 0) > 0) TextButton(onPressed: _readAll, child: const Text('Mark all read'))],
    ),
    body: _body(),
  );

  Widget _body() {
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
      const Icon(Icons.cloud_off_rounded, size: 48), const SizedBox(height: 12), Text(_error!),
      const SizedBox(height: 12), FilledButton(onPressed: _load, child: const Text('Retry')),
      ]));
    }
    if (_inbox == null) return const Center(child: CircularProgressIndicator());
    if (_inbox!.notifications.isEmpty) {
      return RefreshIndicator(onRefresh: _load, child: ListView(children: const <Widget>[
      SizedBox(height: 180), Icon(Icons.notifications_none_rounded, size: 58, color: Color(0xFF607B8B)),
      SizedBox(height: 12), Text('You are all caught up.', textAlign: TextAlign.center),
      ]));
    }
    return RefreshIndicator(onRefresh: _load, child: ListView.builder(
      padding: const EdgeInsets.all(14), itemCount: _inbox!.notifications.length,
      itemBuilder: (context, index) {
        final item = _inbox!.notifications[index];
        return Card(color: item.read ? const Color(0xFF0A1C2B) : const Color(0xFF0A343B), child: ListTile(
          onTap: () => _read(item),
          leading: CircleAvatar(backgroundColor: const Color(0xFF153649), child: Icon(_icon(item.type), color: item.read ? const Color(0xFF9CB0BC) : const Color(0xFF5FE3CE))),
          title: Text(item.title, style: TextStyle(fontWeight: item.read ? FontWeight.w600 : FontWeight.w900)),
          subtitle: Text('${item.body}\n${_time(item.createdAt)}'), isThreeLine: true,
          trailing: item.read ? null : const CircleAvatar(radius: 5, backgroundColor: Color(0xFFE6B44F)),
        ));
      },
    ));
  }

  IconData _icon(String type) {
    if (type.contains('CHALLENGE')) return Icons.sports_esports_rounded;
    if (type.contains('FRIEND')) return Icons.person_add_alt_1_rounded;
    if (type.contains('MESSAGE')) return Icons.chat_bubble_rounded;
    if (type.contains('TOURNAMENT')) return Icons.emoji_events_rounded;
    if (type.contains('CLUB')) return Icons.shield_rounded;
    return Icons.auto_awesome_rounded;
  }

  String _time(DateTime value) {
    final difference = DateTime.now().difference(value.toLocal());
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} min ago';
    if (difference.inDays < 1) return '${difference.inHours} hr ago';
    return '${difference.inDays} days ago';
  }
}
