import 'dart:convert';

import 'package:chessverse_ai/features/social/data/community_api.dart';
import 'package:chessverse_ai/features/social/data/e2ee_chat_service.dart';
import 'package:chessverse_ai/features/social/data/social_api.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStorage extends FlutterSecureStorage {
  _MemoryStorage();
  final Map<String, String> values = <String, String>{};

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];
}

class _IdentityApi extends CommunityApi {
  _IdentityApi(this.ids);
  final Map<String, String> ids;
  final Map<String, Map<String, dynamic>> identities =
      <String, Map<String, dynamic>>{};

  @override
  Future<Map<String, dynamic>> e2eeIdentity(String token) async {
    final Map<String, dynamic>? value = identities[ids[token]];
    if (value == null) {
      throw const SocialException(
          'No encrypted chat identity exists for this account.');
    }
    return value;
  }

  @override
  Future<Map<String, dynamic>> saveE2eeIdentity(
      String token, Map<String, Object?> identity) async {
    final String id = ids[token]!;
    final Map<String, dynamic> saved = <String, dynamic>{
      ...identity,
      'playerId': id,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
    identities[id] = saved;
    return saved;
  }

  @override
  Future<Map<String, dynamic>> e2eePublicKey(
      String token, String friendId) async {
    final Map<String, dynamic>? value = identities[friendId];
    if (value == null) {
      throw const SocialException(
          'Your friend has not enabled encrypted chat yet.');
    }
    return <String, dynamic>{
      'playerId': friendId,
      'publicKey': value['publicKey'],
      'updatedAt': value['updatedAt'],
    };
  }
}

void main() {
  test('encrypts for recipient and sender and restores with recovery key',
      () async {
    const String alice = '11111111-1111-1111-1111-111111111111';
    const String bob = '22222222-2222-2222-2222-222222222222';
    final _IdentityApi api = _IdentityApi(<String, String>{'a': alice, 'b': bob});
    final E2eeChatService first =
        E2eeChatService(api: api, storage: _MemoryStorage());
    final E2eeSetupResult aliceSetup = await first.initialize('a', bob);
    expect(aliceSetup.recoveryKey, isNotNull);
    expect(aliceSetup.friendReady, isFalse);

    final E2eeChatService second =
        E2eeChatService(api: api, storage: _MemoryStorage());
    final E2eeSetupResult bobSetup = await second.initialize('b', alice);
    expect(bobSetup.friendReady, isTrue);
    await first.initialize('a', bob);

    final String envelope = await first.encrypt('private chess plan');
    expect(envelope, startsWith('cv1:'));
    expect(envelope, isNot(contains('private chess plan')));
    expect(await first.decrypt(envelope, mine: true), 'private chess plan');
    expect(await second.decrypt(envelope, mine: false), 'private chess plan');

    final EncryptedChatAttachment attachment = await first.encryptAttachment(
      bytes: <int>[1, 2, 3, 4, 5],
      name: 'analysis.png',
      type: 'image/png',
      caption: 'private position',
    );
    expect(attachment.bytes, isNot(<int>[1, 2, 3, 4, 5]));
    final Map<String, dynamic> attachmentMetadata = jsonDecode(
      await second.decrypt(attachment.envelope, mine: false),
    ) as Map<String, dynamic>;
    expect(attachmentMetadata['name'], 'analysis.png');
    expect(attachmentMetadata['caption'], 'private position');
    expect(
      await second.decryptAttachment(
        attachment.bytes,
        attachmentMetadata['key'] as String,
      ),
      <int>[1, 2, 3, 4, 5],
    );

    final E2eeChatService restored =
        E2eeChatService(api: api, storage: _MemoryStorage());
    await restored.restore('a', aliceSetup.recoveryKey!);
    expect(await restored.decrypt(envelope, mine: true), 'private chess plan');
  });

  test('wrong recovery key cannot unwrap account identity', () async {
    const String alice = '11111111-1111-1111-1111-111111111111';
    final _IdentityApi api = _IdentityApi(<String, String>{'a': alice});
    final E2eeChatService first =
        E2eeChatService(api: api, storage: _MemoryStorage());
    await first.initialize('a', 'missing-friend');
    final E2eeChatService restored =
        E2eeChatService(api: api, storage: _MemoryStorage());
    await expectLater(
      restored.restore('a', 'not-the-recovery-key'),
      throwsA(isA<SocialException>()),
    );
  });
}
