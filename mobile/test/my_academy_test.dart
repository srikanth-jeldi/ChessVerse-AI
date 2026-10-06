import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:chessverse_ai/core/academy_activity.dart';
import 'package:chessverse_ai/features/academy/data/academy_api.dart';
import 'package:chessverse_ai/features/academy/presentation/my_academy_screen.dart';

void main() {
  for(final joined in [false,true]) {
    testWidgets('Mistake Bank sharing is visible only for joined active students: $joined',(tester) async {
      final client=MockClient((request) async {
        final path=request.url.path;
        final Object body=path.endsWith('/me')?{'organizations':joined?[{'id':'org-a','name':'Test Academy','role':'STUDENT'}]:[]}:
          path.endsWith('/workspace')?{'students':[{'id':'s1','account_id':'student','name':'Student','active':true}],'members':[],'batches':[],'assignments':[],'reports':[]}:
          path.endsWith('/app-activity')?{'sharing':[]}:[];
        return http.Response(jsonEncode(body),200,headers:{'content-type':'application/json'});
      });
      await tester.pumpWidget(MaterialApp(home:MyAcademyScreen(token:'student-token',api:AcademyApi('student-token',client:client),onPuzzle:(_) async {},onPosition:(_,_,_) async {})));
      await tester.pumpAndSettle();
      final toggle=find.text('Share Mistake Bank positions and review progress');
      if(joined){
        await tester.scrollUntilVisible(toggle,200,scrollable:find.byType(Scrollable).first);
        expect(toggle,findsOneWidget);
        final widget=tester.widget<SwitchListTile>(find.ancestor(of:toggle,matching:find.byType(SwitchListTile)));
        expect(widget.value,false);expect(widget.onChanged,isNull);
      }else{expect(toggle,findsNothing);}
    });
  }
  test('practice capture counts only matching assignment and avoids repeat completions', () {
    final capture = AcademyPracticeCapture(puzzleId: 'easy-1');
    capture.puzzleCompleted('easy-2');
    expect(capture.attempts, 0);
    capture.puzzleCompleted('easy-1');
    capture.puzzleCompleted('easy-1');
    expect(capture.attempts, 1);
    expect(capture.solved, true);
    final position = AcademyPracticeCapture(position: true);
    position.positionAttempt(false);
    position.positionAttempt(true);
    expect(position.attempts, 2);
    expect(position.solved, true);
  });
  testWidgets('student opens assigned puzzle and submits only to its academy', (
    tester,
  ) async {
    final requests = <http.Request>[];
    bool completed = false;
    final client = MockClient((request) async {
      requests.add(request);
      expect(request.headers['Authorization'], 'Bearer student-token');
      final path = request.url.path;
      dynamic body;
      if (path.endsWith('/me')) {
        body = {
          'organizations': [
            {'id': 'org-a', 'name': 'Test Academy', 'role': 'STUDENT'},
          ],
        };
      } else if (path.endsWith('/workspace')) {
        body = {
          'students': [
            {'id': 's1', 'account_id': 'student', 'name': 'Student'},
          ],
          'members': [],
          'batches': [],
          'assignments': [
            {
              'id': 'task-1',
              'title': 'Fork practice',
              'kind': 'PUZZLES',
              'instructions': 'Find the fork',
              'puzzle_id': 'easy-1',
              'due_date': '2026-10-10',
              'completed_at': completed ? 'now' : null,
            },
          ],
          'reports': [],
        };
      } else if (path.endsWith('/app-activity')) {
        body = {'sharing': []};
      } else if (path.endsWith('/announcements')) {
        body = [];
      } else if (path.endsWith('/results')) {
        expect(path, '/api/v1/academy/org-a/assignments/task-1/results');
        final payload = jsonDecode(request.body);
        expect(payload['solved'], true);
        expect(payload['attempts'], 1);
        expect(payload.containsKey('studentId'), false);
        completed = true;
        return http.Response('', 200);
      } else {
        return http.Response('{}', 404);
      }
      return http.Response(
        jsonEncode(body),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    await tester.pumpWidget(
      MaterialApp(
        home: MyAcademyScreen(
          token: 'student-token',
          api: AcademyApi('student-token', client: client),
          onPuzzle: (id) async {
            expect(id, 'easy-1');
            AcademyPracticeCapture.active!.puzzleCompleted(id);
          },
          onPosition: (_, _, _) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Test Academy'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Start practice'),
      250,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start practice'));
    await tester.pumpAndSettle();
    expect(find.text('Practice complete'), findsOneWidget);
    await tester.tap(find.text('Submit to coach'));
    await tester.pumpAndSettle();
    expect(completed, true);
    expect(AcademyPracticeCapture.active, isNull);
    expect(requests.where((r) => r.url.path.endsWith('/results')).length, 1);
  });
}
