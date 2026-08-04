import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class EncryptionKeyProvider {
  Future<SecretKey?> read(String keyId);
  Future<SecretKey> readOrCreate(String keyId, AesGcm algorithm);
  Future<void> forget(String keyId);
}

class SecureStorageKeyProvider implements EncryptionKeyProvider {
  SecureStorageKeyProvider({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  static const String _prefix = 'ucs_database_key_';
  final FlutterSecureStorage _storage;
  final Map<String, SecretKey> _cache = <String, SecretKey>{};

  @override
  Future<SecretKey?> read(String keyId) async {
    final SecretKey? cached = _cache[keyId];
    if (cached != null) return cached;
    final String? encoded = await _storage.read(key: '$_prefix$keyId');
    if (encoded == null || encoded.isEmpty) return null;
    final SecretKey key = SecretKey(base64Decode(encoded));
    _cache[keyId] = key;
    return key;
  }

  @override
  Future<SecretKey> readOrCreate(String keyId, AesGcm algorithm) async {
    final SecretKey? existing = await read(keyId);
    if (existing != null) return existing;
    final SecretKey key = await algorithm.newSecretKey();
    await _storage.write(key: '$_prefix$keyId', value: base64Encode(await key.extractBytes()));
    _cache[keyId] = key;
    return key;
  }

  @override
  Future<void> forget(String keyId) async {
    _cache.remove(keyId);
    await _storage.delete(key: '$_prefix$keyId');
  }
}

class MemoryEncryptionKeyProvider implements EncryptionKeyProvider {
  final Map<String, SecretKey> _keys = <String, SecretKey>{};

  @override
  Future<SecretKey?> read(String keyId) async => _keys[keyId];

  @override
  Future<SecretKey> readOrCreate(String keyId, AesGcm algorithm) async {
    final SecretKey? existing = _keys[keyId];
    if (existing != null) return existing;
    final SecretKey created = await algorithm.newSecretKey();
    _keys[keyId] = created;
    return created;
  }

  @override
  Future<void> forget(String keyId) async => _keys.remove(keyId);
}

class CipherEnvelopeInfo {
  const CipherEnvelopeInfo({required this.version, required this.algorithm, required this.keyId, required this.legacy});
  final int version;
  final String algorithm;
  final String keyId;
  final bool legacy;
}

class PayloadCipher {
  PayloadCipher({EncryptionKeyProvider? keyProvider, String activeKeyId = currentKeyId})
      : _keyProvider = keyProvider ?? SecureStorageKeyProvider(),
        // ignore: prefer_initializing_formals
        _activeKeyId = activeKeyId;

  static const int currentVersion = 2;
  static const String currentAlgorithm = 'AES-256-GCM';
  static const String currentKeyId = 'v2';
  static const String legacyKeyId = 'v2';

  final EncryptionKeyProvider _keyProvider;
  String _activeKeyId;
  final AesGcm _algorithm = AesGcm.with256bits();
  final Set<String> _missingKeyIds = <String>{};

  String get activeKeyId => _activeKeyId;

  void activateKey(String keyId) {
    if (keyId.trim().isEmpty) throw ArgumentError.value(keyId, 'keyId');
    _activeKeyId = keyId;
  }

  Future<void> forgetKey(String keyId) async {
    _missingKeyIds.remove(keyId);
    await _keyProvider.forget(keyId);
  }

  Future<String> encryptJson(Map<String, dynamic> value, {String? keyId}) async {
    final String selectedKeyId = keyId ?? _activeKeyId;
    if (_missingKeyIds.contains(selectedKeyId)) {
      throw StateError('encryption_key_missing:$selectedKeyId');
    }
    final SecretBox box = await _algorithm.encryptString(
      jsonEncode(value),
      secretKey: await _keyProvider.readOrCreate(selectedKeyId, _algorithm),
    );
    return jsonEncode(<String, Object?>{
      'version': currentVersion,
      'algorithm': currentAlgorithm,
      'keyId': selectedKeyId,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'payload': <String, String>{
        'nonce': base64Encode(box.nonce),
        'cipherText': base64Encode(box.cipherText),
        'mac': base64Encode(box.mac.bytes),
      },
    });
  }

  CipherEnvelopeInfo inspect(String encoded) {
    final Map<String, dynamic> envelope = Map<String, dynamic>.from(jsonDecode(encoded) as Map);
    final bool legacy = !envelope.containsKey('version');
    return CipherEnvelopeInfo(
      version: legacy ? 1 : envelope['version'] as int? ?? 1,
      algorithm: legacy ? currentAlgorithm : envelope['algorithm'] as String? ?? currentAlgorithm,
      keyId: legacy ? legacyKeyId : envelope['keyId'] as String? ?? currentKeyId,
      legacy: legacy,
    );
  }

  Future<Map<String, dynamic>> decryptJson(String encoded) async {
    final Map<String, dynamic> envelope = Map<String, dynamic>.from(jsonDecode(encoded) as Map);
    final bool legacy = !envelope.containsKey('version');
    final int version = legacy ? 1 : envelope['version'] as int? ?? 1;
    if (version < 1 || version > currentVersion) {
      throw FormatException('Versión de cifrado no compatible: $version');
    }
    final String algorithm = legacy ? currentAlgorithm : envelope['algorithm'] as String? ?? currentAlgorithm;
    if (algorithm != currentAlgorithm) throw FormatException('Algoritmo no compatible: $algorithm');
    final String keyId = legacy ? legacyKeyId : envelope['keyId'] as String? ?? currentKeyId;
    final Map<String, dynamic> payload = legacy
        ? envelope
        : Map<String, dynamic>.from(envelope['payload'] as Map? ?? const <String, dynamic>{});
    final SecretBox box = SecretBox(
      base64Decode(payload['cipherText'] as String),
      nonce: base64Decode(payload['nonce'] as String),
      mac: Mac(base64Decode(payload['mac'] as String)),
    );
    final SecretKey? key = await _keyProvider.read(keyId);
    if (key == null) {
      _missingKeyIds.add(keyId);
      throw StateError('encryption_key_missing:$keyId');
    }
    _missingKeyIds.remove(keyId);
    final String clear = await _algorithm.decryptString(box, secretKey: key);
    return Map<String, dynamic>.from(jsonDecode(clear) as Map);
  }

  Future<String> upgradeEnvelope(String encoded) async {
    final CipherEnvelopeInfo info = inspect(encoded);
    if (!info.legacy && info.version == currentVersion && info.keyId == _activeKeyId) return encoded;
    return encryptJson(await decryptJson(encoded));
  }
}
