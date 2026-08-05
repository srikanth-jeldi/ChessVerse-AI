import 'package:flutter/material.dart';

import '../../../core/local_game_archive.dart';
import '../../../core/theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    this.playerName = 'Guest Player',
    this.username,
    this.email,
    this.profilePhotoUrl,
    this.isGuest = true,
    this.onUsernameChanged,
    this.onSecureProgress,
    super.key,
  });

  final String playerName;
  final String? username;
  final String? email;
  final String? profilePhotoUrl;
  final bool isGuest;
  final ValueChanged<String>? onUsernameChanged;
  final Future<void> Function()? onSecureProgress;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String _username;

  @override
  void initState() {
    super.initState();
    final String saved = LocalGameArchive.profileUsername?.trim() ?? '';
    final String account = widget.username?.trim() ?? '';
    _username = saved.isNotEmpty
        ? saved
        : (account.isNotEmpty ? account : widget.playerName);
  }

  @override
  Widget build(BuildContext context) {
    final LocalGameStats stats = LocalGameArchive.stats();
    final RewardSnapshot rewards = LocalGameArchive.rewards();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('PLAYER PROFILE'),
        centerTitle: false,
        backgroundColor: const Color(0xD9071827),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 36),
        children: <Widget>[
          _ProfileHero(
            playerName: widget.playerName,
            username: _username,
            country: LocalGameArchive.profileCountry,
            level: LocalGameArchive.profileLevel,
            avatar: LocalGameArchive.profileAvatar,
            profilePhotoUrl: widget.profilePhotoUrl,
            isGuest: widget.isGuest,
            onEdit: _editProfile,
          ),
          const SizedBox(height: 18),
          _SectionCard(
            title: 'PLAYER PROGRESS',
            icon: Icons.military_tech_rounded,
            asset: 'assets/backgrounds/home-analysis-hero-v1.png',
            trailing: _Pill(
              icon: Icons.paid_rounded,
              label: '${rewards.coins} coins',
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Level ${rewards.level}  •  ${rewards.xp} XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 10,
                    value: rewards.levelProgress,
                    color: AppColors.accentGold,
                    backgroundColor: const Color(0xFF263645),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _Pill(
                      icon: Icons.local_fire_department_rounded,
                      label: '${rewards.streak} day streak',
                    ),
                    _Pill(
                      icon: Icons.workspace_premium_rounded,
                      label:
                          '${rewards.unlockedBadges}/${rewards.badges.length} badges',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _SectionLabel('CAREER STATS'),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.sizeOf(context).width >= 700 ? 4 : 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: <Widget>[
              _Stat('Games', '${stats.gamesPlayed}', Icons.sports_esports),
              _Stat('Wins', '${stats.wins}', Icons.emoji_events_rounded),
              _Stat('Win rate', '${stats.winRate}%', Icons.insights_rounded),
              _Stat('Puzzles', '${stats.puzzlesSolved}', Icons.extension),
            ],
          ),
          const SizedBox(height: 18),
          _SectionCard(
            title: 'ACCOUNT',
            asset: 'assets/backgrounds/home-settings-hero-v1.png',
            icon: widget.isGuest
                ? Icons.person_outline_rounded
                : Icons.verified_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  widget.isGuest
                      ? 'Guest identity and online progress are safe on this device. Secure with Google to restore them after reinstalling or changing devices.'
                      : '${widget.email ?? 'Verified ChessVerseAI player'}\nYour identity and training progress are ready across ChessVerseAI.',
                  style:
                      const TextStyle(color: Color(0xFFA9BBC4), height: 1.45),
                ),
                if (widget.isGuest &&
                    widget.onSecureProgress != null) ...<Widget>[
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    key: const ValueKey<String>('secure-guest-progress'),
                    onPressed: () => widget.onSecureProgress!.call(),
                    icon: const Icon(Icons.g_mobiledata_rounded),
                    label: const Text('SECURE PROGRESS WITH GOOGLE'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile() async {
    final _EditableProfile? value =
        await showModalBottomSheet<_EditableProfile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => _ProfileEditorSheet(
        initialUsername: _username,
        initialCountry: LocalGameArchive.profileCountry,
        initialLevel: LocalGameArchive.profileLevel,
        initialAvatar: LocalGameArchive.profileAvatar,
      ),
    );
    if (value == null || !mounted) return;
    LocalGameArchive.savePlayerProfile(
      username: value.username,
      country: value.country,
      level: value.level,
      avatar: value.avatar,
    );
    setState(() => _username = value.username);
    widget.onUsernameChanged?.call(value.username);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Player profile saved')),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.playerName,
    required this.username,
    required this.country,
    required this.level,
    required this.avatar,
    required this.profilePhotoUrl,
    required this.isGuest,
    required this.onEdit,
  });

  final String playerName;
  final String username;
  final String country;
  final int level;
  final int avatar;
  final String? profilePhotoUrl;
  final bool isGuest;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/backgrounds/home-rankings-hero-v1.png'),
          fit: BoxFit.fitHeight,
          alignment: Alignment.centerRight,
          opacity: .38,
        ),
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF173A43), Color(0xFF091927)],
        ),
        border: Border.all(color: const Color(0xFF9A7133)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
              color: Color(0x55000000), blurRadius: 30, offset: Offset(0, 16)),
        ],
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              _Avatar(
                index: avatar,
                size: 76,
                photoUrl: profilePhotoUrl,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      playerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '@$username',
                      style: const TextStyle(
                        color: Color(0xFF63D2B8),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${_flag(country)} $country  •  ${_levelTitle(level)}',
                        style: const TextStyle(color: Color(0xFFB8C8CE)),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                key: const ValueKey<String>('edit-player-profile'),
                tooltip: 'Edit profile',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              _HeroMetric(
                  label: 'STATUS',
                  value: isGuest ? 'GUEST ONLINE' : 'VERIFIED'),
              const _Divider(),
              _HeroMetric(label: 'CHESS LEVEL', value: '${_elo(level)} ELO'),
              const _Divider(),
              const _HeroMetric(label: 'ARENA', value: 'READY'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileEditorSheet extends StatefulWidget {
  const _ProfileEditorSheet({
    required this.initialUsername,
    required this.initialCountry,
    required this.initialLevel,
    required this.initialAvatar,
  });

  final String initialUsername;
  final String initialCountry;
  final int initialLevel;
  final int initialAvatar;

  @override
  State<_ProfileEditorSheet> createState() => _ProfileEditorSheetState();
}

class _ProfileEditorSheetState extends State<_ProfileEditorSheet> {
  static const List<String> _countries = <String>[
    'India',
    'United States',
    'United Kingdom',
    'Canada',
    'Australia',
    'Singapore',
  ];
  late final TextEditingController _username;
  late String _country;
  late int _level;
  late int _avatar;

  @override
  void initState() {
    super.initState();
    _username = TextEditingController(text: widget.initialUsername);
    _country = _countries.contains(widget.initialCountry)
        ? widget.initialCountry
        : _countries.first;
    _level = widget.initialLevel;
    _avatar = widget.initialAvatar;
  }

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF0A1B29),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(top: BorderSide(color: Color(0xFF9A7133))),
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            children: <Widget>[
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF526875),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'CUSTOMIZE YOUR PLAYER',
                style: TextStyle(
                  color: Color(0xFFF6E7C2),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const Text(
                'Build the identity opponents see in the arena.',
                style: TextStyle(color: Color(0xFF91A8B4)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 74,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 6,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (BuildContext context, int index) => InkWell(
                    key: ValueKey<String>('profile-avatar-$index'),
                    borderRadius: BorderRadius.circular(99),
                    onTap: () => setState(() => _avatar = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _avatar == index
                              ? AppColors.accentGold
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: _Avatar(index: index, size: 62),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                key: const ValueKey<String>('profile-username-field'),
                controller: _username,
                maxLength: 24,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _country,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Country',
                  prefixIcon: Icon(Icons.public_rounded),
                ),
                items: _countries
                    .map(
                      (String country) => DropdownMenuItem<String>(
                        value: country,
                        child: Text('${_flag(country)}  $country'),
                      ),
                    )
                    .toList(),
                onChanged: (String? value) =>
                    setState(() => _country = value ?? _country),
              ),
              const SizedBox(height: 22),
              Text(
                _levelTitle(_level),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Estimated rating: ${_elo(_level)} ELO',
                style: const TextStyle(color: AppColors.accentGold),
              ),
              Slider(
                key: const ValueKey<String>('profile-level-slider'),
                value: _level.toDouble(),
                min: 0,
                max: 4,
                divisions: 4,
                label: _levelTitle(_level),
                onChanged: (double value) =>
                    setState(() => _level = value.round()),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const <Widget>[
                  Text('NEW', style: TextStyle(color: Color(0xFF8198A5))),
                  Text('MASTER', style: TextStyle(color: Color(0xFF8198A5))),
                ],
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                key: const ValueKey<String>('save-player-profile'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: const Color(0xFF211606),
                  minimumSize: const Size.fromHeight(54),
                ),
                onPressed: () {
                  final String name = _username.text.trim();
                  if (!RegExp(r'^[A-Za-z0-9_.-]{3,24}$').hasMatch(name)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Use 3–24 letters, numbers, dot, dash or underscore.',
                        ),
                      ),
                    );
                    return;
                  }
                  Navigator.of(context).pop(
                    _EditableProfile(
                      username: name,
                      country: _country,
                      level: _level,
                      avatar: _avatar,
                    ),
                  );
                },
                icon: const Icon(Icons.save_rounded),
                label: const Text(
                  'SAVE PLAYER PROFILE',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditableProfile {
  const _EditableProfile({
    required this.username,
    required this.country,
    required this.level,
    required this.avatar,
  });

  final String username;
  final String country;
  final int level;
  final int avatar;
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.index, required this.size, this.photoUrl});
  final int index;
  final double size;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    const List<IconData> icons = <IconData>[
      Icons.person_rounded,
      Icons.psychology_rounded,
      Icons.sports_esports_rounded,
      Icons.workspace_premium_rounded,
      Icons.shield_rounded,
      Icons.auto_awesome_rounded,
    ];
    const List<Color> colors = <Color>[
      Color(0xFF1E88A8),
      Color(0xFF3E8E72),
      Color(0xFF8057B8),
      Color(0xFFB47A2B),
      Color(0xFF466A9A),
      Color(0xFF9A4F63),
    ];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[colors[index], const Color(0xFF071522)],
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
              color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 7)),
        ],
      ),
      child: photoUrl?.trim().isNotEmpty == true
          ? ClipOval(
              child: Image.network(
                photoUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(icons[index], color: Colors.white, size: size * 0.5),
              ),
            )
          : Icon(icons[index], color: Colors.white, size: size * 0.5),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(label,
              style: const TextStyle(color: Color(0xFF78929E), fontSize: 9)),
          const SizedBox(height: 3),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFF6E7C2),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 28, color: const Color(0xFF34505B));
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
    this.asset,
  });
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;
  final String? asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xE60C1D2B),
        image: asset == null
            ? null
            : DecorationImage(
                image: AssetImage(asset!),
                fit: BoxFit.fitHeight,
                alignment: Alignment.centerRight,
                opacity: .2,
              ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF304854)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 9,
            runSpacing: 9,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Icon(icon, color: AppColors.accentGold),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFF6E7C2),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF07131E),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: const Color(0xFF34505B)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 15, color: AppColors.accentGold),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AppColors.accentGold,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
  String get asset => switch (label) {
        'Games' => 'assets/backgrounds/home-online-hero-v1.png',
        'Wins' => 'assets/backgrounds/home-rankings-hero-v1.png',
        'Win rate' => 'assets/backgrounds/home-analysis-hero-v1.png',
        _ => 'assets/backgrounds/home-puzzles-hero-v1.png',
      };

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xE60C1D2B),
          image: DecorationImage(
            image: AssetImage(asset),
            fit: BoxFit.cover,
            alignment: Alignment.center,
            opacity: .3,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF3B6170)),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x33000000), blurRadius: 16),
          ],
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: const Color(0xFF63D2B8)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(value,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900)),
                  ),
                  Text(label,
                      style: const TextStyle(
                          color: Color(0xFF8FA5B1), fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      );
}

String _levelTitle(int level) => const <String>[
      'New to chess',
      'Casual player',
      'Club challenger',
      'Advanced tactician',
      'Master arena',
    ][level.clamp(0, 4)];

int _elo(int level) =>
    const <int>[400, 800, 1200, 1600, 2000][level.clamp(0, 4)];

String _flag(String country) =>
    const <String, String>{
      'India': '🇮🇳',
      'United States': '🇺🇸',
      'United Kingdom': '🇬🇧',
      'Canada': '🇨🇦',
      'Australia': '🇦🇺',
      'Singapore': '🇸🇬',
    }[country] ??
    '🌍';
