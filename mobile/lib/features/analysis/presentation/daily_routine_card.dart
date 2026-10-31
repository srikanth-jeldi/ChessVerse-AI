import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/app_preferences.dart';
import '../../../core/app_ui_localizations.dart';
import '../../../core/local_game_archive.dart';
import '../../tutorial/data/academy_progress_store.dart';
import '../../tutorial/data/opening_progress_store.dart';
import '../../tutorial/presentation/opening_trainer_screen.dart';
import '../domain/daily_routine.dart';
import 'mistake_bank_screen.dart';

class DailyRoutineCard extends StatefulWidget {
  const DailyRoutineCard({required this.onPuzzle, super.key});
  final Future<void> Function(String) onPuzzle;
  @override
  State<DailyRoutineCard> createState() => _DailyRoutineCardState();
}

class _DailyRoutineCardState extends State<DailyRoutineCard>
    with WidgetsBindingObserver {
  DailyRoutine? _plan;
  String? _day;
  Set<String> _replayed = {};
  bool _openingDone = false, _busy = false, _loading = false, _failed = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    LocalGameArchive.activityRevision.addListener(_refresh);
    unawaited(_load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LocalGameArchive.activityRevision.removeListener(_refresh);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _refresh() => unawaited(_load());
  Future<void> _load() async {
    if (_loading) return;
    _loading = true;
    try {
      final now = DateTime.now().toUtc();
      final today = now.toIso8601String().substring(0, 10);
      final identity = await OpeningProgressStore.identityKey();
      final key = 'daily.routine.v1.$identity';
      final reviews = await const AcademyProgressStore().readMistakeReviews();
      DailyRoutine? plan;
      try {
        final raw = await const AppPreferences().readString(key, fallback: '');
        final stored = jsonDecode(raw) as Map<String, dynamic>;
        if (stored['date'] == today) plan = DailyRoutine.fromJson(stored);
      } catch (_) {
        /* Missing or outdated local plan: rebuild from evidence. */
      }
      if (plan == null) {
        plan = DailyRoutine.create(
          LocalGameArchive.games,
          LocalGameArchive.completedPuzzleIds,
          now,
        );
        plan = DailyRoutine(
          puzzles: plan.puzzles,
          mistakes: plan.mistakes,
          focus: plan.focus,
          successBaseline: {
            for (final id in plan.mistakes) id: reviews[id]?.successes ?? 0,
          },
        );
        await const AppPreferences().writeString(
          key,
          jsonEncode({'date': today, ...plan.toJson()}),
        );
      }
      final replayed = reviews.entries
          .where(
            (entry) =>
                entry.value.successes >
                    (plan!.successBaseline[entry.key] ?? 0) &&
                entry.value.updatedAt.toUtc().toIso8601String().startsWith(
                  today,
                ) &&
                entry.value.nextReview.isAfter(now),
          )
          .map((entry) => entry.key)
          .toSet();
      final opening =
          await OpeningProgressStore.completedToday('ruy-lopez', true, now) ||
          await OpeningProgressStore.completedToday('ruy-lopez', false, now);
      if (mounted) {
        setState(() {
          _plan = plan;
          _day = today;
          _replayed = replayed;
          _openingDone = opening;
          _failed = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      _loading = false;
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    if (_day != DateTime.now().toUtc().toIso8601String().substring(0, 10)) {
      await _load();
      return;
    }
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        await _load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const UiText(
              'Your daily practice plan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (_failed)
              TextButton(onPressed: _refresh, child: const UiText('Retry')),
            if (plan == null && !_failed) const LinearProgressIndicator(),
            if (plan != null) ...[
              UiText(
                plan.personalised
                    ? 'Based on your reviewed mistakes from the last 30 days.'
                    : 'Starter plan. Review your games to personalise future practice.',
              ),
              if (plan.focus != null)
                Text(
                  '${UiCopy.text('Focus')}: ${UiCopy.text(plan.focus!.label)}',
                ),
              for (var i = 0; i < plan.puzzles.length; i++)
                _task(
                  '${UiCopy.text('Puzzle')} ${i + 1} / ${plan.puzzles.length}',
                  LocalGameArchive.isPuzzleComplete(plan.puzzles[i]),
                  () => widget.onPuzzle(plan.puzzles[i]),
                ),
              for (final id in plan.mistakes)
                _task(
                  UiCopy.text('Replay a reviewed mistake'),
                  _replayed.contains(id),
                  () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => MistakeBankScreen(initialItemIds: [id]),
                    ),
                  ),
                ),
              _task(
                '${UiCopy.text('Opening Trainer')} · ${UiCopy.text('Ruy Lopez')}',
                _openingDone,
                () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => const OpeningTrainerScreen(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _task(String title, bool done, Future<void> Function() action) =>
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: OutlinedButton(
          onPressed: _busy || done ? null : () => _run(action),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(done ? Icons.check_circle : Icons.play_arrow),
                const SizedBox(width: 10),
                Expanded(child: Text(title)),
              ],
            ),
          ),
        ),
      );
}
