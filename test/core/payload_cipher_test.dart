import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_code_scanner/core/security/payload_cipher.dart';

void main() {
  test('versioned envelope round-trips without exposing clear values', () async {
    final PayloadCipher cipher = PayloadCipher(keyProvider: MemoryEncryptionKeyProvider());
    final Map<String, dynamic> source = <String, dynamic>{'secret': 'wifi-password', 'count': 2};
    final String encrypted = await cipher.encryptJson(source);

    expect(encrypted, isNot(contains('wifi-password')));
    expect(cipher.inspect(encrypted).version, PayloadCipher.currentVersion);
    expect(await cipher.decryptJson(encrypted), source);
  });

  test('legacy envelope remains readable and can be upgraded', () async {
    final PayloadCipher cipher = PayloadCipher(keyProvider: MemoryEncryptionKeyProvider());
    final String current = await cipher.encryptJson(<String, dynamic>{'value': 'legacy-compatible'});
    final Map<String, dynamic> envelope = Map<String, dynamic>.from(jsonDecode(current) as Map);
    final String legacy = jsonEncode(envelope['payload']);

    expect(cipher.inspect(legacy).legacy, isTrue);
    expect((await cipher.decryptJson(legacy))['value'], 'legacy-compatible');
    expect(cipher.inspect(await cipher.upgradeEnvelope(legacy)).legacy, isFalse);
  });
  test('a missing decryption key is never replaced silently', () async {
    final MemoryEncryptionKeyProvider provider = MemoryEncryptionKeyProvider();
    final PayloadCipher cipher = PayloadCipher(keyProvider: provider);
    final String encrypted = await cipher.encryptJson(<String, dynamic>{'value': 'protected'});

    await provider.forget(PayloadCipher.currentKeyId);

    expect(provider.read(PayloadCipher.currentKeyId), completion(isNull));
    await expectLater(cipher.decryptJson(encrypted), throwsA(isA<StateError>()));
    await expectLater(cipher.encryptJson(<String, dynamic>{'new': 'value'}), throwsA(isA<StateError>()));
    expect(provider.read(PayloadCipher.currentKeyId), completion(isNull));
  });

  test('tampered authenticated ciphertext is rejected', () async {
    final PayloadCipher cipher = PayloadCipher(keyProvider: MemoryEncryptionKeyProvider());
    final String encrypted = await cipher.encryptJson(<String, dynamic>{'value': 'authentic'});
    final Map<String, dynamic> envelope = Map<String, dynamic>.from(jsonDecode(encrypted) as Map);
    final Map<String, dynamic> payload = Map<String, dynamic>.from(envelope['payload'] as Map);
    final List<int> bytes = base64Decode(payload['cipherText'] as String);
    bytes[0] ^= 0x01;
    payload['cipherText'] = base64Encode(bytes);
    envelope['payload'] = payload;

    await expectLater(cipher.decryptJson(jsonEncode(envelope)), throwsA(anything));
  });

  test('future cipher envelope versions are rejected explicitly', () async {
    final PayloadCipher cipher = PayloadCipher(keyProvider: MemoryEncryptionKeyProvider());
    final String encrypted = await cipher.encryptJson(<String, dynamic>{'value': 'future'});
    final Map<String, dynamic> envelope = Map<String, dynamic>.from(jsonDecode(encrypted) as Map)
      ..['version'] = PayloadCipher.currentVersion + 1;

    await expectLater(cipher.decryptJson(jsonEncode(envelope)), throwsA(isA<FormatException>()));
  });

}
