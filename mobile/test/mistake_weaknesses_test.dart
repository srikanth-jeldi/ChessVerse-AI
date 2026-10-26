import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chessverse_ai/core/local_game_archive.dart';
import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/app_ui_localizations.dart';
import 'package:chessverse_ai/features/analysis/domain/mistake_bank.dart';
import 'package:chessverse_ai/features/analysis/domain/mistake_weaknesses.dart';
import 'package:chessverse_ai/features/analysis/presentation/mistake_weakness_card.dart';

final now = DateTime.utc(2026, 10, 27, 12);
MistakeBankItem item({int days = 1, String theme = 'tactics', int? clock,
  String scope = 'player', String? side}) => MistakeBankItem(
  id: '$days-$theme-$clock',
  game: SavedGameRecord(mode: 'Online', result: 'Draw', detail: '', moves: [],
    playedAt: now.subtract(Duration(days: days)), whitePlayer: 'Me',
    blackPlayer: 'Opponent', reviewScope: scope, playerSide: side),
  review: SavedMoveReview(ply: 50, fenBefore: '8/8/8/8/8/8/4K3/7k w - - 0 25',
    playedMove: 'e2e3', bestMove: 'e2f3', classification: 'Mistake',
    coachingTheme: theme, clockSecondsBefore: clock, centipawnLoss: 120,
    opponentThreat: '', explanation: '', principalVariation: []));

void main() {
  test('tags overlap and require actual clock evidence', () {
    expect(MistakeWeaknesses.tags(item(clock: 30)), containsAll([
      MistakeCategory.tactics, MistakeCategory.endgame, MistakeCategory.timePressure]));
    for (final clock in [null, -1, 31]) {
      expect(MistakeWeaknesses.tags(item(theme: 'timeManagement', clock: clock)),
        isNot(contains(MistakeCategory.timePressure)));
    }
    expect(SavedMoveReview.fromJson(item(clock: 12).review.toJson()).clockSecondsBefore, 12);
    final legacy = item().review.toJson()..remove('clockSecondsBefore');
    expect(SavedMoveReview.fromJson(legacy).clockSecondsBefore, isNull);
  });
  test('date filters include boundary, exclude future, never fall back to older data', () {
    final bank = [item(days: 7), item(days: 8), item(days: 30), item(days: 31), item(days: -1)];
    expect(MistakeWeaknesses.recent(bank, days: 7, now: now), hasLength(1));
    expect(MistakeWeaknesses.recent(bank, days: 30, now: now), hasLength(3));
    expect(MistakeWeaknesses.recent([item(days: 31)], days: 7, now: now), isEmpty);
  });
  test('cloud reanalysis preserves clocks only for the same recorded move', () {
    final incoming = item().review;
    expect(SavedMoveReview.retainRecordedClocks([incoming], [item(clock: 15).review])
      .single.clockSecondsBefore, 15);
    final different = SavedMoveReview.fromJson({...incoming.toJson(), 'playedMove': 'e2d3'});
    expect(SavedMoveReview.retainRecordedClocks([different], [item(clock: 15).review])
      .single.clockSecondsBefore, isNull);
  });
  test('opponent and ambiguous both-side reviews do not become personal weaknesses', () {
    final bank = [item(scope: 'opponent'), item(scope: 'both'),
      item(scope: 'both', side: 'black'), item(scope: 'both', side: 'white')];
    expect(MistakeWeaknesses.recent(bank, days: 7, now: now), hasLength(1));
  });
  for (final language in AppLanguageController.supported.where((l) => l.code != 'system')) {
    testWidgets('weakness summary ${language.code}: periods and practice filter', (tester) async {
      await tester.runAsync(() => UiCopy.load(language.code));
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      List<MistakeBankItem>? selected;
      final recent = item(); final old = item(days: 20, theme: 'kingSafety');
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: Directionality(textDirection: ['ar','fa','he','ur'].contains(language.code)
          ? TextDirection.rtl : TextDirection.ltr,
          child: SingleChildScrollView(child: MistakeWeaknessCard(
            items: [recent, old], now: now, onPractice: (items) => selected = items))),
      ))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('weakness-days-30')));
      await tester.pumpAndSettle();
      final category = find.byKey(const ValueKey('weakness-kingSafety'));
      await tester.ensureVisible(category); await tester.tap(category);
      await tester.pumpAndSettle();
      final practise = find.widgetWithText(FilledButton, UiCopy.text('Practise these positions'));
      await tester.ensureVisible(practise); await tester.tap(practise);
      expect(selected, [old]);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
