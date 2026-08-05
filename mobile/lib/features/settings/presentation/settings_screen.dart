import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../core/audio/chess_sound_service.dart';
import '../../../core/app_preferences.dart';
import '../../../core/layout/responsive_page.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_card.dart';
import '../../../core/widgets/desktop_app_sidebar.dart';
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
    final Size viewport = MediaQuery.sizeOf(context);
    final bool tablet = viewport.shortestSide >= 600;
    final bool wide = (kIsWeb || tablet) && viewport.width >= 700;
    final Widget page = Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: wide ? 92 : 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('SETTINGS',
                style:
                    TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.w900)),
            if (wide) ...<Widget>[
              const SizedBox(height: 4),
              const Text(
                'Customize your game experience',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ],
          ],
        ),
        backgroundColor: const Color(0xE6071727),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ResponsivePage(
              maxWidth: wide ? 1240 : null,
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool desktop = constraints.maxWidth >= 620;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const _SettingsSectionTitle(
                        icon: Icons.workspace_premium_rounded,
                        label: 'GAME PREFERENCES',
                      ),
                      const SizedBox(height: 12),
                      ChessVerseCard(
                        padding: EdgeInsets.symmetric(
                          horizontal: desktop ? 26 : 16,
                          vertical: desktop ? 14 : 8,
                        ),
                        child: desktop
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(
                                    child: Column(
                                      children: <Widget>[
                                        _soundSwitch(),
                                        const Divider(color: AppColors.border),
                                        _hintsSwitch(),
                                        const Divider(color: AppColors.border),
                                        _coordinatesSwitch(),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  const SizedBox(
                                    height: 255,
                                    child: VerticalDivider(
                                        color: AppColors.border),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: Column(
                                      children: <Widget>[
                                        _coachSwitch(),
                                        const Divider(color: AppColors.border),
                                        _animationsSwitch(),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: <Widget>[
                                  _soundSwitch(),
                                  const Divider(color: AppColors.border),
                                  _hintsSwitch(),
                                  const Divider(color: AppColors.border),
                                  _coordinatesSwitch(),
                                  const Divider(color: AppColors.border),
                                  _coachSwitch(),
                                  const Divider(color: AppColors.border),
                                  _animationsSwitch(),
                                ],
                              ),
                      ),
                      const SizedBox(height: 18),
                      const _SettingsSectionTitle(
                        icon: Icons.palette_rounded,
                        label: 'APPEARANCE',
                      ),
                      const SizedBox(height: 12),
                      ChessVerseCard(
                        padding: EdgeInsets.symmetric(
                          horizontal: desktop ? 26 : 16,
                          vertical: desktop ? 10 : 8,
                        ),
                        child: Flex(
                          direction: desktop ? Axis.horizontal : Axis.vertical,
                          children: <Widget>[
                            _AdaptiveFlexItem(
                              expanded: desktop,
                              child: _SettingRow(
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
                                    _preferences.writeString(
                                        'boardTheme', value);
                                  },
                                ),
                              ),
                            ),
                            if (desktop)
                              const SizedBox(
                                height: 76,
                                child: VerticalDivider(color: AppColors.border),
                              )
                            else
                              const Divider(color: AppColors.border),
                            _AdaptiveFlexItem(
                              expanded: desktop,
                              child: _SettingRow(
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
                                    _preferences.writeString(
                                        'pieceStyle', value);
                                  },
                                ),
                              ),
                            ),
                            if (desktop)
                              const SizedBox(
                                height: 76,
                                child: VerticalDivider(color: AppColors.border),
                              )
                            else
                              const Divider(color: AppColors.border),
                            _AdaptiveFlexItem(
                              expanded: desktop,
                              child: _SettingRow(
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
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _SettingsSectionTitle(
                        icon: Icons.shield_outlined,
                        label: 'LEGAL',
                      ),
                      const SizedBox(height: 12),
                      ChessVerseCard(
                        padding: EdgeInsets.symmetric(
                          horizontal: desktop ? 26 : 16,
                          vertical: desktop ? 8 : 6,
                        ),
                        child: Flex(
                          direction: desktop ? Axis.horizontal : Axis.vertical,
                          children: <Widget>[
                            _AdaptiveFlexItem(
                              expanded: desktop,
                              child: _ActionRow(
                                icon: Icons.privacy_tip_rounded,
                                title: 'Privacy Policy',
                                onTap: () =>
                                    _openLegal(context, LegalPageType.privacy),
                              ),
                            ),
                            if (desktop)
                              const SizedBox(
                                height: 68,
                                child: VerticalDivider(color: AppColors.border),
                              )
                            else
                              const Divider(color: AppColors.border),
                            _AdaptiveFlexItem(
                              expanded: desktop,
                              child: _ActionRow(
                                icon: Icons.description_rounded,
                                title: 'Terms of Service',
                                onTap: () =>
                                    _openLegal(context, LegalPageType.terms),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            colors: <Color>[
                              Color(0xFF7D2CF2),
                              Color(0xFF5122A8)
                            ],
                          ),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(color: Color(0x557D2CF2), blurRadius: 20),
                          ],
                        ),
                        child: Material(
                          type: MaterialType.transparency,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: _logout,
                            child: const SizedBox(
                              height: 58,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    'Logout',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Icon(Icons.logout_rounded,
                                      color: Colors.white),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
    if (!wide) return page;
    return Row(
      children: <Widget>[
        DesktopAppSidebar(
          selected: 'Settings',
          onHome: () => Navigator.maybePop(context),
          onSettings: () {},
        ),
        Expanded(child: page),
      ],
    );
  }

  Widget _soundSwitch() => _SettingSwitch(
        icon: Icons.volume_up_rounded,
        title: 'Sound effects',
        subtitle: 'Move sounds, check alerts, and result effects',
        value: _soundEnabled,
        onChanged: (bool value) {
          setState(() => _soundEnabled = value);
          ChessSoundService.instance.enabled = value;
          _preferences.writeBool('sound', value);
        },
      );

  Widget _hintsSwitch() => _SettingSwitch(
        icon: Icons.lightbulb_rounded,
        title: 'Move hints',
        subtitle: 'Show legal move and daily challenge hints',
        value: _hintsEnabled,
        onChanged: (bool value) {
          setState(() => _hintsEnabled = value);
          _preferences.writeBool('hints', value);
        },
      );

  Widget _coordinatesSwitch() => _SettingSwitch(
        icon: Icons.grid_4x4_rounded,
        title: 'Show coordinates',
        subtitle: 'Display a-h and 1-8 board labels',
        value: _coordinatesEnabled,
        onChanged: (bool value) {
          setState(() => _coordinatesEnabled = value);
          _preferences.writeBool('coordinates', value);
        },
      );

  Widget _coachSwitch() => _SettingSwitch(
        icon: Icons.psychology_alt_rounded,
        title: 'AI coach',
        subtitle: 'Explain moves and tactical ideas',
        value: _coachEnabled,
        onChanged: (bool value) {
          setState(() => _coachEnabled = value);
          _preferences.writeBool('coach', value);
        },
      );

  Widget _animationsSwitch() => _SettingSwitch(
        icon: Icons.auto_awesome_rounded,
        title: 'Animations',
        subtitle: 'Board highlights and smooth transitions',
        value: _animationsEnabled,
        onChanged: (bool value) {
          setState(() => _animationsEnabled = value);
          _preferences.writeBool('animations', value);
        },
      );

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
      contentPadding: const EdgeInsets.symmetric(vertical: 5),
      secondary: _GoldIcon(icon),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      value: value,
      activeTrackColor: AppColors.accentGold,
      activeThumbColor: const Color(0xFF05070A),
      onChanged: onChanged,
    );
  }
}

class _AdaptiveFlexItem extends StatelessWidget {
  const _AdaptiveFlexItem({required this.expanded, required this.child});

  final bool expanded;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      expanded ? Expanded(child: child) : child;
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
      leading: _GoldIcon(icon),
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
      leading: _GoldIcon(icon),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Expanded(child: Divider(color: Color(0x557F642F))),
          const SizedBox(width: 10),
          Icon(icon, color: AppColors.accentGold, size: 23),
          const SizedBox(width: 9),
          Text(label,
              style: const TextStyle(
                  color: AppColors.accentGold,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w900)),
          const SizedBox(width: 10),
          const Expanded(child: Divider(color: Color(0x557F642F))),
        ],
      );
}

class _GoldIcon extends StatelessWidget {
  const _GoldIcon(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF071827),
          border: Border.all(color: const Color(0xFF19354A)),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x332D9CF0), blurRadius: 12),
          ],
        ),
        child: Icon(icon, color: AppColors.accentGold, size: 25),
      );
}
