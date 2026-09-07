import 'package:flutter/material.dart';

import '../data/mission_api.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({required this.token, this.onRewardClaimed, super.key});
  final String token;
  final VoidCallback? onRewardClaimed;

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  static const MissionApi _api = MissionApi();
  MissionBoard? _board;
  String? _error;
  String? _claiming;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final MissionBoard board = await _api.load(widget.token);
      if (mounted) {
        setState(() {
          _board = board;
          _error = null;
        });
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _claim(PlayerMission mission) async {
    setState(() => _claiming = mission.code);
    try {
      final MissionBoard board = await _api.claim(widget.token, mission.code);
      if (!mounted) return;
      setState(() {
        _board = board;
        _error = null;
      });
      widget.onRewardClaimed?.call();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${mission.rewardCoins} coins added to your wallet.'),
      ));
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _claiming = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF030A12),
        appBar: AppBar(
          backgroundColor: const Color(0xFF071827),
          title: const Text('MISSIONS'),
        ),
        body: _error != null && _board == null
            ? Center(
                child: FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('RETRY'),
              ))
            : _board == null
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
                      children: <Widget>[
                        const _MissionHero(),
                        const SizedBox(height: 22),
                        _section('DAILY MISSIONS', _board!.daily),
                        const SizedBox(height: 22),
                        _section('WEEKLY MISSIONS', _board!.weekly),
                      ],
                    ),
                  ),
      );

  Widget _section(String title, List<PlayerMission> missions) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(title,
                  style: const TextStyle(
                    color: Color(0xFFE5B550),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  )),
              const SizedBox(height: 10),
              ...missions.map((mission) => _MissionCard(
                    mission: mission,
                    busy: _claiming == mission.code,
                    onClaim: () => _claim(mission),
                  )),
            ],
          ),
        ),
      );
}

class _MissionHero extends StatelessWidget {
  const _MissionHero();
  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(colors: <Color>[
                Color(0xFF123C43),
                Color(0xFF0A1D30),
                Color(0xFF1D162B),
              ]),
              border: Border.all(color: const Color(0xFF55E2CF)),
            ),
            child: const Row(children: <Widget>[
              Icon(Icons.flag_circle_rounded,
                  color: Color(0xFFE5B550), size: 52),
              SizedBox(width: 16),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('YOUR NEXT CHALLENGE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      )),
                  SizedBox(height: 6),
                  Text(
                      'Fair virtual rewards for verified play. Rewards cannot be purchased or withdrawn.',
                      style: TextStyle(color: Color(0xFFB4C3CC), height: 1.35)),
                ],
              )),
            ]),
          ),
        ),
      );
}

class _MissionCard extends StatelessWidget {
  const _MissionCard(
      {required this.mission, required this.busy, required this.onClaim});
  final PlayerMission mission;
  final bool busy;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final double progress =
        mission.target <= 0 ? 0 : mission.progress / mission.target;
    return Semantics(
      label:
          '${mission.title}, ${mission.progress} of ${mission.target}, ${mission.rewardCoins} coin reward',
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xEE0A1C2B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: mission.completed
                  ? const Color(0xFF55E2CF)
                  : const Color(0xFF29475A)),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(children: <Widget>[
                Icon(
                    mission.completed
                        ? Icons.task_alt_rounded
                        : Icons.track_changes_rounded,
                    color: mission.completed
                        ? const Color(0xFF55E2CF)
                        : const Color(0xFF7D96A8)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(mission.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ))),
                const Icon(Icons.paid_rounded, color: Color(0xFFE5B550)),
                const SizedBox(width: 5),
                Text('${mission.rewardCoins}',
                    style: const TextStyle(
                      color: Color(0xFFE5B550),
                      fontWeight: FontWeight.w900,
                    )),
              ]),
              const SizedBox(height: 7),
              Text(mission.description,
                  style: const TextStyle(color: Color(0xFFB4C3CC))),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                  value: progress.clamp(0, 1),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(99),
                  color: const Color(0xFF55E2CF),
                  backgroundColor: const Color(0xFF25394A)),
              const SizedBox(height: 10),
              Row(children: <Widget>[
                Text('${mission.progress}/${mission.target}',
                    style: const TextStyle(
                      color: Color(0xFF8EA6B6),
                      fontWeight: FontWeight.w800,
                    )),
                const Spacer(),
                if (mission.claimed)
                  const Text('CLAIMED',
                      style: TextStyle(
                          color: Color(0xFF55E2CF),
                          fontWeight: FontWeight.w900))
                else
                  FilledButton(
                    onPressed: mission.completed && !busy ? onClaim : null,
                    child: Text(busy
                        ? 'CLAIMING…'
                        : mission.completed
                            ? 'CLAIM REWARD'
                            : 'IN PROGRESS'),
                  ),
              ]),
            ]),
      ),
    );
  }
}
