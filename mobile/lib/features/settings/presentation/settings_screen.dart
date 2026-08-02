import 'package:flutter/material.dart';

import '../../../core/audio/chess_sound_service.dart';
import '../../../core/app_preferences.dart';
import '../../../core/layout/responsive_page.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_button.dart';
import '../../../core/widgets/chessverse_card.dart';
import '../../legal/presentation/legal_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({this.onLogout, super.key});

  final Future<void> Function()? onLogout;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const AppPreferences _preferences = AppPreferences();
  bool _soundEnabled = true;
  bool _hintsEnabled = true;
  bool _coachEnabled = true;
  bool _animationsEnabled = true;
  bool _coordinatesEnabled = true;
  String _boardTheme = 'Royal Walnut';
  String _pieceStyle = 'Staunton 3D';
  String _appTheme = 'Dark premium';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<Object> values = await Future.wait<Object>(<Future<Object>>[
      _preferences.readBool('sound', fallback: true),
      _preferences.readBool('hints', fallback: true),
      _preferences.readBool('coach', fallback: true),
      _preferences.readBool('animations', fallback: true),
      _preferences.readBool('coordinates', fallback: true),
      _preferences.readString('boardTheme', fallback: 'Royal Walnut'),
      _preferences.readString('pieceStyle', fallback: 'Staunton 3D'),
      _preferences.readString('appTheme', fallback: 'Dark premium'),
    ]);
    if (!mounted) return;
    setState(() {
      _soundEnabled = values[0] as bool;
      _hintsEnabled = values[1] as bool;
      _coachEnabled = values[2] as bool;
      _animationsEnabled = values[3] as bool;
      _coordinatesEnabled = values[4] as bool;
      _boardTheme = values[5] as String;
      _pieceStyle = values[6] as String;
      _appTheme = values[7] as String;
      _loading = false;
    });
    ChessSoundService.instance.enabled = _soundEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ResponsivePage(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Game preferences',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  ChessVerseCard(
                    child: Column(
                      children: <Widget>[
                        _SettingSwitch(
                          icon: Icons.volume_up_rounded,
                          title: 'Sound effects',
                          subtitle:
                              'Move sounds, check alerts, and result effects',
                          value: _soundEnabled,
                          onChanged: (bool value) {
                            setState(() => _soundEnabled = value);
                            ChessSoundService.instance.enabled = value;
                            _preferences.writeBool('sound', value);
                          },
                        ),
                        const Divider(color: AppColors.border),
                        _SettingSwitch(
                          icon: Icons.lightbulb_rounded,
                          title: 'Move hints',
                          subtitle: 'Show legal move and daily challenge hints',
                          value: _hintsEnabled,
                          onChanged: (bool value) {
                            setState(() => _hintsEnabled = value);
                            _preferences.writeBool('hints', value);
                          },
                        ),
                        const Divider(color: AppColors.border),
                        _SettingSwitch(
                          icon: Icons.grid_4x4_rounded,
                          title: 'Show coordinates',
                          subtitle: 'Display a-h and 1-8 board labels',
                          value: _coordinatesEnabled,
                          onChanged: (bool value) {
                            setState(() => _coordinatesEnabled = value);
                            _preferences.writeBool('coordinates', value);
                          },
                        ),
                        const Divider(color: AppColors.border),
                        _SettingSwitch(
                          icon: Icons.psychology_alt_rounded,
                          title: 'AI coach',
                          subtitle: 'Explain moves and tactical ideas',
                          value: _coachEnabled,
                          onChanged: (bool value) {
                            setState(() => _coachEnabled = value);
                            _preferences.writeBool('coach', value);
                          },
                        ),
                        const Divider(color: AppColors.border),
                        _SettingSwitch(
                          icon: Icons.auto_awesome_rounded,
                          title: 'Animations',
                          subtitle: 'Board highlights and smooth transitions',
                          value: _animationsEnabled,
                          onChanged: (bool value) {
                            setState(() => _animationsEnabled = value);
                            _preferences.writeBool('animations', value);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Appearance',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  ChessVerseCard(
                    child: Column(
                      children: <Widget>[
                        _SettingRow(
                          icon: Icons.grid_view_rounded,
                          title: 'Board theme',
                          value: _boardTheme,
                          onTap: () => _choose(
                            title: 'Board theme',
                            values: const <String>[
                              'Royal Walnut',
                              'Jade Glass',
                              'Tournament',
                              'Marble',
                              'Sapphire',
                            ],
                            selected: _boardTheme,
                            onSelected: (String value) {
                              setState(() => _boardTheme = value);
                              _preferences.writeString('boardTheme', value);
                            },
                          ),
                        ),
                        const Divider(color: AppColors.border),
                        _SettingRow(
                          icon: Icons.extension_rounded,
                          title: 'Piece style',
                          value: _pieceStyle,
                          onTap: () => _choose(
                            title: 'Piece style',
                            values: const <String>[
                              'Staunton 3D',
                              'Classic',
                              'Modern',
                            ],
                            selected: _pieceStyle,
                            onSelected: (String value) {
                              setState(() => _pieceStyle = value);
                              _preferences.writeString('pieceStyle', value);
                            },
                          ),
                        ),
                        const Divider(color: AppColors.border),
                        _SettingRow(
                          icon: Icons.dark_mode_rounded,
                          title: 'App theme',
                          value: _appTheme,
                          onTap: () => _choose(
                            title: 'App theme',
                            values: const <String>[
                              'Dark premium',
                              'Midnight blue',
                              'Emerald',
                            ],
                            selected: _appTheme,
                            onSelected: (String value) {
                              setState(() => _appTheme = value);
                              _preferences.writeString('appTheme', value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Legal', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  ChessVerseCard(
                    child: Column(
                      children: <Widget>[
                        _ActionRow(
                          icon: Icons.privacy_tip_rounded,
                          title: 'Privacy Policy',
                          onTap: () =>
                              _openLegal(context, LegalPageType.privacy),
                        ),
                        const Divider(color: AppColors.border),
                        _ActionRow(
                          icon: Icons.description_rounded,
                          title: 'Terms of Service',
                          onTap: () => _openLegal(context, LegalPageType.terms),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ChessVerseButton(
                    label: 'Logout',
                    icon: Icons.logout_rounded,
                    onPressed: _logout,
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _logout() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('You can sign in again with the same account.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await widget.onLogout?.call();
  }

  Future<void> _choose({
    required String title,
    required List<String> values,
    required String selected,
    required ValueChanged<String> onSelected,
  }) async {
    final String? value = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: RadioGroup<String>(
          groupValue: selected,
          onChanged: (String? value) => Navigator.pop(context, value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(title: Text(title)),
              for (final String option in values)
                RadioListTile<String>(
                  value: option,
                  title: Text(option),
                ),
            ],
          ),
        ),
      ),
    );
    if (value != null) onSelected(value);
  }

  void _openLegal(BuildContext context, LegalPageType type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalScreen(type: type),
      ),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  const _SettingSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon, color: AppColors.accentGold),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow(
      {required this.icon,
      required this.title,
      required this.value,
      required this.onTap});

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.accentGold),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(value, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow(
      {required this.icon, required this.title, required this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.accentGold),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
