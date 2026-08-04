import 'package:flutter_test/flutter_test.dart';
import 'package:universal_code_scanner/core/database/app_database.dart';
import 'package:universal_code_scanner/core/recovery/recovery_issue.dart';
import 'package:universal_code_scanner/core/recovery/recovery_repository.dart';
import 'package:universal_code_scanner/core/recovery/recovery_service.dart';
import 'package:universal_code_scanner/core/security/payload_cipher.dart';

void main() {
  test('recovery bundle preserves ciphertext but never includes the key or clear payload', () async {
    final AppDatabase database = await AppDatabase.openTemporary();
    addTearDown(database.close);
    final MemoryEncryptionKeyProvider provider = MemoryEncryptionKeyProvider();
    final PayloadCipher cipher = PayloadCipher(keyProvider: provider);
    final RecoveryRepository repository = RecoveryRepository(database);
    final String encrypted = await cipher.encryptJson(<String, dynamic>{'password': 'never-export-clear'});
    await repository.record(
      entityType: RecoveryEntityType.history,
      entityId: 'record-one',
      code: 'test',
      encryptedPayload: encrypted,
    );

    final String bundle = await RecoveryService(database, cipher, repository).exportBundle();
    expect(bundle, contains('encryptedPayload'));
    expect(bundle, isNot(contains('never-export-clear')));
    expect(bundle, isNot(contains('ucs_database_key')));
  });
}
