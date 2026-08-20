import 'package:chessverse_ai/features/social/data/community_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('community payload decodes clubs tournaments chat and fair-play score', () {
    final CommunityDto value = CommunityDto.fromJson(<String, dynamic>{
      'fairPlayScore': 95,
      'clubs': <Map<String, dynamic>>[
        <String, dynamic>{'id': 'c1', 'name': 'Royal Knights', 'members': 12, 'ratingRequirement': 1200, 'joined': true},
      ],
      'tournaments': <Map<String, dynamic>>[
        <String, dynamic>{'id': 't1', 'name': 'Rapid Arena', 'timeControlMinutes': 10, 'players': 64, 'capacity': 256, 'status': 'OPEN', 'joined': false},
      ],
      'conversations': <Map<String, dynamic>>[
        <String, dynamic>{'playerId': 'p1', 'displayName': 'KnightRaven', 'online': true, 'lastMessage': 'Ready?', 'unread': 2},
      ],
    });
    expect(value.fairPlayScore, 95);
    expect(value.clubs.single.joined, isTrue);
    expect(value.tournaments.single.minutes, 10);
    expect(value.conversations.single.unread, 2);
  });
}
