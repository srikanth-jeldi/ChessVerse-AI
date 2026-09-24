import 'package:chessverse_ai/features/auth/data/auth_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('auth conflicts keep stable user-facing messages', () {
    expect(
      authFriendlyErrorMessage(path: 'register', statusCode: 409),
      'An account already exists for this email. Open Login instead.',
    );
    expect(
      authFriendlyErrorMessage(path: 'login', statusCode: 401),
      'Invalid user ID or password.',
    );
    expect(
      authFriendlyErrorMessage(path: 'facebook', statusCode: 409),
      'Account already exists. Sign in first before linking Facebook.',
    );
    expect(
      authFriendlyErrorMessage(path: 'google', statusCode: 409),
      'Account already exists. Sign in first before linking Google.',
    );
  });

  test('other failures preserve a useful server message', () {
    expect(
      authFriendlyErrorMessage(
        path: 'verify-email',
        statusCode: 400,
        serverMessage: 'Incorrect verification code.',
      ),
      'Incorrect verification code.',
    );
  });
}
