import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/app_preferences.dart';
import '../../../core/app_ui_localizations.dart';
import '../../../core/local_game_archive.dart';
import '../../../core/widgets/chessverse_card.dart';
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
    final total = plan == null ? 0 : plan.puzzles.length + plan.mistakes.length + 1;
    final completed = plan == null ? 0 :
        plan.puzzles.where(LocalGameArchive.isPuzzleComplete).length +
        plan.mistakes.where(_replayed.contains).length +
        (_openingDone ? 1 : 0);
    return ChessVerseCard(
      padding: const EdgeInsets.all(18),
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: Color(0xFFEABF61)),
                SizedBox(width: 10),
                Expanded(child: UiText(
                  'Your daily practice plan',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                      color: Color(0xFFF6E7C2)),
                )),
              ],
            ),
            const SizedBox(height: 10),
            if (_failed)
              TextButton(onPressed: _refresh, child: const UiText('Retry')),
            if (plan == null && !_failed) const LinearProgressIndicator(),
            if (plan != null) ...[
              UiText(
                plan.personalised
                    ? 'Based on your reviewed mistakes from the last 30 days.'
                    : 'Starter plan. Review your games to personalise future practice.',
                style: const TextStyle(color: Color(0xFFADC1CE), height: 1.4),
              ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : completed / total,
                    minHeight: 6,
                    color: const Color(0xFF54DECA),
                    backgroundColor: const Color(0xFF263C4D),
                  ),
                )),
                const SizedBox(width: 12),
                Text('$completed / $total',
                  style: const TextStyle(color: Color(0xFF54DECA), fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 6),
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
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFF8FAFC),
            disabledForegroundColor: const Color(0xFF54DECA),
            backgroundColor: done ? const Color(0xFF123E40) : const Color(0xFF0B2233),
            side: BorderSide(color: done ? const Color(0xFF54DECA) : const Color(0xFF315364)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            minimumSize: const Size.fromHeight(52),
          ),
          onPressed: _busy || done ? null : () => _run(action),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(done ? Icons.check_circle : Icons.play_circle_outline_rounded,
                    color: done ? const Color(0xFF54DECA) : const Color(0xFFEABF61)),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
                if (!done) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFFADC1CE)),
                ],
              ],
            ),
          ),
        ),
      );
}
