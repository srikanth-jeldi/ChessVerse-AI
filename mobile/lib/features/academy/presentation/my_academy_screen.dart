import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/academy_activity.dart';
import '../../puzzles/domain/puzzle_catalog.dart';
import '../data/academy_api.dart';

/// Student workspace in the existing app. Staff administration stays on the web.
class MyAcademyScreen extends StatefulWidget {
  const MyAcademyScreen({
    required this.token,
    required this.onPuzzle,
    required this.onPosition,
    this.api,
    super.key,
  });
  final AcademyApi? api;
  final String token;
  final Future<void> Function(String id) onPuzzle;
  final Future<void> Function(String fen, String bestMove, String instructions)
  onPosition;
  @override
  State<MyAcademyScreen> createState() => _MyAcademyScreenState();
}

class _MyAcademyScreenState extends State<MyAcademyScreen> {
  late final AcademyApi api = widget.api ?? AcademyApi(widget.token);
  final invite = TextEditingController();
  List<dynamic> organizations = [], announcements = [];
  Map<String, dynamic>? workspace, activity;
  String? org, error;
  bool busy = true;
  int generation = 0;
  @override
  void initState() {
    super.initState();
    unawaited(load());
  }

  @override
  void dispose() {
    generation++;
    api.close();
    invite.dispose();
    super.dispose();
  }

  List<dynamic> rows(String key) => workspace?[key] as List<dynamic>? ?? [];
  Future<void> load() async {
    final request = ++generation;
    setState(() {
      busy = true;
      error = null;
      workspace = null;
      activity = null;
      announcements = [];
    });
    try {
      final me = await api.request('/me');
      final list = (me['organizations'] as List)
          .where((o) => o['role'] == 'STUDENT')
          .toList();
      final selected = list.any((o) => o['id'] == org)
          ? org
          : (list.isEmpty ? null : list.first['id'] as String);
      Map<String, dynamic>? data, feed;
      List<dynamic> notices = [];
      if (selected != null) {
        data = Map<String, dynamic>.from(
          await api.request('/$selected/workspace'),
        );
        feed = Map<String, dynamic>.from(
          await api.request('/$selected/app-activity'),
        );
        notices = await api.request('/$selected/announcements') as List;
      }
      if (!mounted || request != generation) return;
      setState(() {
        organizations = list;
        org = selected;
        workspace = data;
        activity = feed;
        announcements = notices;
      });
    } catch (e) {
      if (mounted && request == generation)
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted && request == generation) setState(() => busy = false);
    }
  }

  Future<void> join() async {
    final text = invite.text.trim();
    final uri = Uri.tryParse(text);
    final token = uri?.queryParameters['invite'] ?? text;
    if (token.length < 32 || token.length > 200) {
      message('Paste the invitation link sent by your academy.');
      return;
    }
    setState(() => busy = true);
    try {
      await api.request(
        '/invitations/accept',
        method: 'POST',
        body: {'token': token},
      );
      invite.clear();
      await load();
    } catch (e) {
      message(e.toString());
      if (mounted) setState(() => busy = false);
    }
  }

  void message(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Widget box(Widget child) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );
  Future<void> train(Map<String, dynamic> assignment) async {
    final selectedOrg = org!;
    final kind = assignment['kind'];
    final study = kind == 'OPENINGS' || kind == 'MASTER_GAMES';
    final capture = AcademyPracticeCapture(
      puzzleId: assignment['puzzle_id'],
      position: kind == 'POSITIONS',
    );
    if (!study) {
      String? puzzle = assignment['puzzle_id'];
      if (kind == 'PUZZLES' && puzzle == null) {
        puzzle = await showDialog<String>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('Choose a practice puzzle'),
            children: PuzzleCatalog.all
                .take(30)
                .map(
                  (p) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, p.id),
                    child: Text(p.title),
                  ),
                )
                .toList(),
          ),
        );
        if (puzzle == null) return;
      }
      if (kind == 'POSITIONS' &&
          (assignment['position_fen'] == null ||
              assignment['best_move'] == null)) {
        message(
          'Ask your coach to assign a position with a FEN and best move.',
        );
        return;
      }
      setState(() => busy = true);
      AcademyPracticeCapture.active = capture;
      try {
        if (kind == 'PUZZLES') {
          await widget.onPuzzle(puzzle!);
        } else {
          await widget.onPosition(
            assignment['position_fen'],
            assignment['best_move'],
            assignment['instructions'],
          );
        }
      } catch (e) {
        message(
          'Practice could not open. Please ask your coach to check the assignment.',
        );
        return;
      } finally {
        AcademyPracticeCapture.active = null;
        if (mounted) setState(() => busy = false);
      }
      if (!mounted || capture.attempts == 0) return;
    }
    if (!mounted) return;
    var notes = '';
    final eventId = const Uuid().v4();
    bool sending = false;
    String? sendError;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(
            study
                ? 'Submit study notes'
                : capture.solved
                ? 'Practice complete'
                : 'Practice attempt',
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(assignment['instructions']),
                  const SizedBox(height: 16),
                  Text(
                    study
                        ? 'Explain what you learned. Your coach will see this as student-reported study.'
                        : '${capture.attempts} recorded attempt(s). ${capture.solved ? 'Solved' : 'Needs more practice'}. This result goes only to this assignment’s academy.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (value) => notes = value,
                    maxLength: 2000,
                    minLines: 3,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: study
                          ? 'Study notes (required)'
                          : 'Notes for your coach',
                    ),
                  ),
                  if (sendError != null)
                    Text(sendError!, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: sending ? null : () => Navigator.pop(context),
              child: const Text('Close without sending'),
            ),
            FilledButton(
              onPressed: sending
                  ? null
                  : () async {
                      if (study && notes.trim().isEmpty) {
                        update(() => sendError = 'Add your study notes first.');
                        return;
                      }
                      update(() => sending = true);
                      try {
                        await api.request(
                          '/$selectedOrg/assignments/${assignment['id']}/results',
                          method: 'POST',
                          body: {
                            'id': eventId,
                            'attempts': study ? 1 : capture.attempts,
                            'solved': study || capture.solved,
                            'notes': notes.trim(),
                          },
                        );
                        if (context.mounted) Navigator.pop(context);
                        message('Result saved for your coach.');
                      } catch (e) {
                        if (context.mounted)
                          update(() {
                            sending = false;
                            sendError =
                                'Not saved. Check your connection and retry. $e';
                          });
                      }
                    },
              child: Text(sending ? 'Saving…' : 'Submit to coach'),
            ),
          ],
        ),
      ),
    );
    if (mounted) await load();
  }

  void showReport(Map<String, dynamic> report) {
    try {
      final summary =
          jsonDecode(report['summary'] as String) as Map<String, dynamic>;
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${report['period']} progress'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${summary['from']} – ${summary['to']}'),
                  Text(summary['source'] ?? 'Coach observations'),
                  for (final o in summary['observations'] ?? [])
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        '${o['practiced_on']}: ${o['accuracy']}% accuracy · ${o['minutes']} minutes\n${o['notes']}',
                      ),
                    ),
                  for (final d in summary['appDaily'] ?? [])
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${d['day']} · ${d['kind']}: ${d['events']} events, ${d['solved']} solved',
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (_) {
      message('This report could not be opened.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final students = rows('students');
    final student = students.isEmpty ? null : students.first;
    String label(List<dynamic> items, dynamic id, String fallback) =>
        items
            .where((e) => e['id'] == id)
            .map((e) => e['name'] as String)
            .firstOrNull ??
        fallback;
    final shared = (activity?['sharing'] as List? ?? []).any(
      (e) => e['student_id'] == student?['id'] && e['enabled'] == true,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Academy'),
        actions: [
          IconButton(
            onPressed: busy ? null : load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh academy',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (busy) const LinearProgressIndicator(),
                    if (error != null) box(Text(error!)),
                    box(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your coach. Your training. Your next move.',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: invite,
                            decoration: const InputDecoration(
                              labelText: 'Academy invitation link',
                              helperText: 'Use the same verified email your academy invited.',
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: busy ? null : join,
                            icon: const Icon(Icons.school),
                            label: const Text('Accept invitation'),
                          ),
                        ],
                      ),
                    ),
                    if (!busy && organizations.isEmpty && error == null)
                      box(
                        const Text(
                          'No student academy membership yet. Ask your academy for an invitation. Personal practice remains available.',
                        ),
                      ),
                    if (organizations.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: org,
                        decoration: const InputDecoration(labelText: 'Academy'),
                        items: organizations
                            .map(
                              (o) => DropdownMenuItem<String>(
                                value: o['id'],
                                child: Text(o['name']),
                              ),
                            )
                            .toList(),
                        onChanged: busy
                            ? null
                            : (value) {
                                org = value;
                                unawaited(load());
                              },
                      ),
                    if (workspace != null) ...[
                      const SizedBox(height: 16),
                      box(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label(
                                rows('members'),
                                student?['coach_id'],
                                'Coach not assigned',
                              ),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              label(
                                rows('batches'),
                                student?['batch_id'],
                                'Batch not assigned',
                              ),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Share personal practice with this academy',
                              ),
                              subtitle: const Text(
                                'Shares new app activity with authorized staff and linked parents. Stopping sharing keeps earlier report snapshots. Assignment submissions are shared separately.',
                              ),
                              value: shared,
                              onChanged: busy
                                  ? null
                                  : (value) async {
                                      setState(() => busy = true);
                                      try {
                                        await api.request(
                                          '/$org/app-activity/sharing',
                                          method: 'PUT',
                                          body: {'enabled': value},
                                        );
                                        await load();
                                      } catch (e) {
                                        message(e.toString());
                                        if (mounted)
                                          setState(() => busy = false);
                                      }
                                    },
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'Assignments',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (rows('assignments').isEmpty)
                        box(
                          const Text(
                            'Your coach’s assignments will appear here.',
                          ),
                        ),
                      for (final a in rows('assignments'))
                        box(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a['title'],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('${a['kind']} · Due ${a['due_date']}'),
                              const SizedBox(height: 10),
                              Text(a['instructions']),
                              const SizedBox(height: 14),
                              FilledButton.icon(
                                onPressed: busy || a['completed_at'] != null
                                    ? null
                                    : () => train(Map<String, dynamic>.from(a)),
                                icon: Icon(
                                  a['completed_at'] != null
                                      ? Icons.check_circle
                                      : Icons.play_arrow,
                                ),
                                label: Text(
                                  a['completed_at'] != null
                                      ? 'Completed'
                                      : a['kind'] == 'OPENINGS' ||
                                            a['kind'] == 'MASTER_GAMES'
                                      ? 'Study and submit notes'
                                      : 'Start practice',
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Text(
                        'Announcements',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      for (final a in announcements)
                        box(
                          ListTile(
                            title: Text(a['title']),
                            subtitle: Text(a['message']),
                          ),
                        ),
                      const Text(
                        'Progress reports',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      for (final r in rows('reports'))
                        box(
                          ListTile(
                            title: Text('${r['period']} report'),
                            subtitle: Text('${r['created_at']}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () =>
                                showReport(Map<String, dynamic>.from(r)),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
