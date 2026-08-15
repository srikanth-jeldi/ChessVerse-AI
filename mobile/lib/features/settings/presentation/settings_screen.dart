import 'package:flutter/material.dart';

import '../../../core/audio/chess_sound_service.dart';
import '../../../core/app_preferences.dart';
import '../../../core/chess_piece_appearance.dart';
import '../../../core/layout/app_breakpoints.dart';
import '../../../core/layout/responsive_page.dart';
import '../../../core/notifications/daily_reminder_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_card.dart';
import '../../../core/widgets/desktop_app_sidebar.dart';
import '../../legal/presentation/legal_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    this.onLogout,
    this.onDeleteAccount,
    this.onHome,
    this.onPlay,
    this.onPuzzles,
    this.onLearn,
    this.onProfile,
    super.key,
  });

  final Future<void> Function()? onLogout;
  final Future<void> Function()? onDeleteAccount;
  final VoidCallback? onHome;
  final VoidCallback? onPlay;
  final VoidCallback? onPuzzles;
  final VoidCallback? onLearn;
  final VoidCallback? onProfile;

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
  bool _dailyReminderEnabled = false;
  bool _deletingAccount = false;
  String _boardTheme = 'Royal Walnut';
  String _pieceStyle = 'Premium 3D';
  String _pieceSize = 'Extra Large';
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
      _preferences.readBool('dailyReminder', fallback: false),
      _preferences.readString('boardTheme', fallback: 'Royal Walnut'),
      _preferences.readString('pieceStyle', fallback: 'Premium 3D'),
      _preferences.readString('pieceSize', fallback: 'Extra Large'),
      _preferences.readString('appTheme', fallback: 'Dark premium'),
    ]);
    if (!mounted) return;
    setState(() {
      _soundEnabled = values[0] as bool;
      _hintsEnabled = values[1] as bool;
      _coachEnabled = values[2] as bool;
      _animationsEnabled = values[3] as bool;
      _coordinatesEnabled = values[4] as bool;
      _dailyReminderEnabled = values[5] as bool;
      _boardTheme = values[6] as String;
      _pieceStyle = ChessPieceAppearanceController.styleLabel(
        ChessPieceAppearanceController.styleFromLabel(values[7] as String),
      );
      _pieceSize = values[8] as String;
      _appTheme = values[9] as String;
      _loading = false;
    });
    ChessPieceAppearanceController.current.value = ChessPieceAppearance(
      style: ChessPieceAppearanceController.styleFromLabel(_pieceStyle),
      size: ChessPieceAppearanceController.sizeFromLabel(_pieceSize),
    );
    ChessSoundService.instance.enabled = _soundEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final Size viewport = MediaQuery.sizeOf(context);
    final bool wide =
        AppBreakpoints.isTabletOrLarger(context) && viewport.width >= 700;
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
                  final bool desktop = wide && constraints.maxWidth >= 620;
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
                                        const Divider(color: AppColors.border),
                                        _dailyReminderSwitch(),
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
                                  const Divider(color: AppColors.border),
                                  _dailyReminderSwitch(),
                                ],
                              ),
                      ),
                      const SizedBox(height: 18),
                      const _SettingsSectionTitle(
                        icon: Icons.palette_rounded,
                        label: 'APPEARANCE',
                      ),
                      const SizedBox(height: 12),
                      _AppearancePreview(
                        boardTheme: _boardTheme,
                        pieceStyle: _pieceStyle,
                        pieceSize: _pieceSize,
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
                                  previewBuilder: (String value) =>
                                      _AppearancePreview(
                                    key: const ValueKey<String>(
                                        'appearance-choice-preview'),
                                    boardTheme: value,
                                    pieceStyle: _pieceStyle,
                                    pieceSize: _pieceSize,
                                  ),
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
                                  values: ChessPieceAppearanceController
                                      .styleLabels,
                                  selected: _pieceStyle,
                                  previewBuilder: (String value) =>
                                      _AppearancePreview(
                                    key: const ValueKey<String>(
                                        'appearance-choice-preview'),
                                    boardTheme: _boardTheme,
                                    pieceStyle: value,
                                    pieceSize: _pieceSize,
                                  ),
                                  onSelected: (String value) {
                                    setState(() => _pieceStyle = value);
                                    _preferences.writeString(
                                        'pieceStyle', value);
                                    ChessPieceAppearanceController
                                            .current.value =
                                        ChessPieceAppearanceController
                                            .current.value
                                            .copyWith(
                                      style: ChessPieceAppearanceController
                                          .styleFromLabel(value),
                                    );
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
                                icon: Icons.zoom_out_map_rounded,
                                title: 'Piece size',
                                value: _pieceSize,
                                onTap: () => _choose(
                                  title: 'Piece size',
                                  values:
                                      ChessPieceAppearanceController.sizeLabels,
                                  selected: _pieceSize,
                                  previewBuilder: (String value) =>
                                      _AppearancePreview(
                                    key: const ValueKey<String>(
                                        'appearance-choice-preview'),
                                    boardTheme: _boardTheme,
                                    pieceStyle: _pieceStyle,
                                    pieceSize: value,
                                  ),
                                  onSelected: (String value) {
                                    setState(() => _pieceSize = value);
                                    _preferences.writeString(
                                        'pieceSize', value);
                                    ChessPieceAppearanceController
                                            .current.value =
                                        ChessPieceAppearanceController
                                            .current.value
                                            .copyWith(
                                      size: ChessPieceAppearanceController
                                          .sizeFromLabel(value),
                                    );
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
                      const SizedBox(height: 12),
                      TextButton.icon(
                        key: const ValueKey<String>('delete-account'),
                        onPressed: _deletingAccount ? null : _deleteAccount,
                        icon: _deletingAccount
                            ? const SizedBox.square(
                                dimension: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.delete_forever_rounded),
                        label: Text(_deletingAccount
                            ? 'Deleting account…'
                            : 'Delete account permanently'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFFF7777),
                          minimumSize: const Size.fromHeight(52),
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
          onHome: widget.onHome ?? () => Navigator.maybePop(context),
          onPlay: widget.onPlay,
          onPuzzles: widget.onPuzzles,
          onLearn: widget.onLearn,
          onProfile: widget.onProfile,
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

  Widget _dailyReminderSwitch() => _SettingSwitch(
        icon: Icons.notifications_active_rounded,
        title: 'Daily chess reminder',
        subtitle: 'Remind me to play the daily challenge',
        value: _dailyReminderEnabled,
        onChanged: (bool value) async {
          final ScaffoldMessengerState messenger =
              ScaffoldMessenger.of(context);
          bool enabled = value;
          if (value) {
            enabled = await DailyReminderService.instance.enable();
          } else {
            await DailyReminderService.instance.disable();
          }
          if (!mounted) return;
          setState(() => _dailyReminderEnabled = enabled);
          await _preferences.writeBool('dailyReminder', enabled);
          messenger.showSnackBar(
            SnackBar(
              content: Text(enabled
                  ? 'Daily reminder set for 7:00 PM.'
                  : value
                      ? 'Notification permission is required.'
                      : 'Daily reminder disabled.'),
            ),
          );
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

  Future<void> _deleteAccount() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete account permanently?'),
        content: const Text(
          'Your profile, progress, rating and match history will be permanently deleted. This cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep account'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB3261E)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete forever'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deletingAccount = true);
    try {
      await widget.onDeleteAccount?.call();
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account deletion failed: ${error.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _deletingAccount = false);
    }
  }

  Future<void> _choose({
    required String title,
    required List<String> values,
    required String selected,
    required ValueChanged<String> onSelected,
    Widget Function(String value)? previewBuilder,
  }) async {
    final String? value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        String pendingValue = selected;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) =>
              SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.9,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: RadioGroup<String>(
                      groupValue: pendingValue,
                      onChanged: (String? value) {
                        if (value != null) {
                          setSheetState(() => pendingValue = value);
                        }
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(title),
                            subtitle: previewBuilder == null
                                ? null
                                : const Text(
                                    'Select an option to preview it live.'),
                          ),
                          if (previewBuilder != null) ...<Widget>[
                            previewBuilder(pendingValue),
                            const SizedBox(height: 10),
                          ],
                          for (final String option in values)
                            RadioListTile<String>(
                              value: option,
                              title: Text(option),
                              contentPadding: EdgeInsets.zero,
                            ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            key: const ValueKey<String>(
                                'apply-appearance-choice'),
                            onPressed: () =>
                                Navigator.pop(sheetContext, pendingValue),
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Apply'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
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

class _AppearancePreview extends StatelessWidget {
  const _AppearancePreview({
    required this.boardTheme,
    required this.pieceStyle,
    required this.pieceSize,
    super.key,
  });

  final String boardTheme;
  final String pieceStyle;
  final String pieceSize;

  static const List<String> _pieces = <String>[
    'pawn',
    'knight',
    'bishop',
    'rook',
    'queen',
    'king',
  ];
  static const List<String> _whiteGlyphs = <String>[
    '♙',
    '♘',
    '♗',
    '♖',
    '♕',
    '♔',
  ];
  static const List<String> _blackGlyphs = <String>[
    '♟',
    '♞',
    '♝',
    '♜',
    '♛',
    '♚',
  ];

  _PreviewPalette get _palette {
    switch (boardTheme) {
      case 'Jade Glass':
        return const _PreviewPalette(
          light: Color(0xFFC4DCCF),
          dark: Color(0xFF2F7D66),
          frame: Color(0xFF184D40),
        );
      case 'Tournament':
        return const _PreviewPalette(
          light: Color(0xFFDEC6A2),
          dark: Color(0xFFB58863),
          frame: Color(0xFF70452D),
        );
      case 'Marble':
        return const _PreviewPalette(
          light: Color(0xFFD9D8D3),
          dark: Color(0xFF667078),
          frame: Color(0xFF3C454C),
        );
      case 'Sapphire':
        return const _PreviewPalette(
          light: Color(0xFFC6D3D6),
          dark: Color(0xFF28546A),
          frame: Color(0xFF123647),
        );
      default:
        return const _PreviewPalette(
          light: Color(0xFFD8C3A5),
          dark: Color(0xFF7A4F2A),
          frame: Color(0xFF342113),
        );
    }
  }

  double get _pieceScale {
    switch (pieceSize) {
      case 'Double Extra Large':
        return 0.96;
      case 'Extra Large':
        return 0.84;
      default:
        return 0.72;
    }
  }

  @override
  Widget build(BuildContext context) {
    final _PreviewPalette palette = _palette;
    return ChessVerseCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const _GoldIcon(Icons.visibility_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'LIVE BOARD & PIECE PREVIEW',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.accentGold,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$boardTheme  •  $pieceStyle  •  $pieceSize',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.frame,
                    border: Border.all(color: palette.frame, width: 4),
                  ),
                  child: AspectRatio(
                    aspectRatio: 3,
                    child: Column(
                      children: <Widget>[
                        _pieceRow(white: false, palette: palette),
                        _pieceRow(white: true, palette: palette),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pieceRow({
    required bool white,
    required _PreviewPalette palette,
  }) {
    return Expanded(
      child: Row(
        children: List<Widget>.generate(_pieces.length, (int index) {
          final Color squareColor =
              index.isEven == white ? palette.light : palette.dark;
          return Expanded(
            child: ColoredBox(
              color: squareColor,
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double size = constraints.biggest.shortestSide;
                  return Center(
                    child: SizedBox.square(
                      dimension: size * _pieceScale,
                      child: _piece(
                        white: white,
                        index: index,
                        size: size * _pieceScale,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _piece({
    required bool white,
    required int index,
    required double size,
  }) {
    final String glyph = white ? _whiteGlyphs[index] : _blackGlyphs[index];
    if (pieceStyle != 'Premium 3D') {
      final bool highContrast = pieceStyle == 'High Contrast';
      final Color color = white ? Colors.white : Colors.black;
      return FittedBox(
        fit: BoxFit.contain,
        child: Text(
          glyph,
          style: TextStyle(
            color: color,
            fontSize: size,
            height: 1,
            shadows: <Shadow>[
              Shadow(
                color: white ? Colors.black : Colors.white,
                blurRadius: highContrast ? 3 : 1.5,
              ),
            ],
          ),
        ),
      );
    }
    final String side = white ? 'white' : 'black';
    return Image.asset(
      'assets/pieces/staunton_${side}_${_pieces[index]}.png',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => FittedBox(
        fit: BoxFit.contain,
        child: Text(glyph, style: TextStyle(fontSize: size, height: 1)),
      ),
    );
  }
}

class _PreviewPalette {
  const _PreviewPalette({
    required this.light,
    required this.dark,
    required this.frame,
  });

  final Color light;
  final Color dark;
  final Color frame;
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
