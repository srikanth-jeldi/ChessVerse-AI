import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../features/auth/data/auth_session_store.dart';
import 'config/app_config.dart';

/// Best-effort practice telemetry. The server records only opted-in students.
/// No board position, personal game contents or opponent details are sent.
Future<void> recordAcademyPositionRetry(bool correct) async {
  AcademyPracticeCapture.active?.positionAttempt(correct);
  if (AcademyPracticeCapture.active != null) return;
  await _recordPractice('position-retries', {
    'id': const Uuid().v4(),
    'correct': correct,
  });
}

Future<void> recordAcademyPuzzleCompletion(String puzzleId) async {
  AcademyPracticeCapture.active?.puzzleCompleted(puzzleId);
  if (AcademyPracticeCapture.inSprint ||
      AcademyPracticeCapture.active != null) {
    return;
  }
  await _recordPractice('puzzle-completions', {'puzzleId': puzzleId});
}

class AcademyPracticeCapture {
  AcademyPracticeCapture({this.puzzleId, this.position = false});
  static AcademyPracticeCapture? active;
  static bool inSprint = false;
  final String? puzzleId;
  final bool position;
  int attempts = 0;
  bool solved = false;
  void positionAttempt(bool correct) {
    if (position) {
      attempts++;
      solved = solved || correct;
    }
  }

  void puzzleCompleted(String id) {
    if (!position && !solved && (puzzleId == null || id == puzzleId)) {
      attempts++;
      solved = true;
    }
  }
}

Future<void> _recordPractice(String path, Map<String, Object> body) async {
  try {
    final session = await const AuthSessionStore().read();
    if (session == null || session.isGuest || session.isExpired) return;
    await http
        .post(
          Uri.parse('${AppConfig.apiBaseUrl}/api/v1/puzzle-sprints/$path'),
          headers: {
            'Authorization': 'Bearer ${session.token}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 8));
  } catch (_) {
    // Practice remains usable offline. Do not report a sync success to the user.
  }
}
