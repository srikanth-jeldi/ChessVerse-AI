import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'community_api.dart';
import 'social_api.dart';

class E2eeSetupResult {
  const E2eeSetupResult({
    required this.ready,
    required this.friendReady,
    this.recoveryKey,
  });

  final bool ready;
  final bool friendReady;
  final String? recoveryKey;
}

class EncryptedChatAttachment {
  const EncryptedChatAttachment({required this.bytes, required this.envelope});
  final List<int> bytes;
  final String envelope;
}

/// Zero-knowledge direct-message encryption. The backend stores only public
/// keys, ciphertext and a recovery-key-wrapped copy of the private key.
class E2eeChatService {
  E2eeChatService({
    required this.api,
    FlutterSecureStorage? storage,
    Random? random,
  })  : storage = storage ?? const FlutterSecureStorage(),
        _random = random ?? Random.secure();

  final CommunityApi api;
  final FlutterSecureStorage storage;
  final Random _random;
  final X25519 _x25519 = X25519();
  final AesGcm _aes = AesGcm.with256bits();
  final Hkdf _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  static const int _iterations = 210000;
  static const String _prefix = 'cv1:';

  String? _playerId;
  SimpleKeyPairData? _identity;
  SimplePublicKey? _friendKey;

  bool get ready => _identity != null;
  bool get friendReady => _friendKey != null;

  /// Decrypts an incoming data-only push without contacting the backend.
  /// The private identity remains inside platform secure storage.
  Future<String?> decryptNotification(String envelope) async {
    final String? playerId =
        await storage.read(key: 'chat-e2ee-current-player');
    if (playerId == null || playerId.isEmpty) return null;
    _identity = await _readPair(playerId, null);
    if (_identity == null) return null;
    final String plaintext = await decrypt(envelope, mine: false);
    if (plaintext.startsWith('🔒')) return null;
    return plaintext;
  }

  Future<E2eeSetupResult> initialize(String token, String friendId) async {
    String? recoveryKey;
    Map<String, dynamic>? cloud;
    try {
      cloud = await api.e2eeIdentity(token);
      _playerId = cloud['playerId'] as String?;
    } on SocialException catch (error) {
      if (!error.message.toLowerCase().contains('no encrypted chat identity')) {
        rethrow;
      }
    }

    if (cloud == null) {
      final SimpleKeyPairData pair = await _newIdentity();
      recoveryKey = _encode(_randomBytes(32));
      final Map<String, Object?> upload = await _wrapIdentity(pair, recoveryKey);
      final Map<String, dynamic> saved =
          await api.saveE2eeIdentity(token, upload);
      _playerId = saved['playerId'] as String?;
      if (_playerId == null || _playerId!.isEmpty) {
        throw const SocialException('Encrypted chat identity setup failed.');
      }
      await _storePair(_playerId!, pair);
      _identity = pair;
    } else if (_playerId != null) {
      _identity = await _readPair(_playerId!, cloud['publicKey'] as String?);
    }

    try {
      final Map<String, dynamic> friend =
          await api.e2eePublicKey(token, friendId);
      _friendKey = SimplePublicKey(
        _decode(friend['publicKey'] as String),
        type: KeyPairType.x25519,
      );
    } on SocialException catch (error) {
      if (!error.message.toLowerCase().contains('not enabled')) rethrow;
      _friendKey = null;
    }
    return E2eeSetupResult(
      ready: ready,
      friendReady: friendReady,
      recoveryKey: recoveryKey,
    );
  }

  Future<void> restore(String token, String recoveryKey) async {
    final Map<String, dynamic> cloud = await api.e2eeIdentity(token);
    final String playerId = cloud['playerId'] as String;
    final SecretKey wrappingKey = await _recoveryKey(
      recoveryKey,
      _decode(cloud['backupSalt'] as String),
      (cloud['backupKdfIterations'] as num).toInt(),
    );
    try {
      final List<int> wrapped = _decode(cloud['encryptedPrivateKey'] as String);
      final List<int> nonce = _decode(cloud['backupNonce'] as String);
      final SecretBox box = SecretBox.fromConcatenation(
        wrapped,
        nonceLength: nonce.length,
        macLength: 16,
      );
      final List<int> privateBytes =
          await _aes.decrypt(box, secretKey: wrappingKey);
      final SimplePublicKey publicKey = SimplePublicKey(
        _decode(cloud['publicKey'] as String),
        type: KeyPairType.x25519,
      );
      final SimpleKeyPairData pair = SimpleKeyPairData(
        privateBytes,
        publicKey: publicKey,
        type: KeyPairType.x25519,
      );
      await _storePair(playerId, pair);
      _playerId = playerId;
      _identity = pair;
    } on SecretBoxAuthenticationError {
      throw const SocialException('Recovery key is incorrect.');
    } on FormatException {
      throw const SocialException('Recovery key is invalid.');
    }
  }

  Future<String> encrypt(String plaintext) async {
    final SimpleKeyPairData? identity = _identity;
    final SimplePublicKey? recipient = _friendKey;
    if (identity == null) {
      throw const SocialException('Restore your encrypted chat key first.');
    }
    if (recipient == null) {
      throw const SocialException(
          'Your friend must open chat once to enable encrypted messages.');
    }
    final SimpleKeyPairData ephemeral = await _newIdentity();
    final SimplePublicKey ephemeralPublic = await ephemeral.extractPublicKey();
    final SecretKey recipientSecret = await _shared(ephemeral, recipient);
    final SecretKey senderSecret =
        await _shared(ephemeral, await identity.extractPublicKey());
    final Map<String, Object> envelope = <String, Object>{
      'v': 1,
      'e': _encode(ephemeralPublic.bytes),
      'r': await _seal(plaintext, recipientSecret),
      's': await _seal(plaintext, senderSecret),
    };
    return '$_prefix${_encode(utf8.encode(jsonEncode(envelope)))}';
  }

  Future<EncryptedChatAttachment> encryptAttachment({
    required List<int> bytes,
    required String name,
    required String type,
    required String caption,
  }) async {
    final List<int> contentKey = _randomBytes(32);
    final SecretBox box = await _aes.encrypt(
      bytes,
      secretKey: SecretKey(contentKey),
      nonce: _randomBytes(12),
    );
    final String metadata = jsonEncode(<String, Object>{
      'kind': 'attachment',
      'key': _encode(contentKey),
      'name': name,
      'type': type,
      'size': bytes.length,
      'caption': caption,
    });
    return EncryptedChatAttachment(
      bytes: box.concatenation(),
      envelope: await encrypt(metadata),
    );
  }

  Future<List<int>> decryptAttachment(
      List<int> ciphertext, String encodedKey) async {
    final SecretBox box = SecretBox.fromConcatenation(
      ciphertext,
      nonceLength: 12,
      macLength: 16,
    );
    return _aes.decrypt(box, secretKey: SecretKey(_decode(encodedKey)));
  }

  Future<String> decrypt(String envelope, {required bool mine}) async {
    if (!envelope.startsWith(_prefix)) return envelope;
    final SimpleKeyPairData? identity = _identity;
    if (identity == null) return '🔒 Restore your recovery key to read this message';
    try {
      final Map<String, dynamic> decoded = jsonDecode(
        utf8.decode(_decode(envelope.substring(_prefix.length))),
      ) as Map<String, dynamic>;
      if (decoded['v'] != 1) throw const FormatException();
      final SimplePublicKey ephemeral = SimplePublicKey(
        _decode(decoded['e'] as String),
        type: KeyPairType.x25519,
      );
      final SecretKey secret = await _shared(identity, ephemeral);
      return await _open(decoded[mine ? 's' : 'r'] as String, secret);
    } catch (_) {
      return '🔒 Encrypted message could not be opened';
    }
  }

  Future<SimpleKeyPairData> _newIdentity() async {
    final KeyPair pair = await _x25519.newKeyPair();
    return (await pair.extract()) as SimpleKeyPairData;
  }

  Future<SecretKey> _shared(
      SimpleKeyPairData pair, SimplePublicKey remote) async {
    final SecretKey raw = await _x25519.sharedSecretKey(
      keyPair: pair,
      remotePublicKey: remote,
    );
    return _hkdf.deriveKey(
      secretKey: raw,
      nonce: utf8.encode('ChessVerseAI-chat-v1'),
    );
  }

  Future<String> _seal(String plaintext, SecretKey key) async {
    final SecretBox box = await _aes.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      nonce: _randomBytes(12),
    );
    return _encode(box.concatenation());
  }

  Future<String> _open(String value, SecretKey key) async {
    final SecretBox box = SecretBox.fromConcatenation(
      _decode(value),
      nonceLength: 12,
      macLength: 16,
    );
    return utf8.decode(await _aes.decrypt(box, secretKey: key));
  }

  Future<Map<String, Object?>> _wrapIdentity(
      SimpleKeyPairData pair, String recoveryKey) async {
    final List<int> salt = _randomBytes(16);
    final List<int> nonce = _randomBytes(12);
    final SecretKey key = await _recoveryKey(recoveryKey, salt, _iterations);
    final SecretBox wrapped = await _aes.encrypt(
      pair.bytes,
      secretKey: key,
      nonce: nonce,
    );
    final SimplePublicKey publicKey = await pair.extractPublicKey();
    return <String, Object?>{
      'publicKey': _encode(publicKey.bytes),
      'encryptedPrivateKey': _encode(wrapped.concatenation()),
      'backupSalt': _encode(salt),
      'backupNonce': _encode(nonce),
      'backupKdfIterations': _iterations,
    };
  }

  Future<SecretKey> _recoveryKey(
          String value, List<int> salt, int iterations) =>
      Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterations, bits: 256)
          .deriveKeyFromPassword(password: value.trim(), nonce: salt);

  Future<void> _storePair(String playerId, SimpleKeyPairData pair) async {
    await storage.write(key: 'chat-e2ee-$playerId-private', value: _encode(pair.bytes));
    final SimplePublicKey publicKey = await pair.extractPublicKey();
    await storage.write(key: 'chat-e2ee-$playerId-public', value: _encode(publicKey.bytes));
    await storage.write(key: 'chat-e2ee-current-player', value: playerId);
  }

  Future<SimpleKeyPairData?> _readPair(
      String playerId, String? cloudPublic) async {
    final String? privateValue =
        await storage.read(key: 'chat-e2ee-$playerId-private');
    final String? publicValue =
        await storage.read(key: 'chat-e2ee-$playerId-public');
    if (privateValue == null || (publicValue ?? cloudPublic) == null) return null;
    return SimpleKeyPairData(
      _decode(privateValue),
      publicKey: SimplePublicKey(
        _decode(publicValue ?? cloudPublic!),
        type: KeyPairType.x25519,
      ),
      type: KeyPairType.x25519,
    );
  }

  List<int> _randomBytes(int length) =>
      List<int>.generate(length, (_) => _random.nextInt(256), growable: false);
  String _encode(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');
  Uint8List _decode(String value) {
    final String padded = value.padRight((value.length + 3) ~/ 4 * 4, '=');
    return base64Url.decode(padded);
  }
}
