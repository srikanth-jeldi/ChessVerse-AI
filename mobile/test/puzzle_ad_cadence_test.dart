import 'package:chessverse_ai/core/ads/post_match_ad_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test('every third completion, duplicate callbacks and restart', () async {
    final service = PostMatchAdService.forTesting();
    expect(await service.recordPuzzleCompletion('one'), false);
    expect(await service.recordPuzzleCompletion('one'), false);
    expect(await service.recordPuzzleCompletion('two'), false);
    final restarted = PostMatchAdService.forTesting();
    expect(await restarted.recordPuzzleCompletion('three'), true);
    expect(await restarted.recordPuzzleCompletion('three'), true);
    expect(await restarted.recordPuzzleCompletion('four'), false);
  });
  test('concurrent completions retain the three-puzzle cadence', () async {
    final service = PostMatchAdService.forTesting();
    expect(
      await Future.wait(
        List.generate(6, (i) => service.recordPuzzleCompletion('$i')),
      ),
      [false, false, true, false, false, true],
    );
  });
}
