import 'package:chessverse_ai/features/social/data/social_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('social hub decodes friends, requests and live challenges', () {
    final SocialHubDto hub = SocialHubDto.fromJson(<String, dynamic>{
      'friends': <Map<String, dynamic>>[<String, dynamic>{
        'connectionId': 'link-1', 'playerId': 'player-2', 'username': 'rival',
        'displayName': 'Knight Rival', 'country': 'India', 'rating': 1542,
        'online': true, 'relationship': 'FRIEND',
      }],
      'incomingRequests': <Map<String, dynamic>>[],
      'outgoingRequests': <Map<String, dynamic>>[],
      'challenges': <Map<String, dynamic>>[<String, dynamic>{
        'id': 'challenge-1', 'opponentName': 'Knight Rival',
        'timeControlMinutes': 5, 'roomCode': 'CV1234', 'matchId': 'match-1',
        'status': 'PENDING', 'incoming': true,
        'expiresAt': '2026-08-20T15:30:00Z',
      }],
    });

    expect(hub.friends.single.online, isTrue);
    expect(hub.friends.single.rating, 1542);
    expect(hub.challenges.single.incoming, isTrue);
    expect(hub.challenges.single.minutes, 5);
  });
}
