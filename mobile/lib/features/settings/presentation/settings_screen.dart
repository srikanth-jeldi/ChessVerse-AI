import 'package:flutter/material.dart';

import '../../../core/audio/chess_sound_service.dart';
import '../../../core/layout/responsive_page.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_button.dart';
import '../../../core/widgets/chessverse_card.dart';
import '../../legal/presentation/legal_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _hintsEnabled = true;
  bool _coachEnabled = true;
  bool _animationsEnabled = true;
  bool _coordinatesEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: ResponsivePage(
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
                    subtitle: 'Move sounds, check alerts, and result effects',
                    value: _soundEnabled,
                    onChanged: (bool value) {
                      setState(() => _soundEnabled = value);
                      ChessSoundService.instance.enabled = value;
                    },
                  ),
                  const Divider(color: AppColors.border),
                  _SettingSwitch(
                    icon: Icons.lightbulb_rounded,
                    title: 'Move hints',
                    subtitle: 'Show legal move and daily challenge hints',
                    value: _hintsEnabled,
                    onChanged: (bool value) =>
                        setState(() => _hintsEnabled = value),
                  ),
                  const Divider(color: AppColors.border),
                  _SettingSwitch(
                    icon: Icons.grid_4x4_rounded,
                    title: 'Show coordinates',
                    subtitle: 'Display a-h and 1-8 board labels',
                    value: _coordinatesEnabled,
                    onChanged: (bool value) =>
                        setState(() => _coordinatesEnabled = value),
                  ),
                  const Divider(color: AppColors.border),
                  _SettingSwitch(
                    icon: Icons.psychology_alt_rounded,
                    title: 'AI coach',
                    subtitle: 'Explain moves and tactical ideas',
                    value: _coachEnabled,
                    onChanged: (bool value) =>
                        setState(() => _coachEnabled = value),
                  ),
                  const Divider(color: AppColors.border),
                  _SettingSwitch(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Animations',
                    subtitle: 'Board highlights and smooth transitions',
                    value: _animationsEnabled,
                    onChanged: (bool value) =>
                        setState(() => _animationsEnabled = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ChessVerseCard(
              child: Column(
                children: const <Widget>[
                  _SettingRow(
                    icon: Icons.grid_view_rounded,
                    title: 'Board theme',
                    value: 'Royal Walnut',
                  ),
                  Divider(color: AppColors.border),
                  _SettingRow(
                    icon: Icons.extension_rounded,
                    title: 'Piece style',
                    value: 'Staunton 3D',
                  ),
                  Divider(color: AppColors.border),
                  _SettingRow(
                    icon: Icons.dark_mode_rounded,
                    title: 'App theme',
                    value: 'Dark premium',
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
                    onTap: () => _openLegal(context, LegalPageType.privacy),
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
              label: 'Logout preview',
              icon: Icons.logout_rounded,
              onPressed: () => _showMessage(
                  context, 'Logout will be connected to real auth later.'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
      {required this.icon, required this.title, required this.value});

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.accentGold),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      trailing: Text(value, style: Theme.of(context).textTheme.bodySmall),
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
