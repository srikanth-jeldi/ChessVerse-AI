import 'package:flutter/material.dart';

import '../../auth/data/auth_api.dart';
import '../../auth/data/auth_session_store.dart';

class DeviceSessionsScreen extends StatefulWidget {
  const DeviceSessionsScreen({super.key});

  @override
  State<DeviceSessionsScreen> createState() => _DeviceSessionsScreenState();
}

class _DeviceSessionsScreenState extends State<DeviceSessionsScreen> {
  static const AuthApi _api = AuthApi();
  static const AuthSessionStore _store = AuthSessionStore();
  StoredAuthSession? _session;
  List<Map<String, dynamic>> _devices = <Map<String, dynamic>>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final StoredAuthSession? session = await _store.read();
      if (session == null) {
        throw const AuthApiException('Sign in to manage devices.');
      }
      final List<Map<String, dynamic>> devices =
          await _api.sessions(session.token);
      if (!mounted) return;
      setState(() {
        _session = session;
        _devices = devices;
        _loading = false;
        _error = null;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _revoke(String id) async {
    final StoredAuthSession? session = _session;
    if (session == null) return;
    await _api.revokeSession(session.token, id);
    await _load();
  }

  Future<void> _logoutAll() async {
    final StoredAuthSession? session = _session;
    if (session == null) return;
    await _api.logoutAll(session.token);
    await _store.clearSession();
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Devices & sessions')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: <Widget>[
                      const Text(
                        'Signed-in devices',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      const Text('Remove any device you no longer recognize.'),
                      const SizedBox(height: 16),
                      for (final Map<String, dynamic> device in _devices)
                        Card(
                          child: ListTile(
                            leading: Icon(device['current'] == true
                                ? Icons.smartphone_rounded
                                : Icons.devices_rounded),
                            title: Text(device['deviceName'] as String? ??
                                'Unknown device'),
                            subtitle: Text(device['current'] == true
                                ? 'This device'
                                : 'Last active ${device['lastUsedAt'] ?? 'unknown'}'),
                            trailing: device['current'] == true
                                ? const Icon(Icons.verified_user_rounded)
                                : IconButton(
                                    tooltip: 'Sign out device',
                                    icon: const Icon(Icons.logout_rounded),
                                    onPressed: () =>
                                        _revoke(device['id'] as String),
                                  ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: _logoutAll,
                        icon: const Icon(Icons.phonelink_erase_rounded),
                        label: const Text('Sign out on all devices'),
                      ),
                    ],
                  ),
      );
}
