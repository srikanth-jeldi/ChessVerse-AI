import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/live_coach_localizations.dart';
import 'package:chessverse_ai/features/social/data/community_api.dart';
import 'package:chessverse_ai/features/social/presentation/daily_practice_cup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _PracticeApi extends CommunityApi {
  final state = {
    'id': 'cup', 'mySeat': 0,
    'seats': List.generate(6, (i) => {'name': 'Player $i', 'bot': i != 0}),
    'games': [{'number': 1, 'round': 1, 'white': 0, 'black': 5, 'result': '*'}],
  };
  String? played;
  int? expectedPly;
  @override
  Future<Map<String,dynamic>> joinDailyPractice(String token) async => state;
  @override
  Future<Map<String,dynamic>> dailyPracticeStandings(String token,String cup) async => state;
  @override
  Future<Map<String,dynamic>> practiceBoard(String token,String cup,int board,{String? move,int? ply}) async {
    played=move;
    expectedPly=ply;
    return {'cup':state,'board':1,'ply':move==null?0:2,'legal':['e2e4'],
      'fen':move==null?'4k3/8/8/8/8/8/4P3/4K3 w - - 0 1':'8/4k3/8/8/4P3/8/8/4K3 w - - 0 2'};
  }
}

void main() {
  testWidgets('registration shows only real entrants until the roster locks', (tester) async {
    final api=_PracticeApi();
    final full={...api.state};
    api.state.addAll({'lobbySeconds':5,'games':[], 'seats':[{'name':'Player 0','bot':false}]});
    await tester.pumpWidget(MaterialApp(home:DailyPracticeCupScreen(api:api,token:'test')));
    await tester.pump();
    expect(find.textContaining('1/6'), findsOneWidget);
    expect(find.byIcon(Icons.smart_toy),findsNothing);
    expect(find.byIcon(Icons.play_arrow),findsNothing);
    api.state.remove('lobbySeconds');
    api.state.addAll(full);
    await tester.pump(const Duration(seconds:5));
    await tester.pump();
    expect(find.byIcon(Icons.smart_toy),findsNWidgets(5));
    expect(find.byIcon(Icons.play_arrow),findsOneWidget);
  });
  test('all coach languages include the actual reply and stronger alternative', (){
    for(final locale in AppLanguageController.supported) {
      final text=liveReplyAdvice(locale.code,'c5f2','f2g2',{
        'attacker':'BISHOP','captured':'ROOK','check':true,'mate':false});
      expect(text,contains('c5 → f2+'));
      expect(text,contains('f2 → g2'));
      expect(text,isNot(contains('{p}')));
      if(locale.code=='te') expect(text,contains('తీసుకోగలడు'));
    }
  });
  testWidgets('roster uses bot icons and names stay clean on the board',(tester)async{
    final api=_PracticeApi();
    await tester.pumpWidget(MaterialApp(home:DailyPracticeCupScreen(api:api,token:'test')));
    await tester.pumpAndSettle();
    expect(find.text('Player 5'),findsOneWidget);
    expect(find.byIcon(Icons.smart_toy),findsNWidgets(5));
    expect(find.textContaining('· AI'),findsNothing);
    final pairing=find.text('Player 0  •  Player 5');
    await tester.ensureVisible(pairing);
    await tester.tap(pairing);
    await tester.pumpAndSettle();
    expect(pairing,findsOneWidget);
    expect(find.textContaining('· AI'),findsNothing);
    await tester.ensureVisible(find.text('e2'));
    await tester.tap(find.text('e2'));
    await tester.tap(find.text('e4'));
    await tester.pumpAndSettle();
    expect(api.played,'e2e4');
    expect(api.expectedPly,0);
  });
}
