import 'package:chessverse_ai/features/analysis/data/game_analysis_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses persistent every-ply analysis and ECO metadata', () {
    final CloudAnalysisJob job = CloudAnalysisJob.fromJson(<String, dynamic>{
      'job': <String, dynamic>{
        'id': 'job-1',
        'status': 'COMPLETED',
        'totalPlies': 2,
        'analyzedPlies': 2,
        'attemptCount': 1,
        'openingEco': 'B90',
        'openingName': 'Sicilian Defense: Najdorf Variation',
        'bookPlies': 10,
        'firstDeviationPly': 11,
      },
      'plies': <Map<String, dynamic>>[
        <String, dynamic>{
          'ply': 1,
          'fenBefore':
              'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
          'playedMove': 'e2e4',
          'bestMove': 'e2e4',
          'classification': 'Best',
          'coachingTheme': 'opening',
          'centipawnLoss': 0,
          'evaluationBeforeCp': 20,
          'evaluationAfterCp': 22,
          'mateBefore': null,
          'mateAfter': null,
          'principalVariation': <String>['e2e4', 'c7c5'],
          'depth': 16,
        },
      ],
    });

    expect(job.status, 'COMPLETED');
    expect(job.openingEco, 'B90');
    expect(job.firstDeviationPly, 11);
    expect(job.plies.single.fenBefore, contains(' w '));
    expect(job.plies.single.coachingTheme, 'opening');
    expect(job.plies.single.principalVariation, <String>['e2e4', 'c7c5']);
  });
}
