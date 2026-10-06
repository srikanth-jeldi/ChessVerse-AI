import 'package:chessverse_ai/core/diagnostics/app_diagnostics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'diagnostic redaction removes credentials and masks email addresses',
    () {
      const String source =
          'Authorization: Bearer secret-token password=hunter2 '
          'accessToken=abc123 user@example.com '
          'eyJhbGciOiJIUzI1NiJ9.payload.signature';

      final String safe = AppDiagnostics.redact(source);

      expect(safe, isNot(contains('secret-token')));
      expect(safe, isNot(contains('hunter2')));
      expect(safe, isNot(contains('abc123')));
      expect(safe, isNot(contains('user@example.com')));
      expect(safe, contains('[REDACTED]'));
      expect(safe, contains('u***@example.com'));
    },
  );

  test('classifies recoverable network and disposed-player failures', () {
    expect(
      AppDiagnostics.isExpectedTransient(
        Exception(
          "SocketException: Failed host lookup: 'api.chessverseai.com'",
        ),
      ),
      isTrue,
    );
    expect(
      AppDiagnostics.isExpectedTransient(
        Exception(
          'Player has not yet been created or has already been disposed.',
        ),
      ),
      isTrue,
    );
    expect(
      AppDiagnostics.isExpectedTransient(StateError('invalid board state')),
      isFalse,
    );
  });
}
