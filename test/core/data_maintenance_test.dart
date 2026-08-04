import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:universal_code_scanner/core/database/app_database.dart';
import 'package:universal_code_scanner/core/security/data_maintenance_service.dart';
import 'package:universal_code_scanner/core/security/encryption_metadata_repository.dart';
import 'package:universal_code_scanner/core/security/payload_cipher.dart';


class _TrackingKeyProvider implements EncryptionKeyProvider {
  final MemoryEncryptionKeyProvider delegate = MemoryEncryptionKeyProvider();
  String? lastCreated;
  final Set<String> forgotten = <String>{};

  @override
  Future<void> forget(String keyId) async {
    forgotten.add(keyId);
    await delegate.forget(keyId);
  }

  @override
  Future<SecretKey?> read(String keyId) => delegate.read(keyId);

  @override
  Future<SecretKey> readOrCreate(String keyId, AesGcm algorithm) async {
    if (await delegate.read(keyId) == null) lastCreated = keyId;
    return delegate.readOrCreate(keyId, algorithm);
  }
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  test('key rotation updates records and active metadata in one database transaction', () async {
    final AppDatabase database = await AppDatabase.openTemporary();
    addTearDown(database.close);
    final MemoryEncryptionKeyProvider provider = MemoryEncryptionKeyProvider();
    final PayloadCipher cipher = PayloadCipher(keyProvider: provider);
    final EncryptionMetadataRepository metadata = EncryptionMetadataRepository(database);
    final StoreRef<String, Map<String, Object?>> history = stringMapStoreFactory.store('scan_history');
    await metadata.saveActiveKeyId(PayloadCipher.currentKeyId);
    final String oldPayload = await cipher.encryptJson(<String, dynamic>{'id': 'one'});
    await history.record('one').put(database.database, <String, Object?>{'payload': oldPayload});

    final EncryptionRotationResult result = await DataMaintenanceService(database, cipher, metadata).rotateEncryptionKey();
    final Map<String, Object?> rotated = (await history.record('one').get(database.database))!;

    expect(result.historyRecords, 1);
    expect(await metadata.loadActiveKeyId(), result.keyId);
    expect(cipher.inspect(rotated['payload']! as String).keyId, result.keyId);
    expect(await cipher.decryptJson(rotated['payload']! as String), <String, dynamic>{'id': 'one'});
  });

  test('rotation aborts before changing metadata when a payload is incomplete', () async {
    final AppDatabase database = await AppDatabase.openTemporary();
    addTearDown(database.close);
    final PayloadCipher cipher = PayloadCipher(keyProvider: MemoryEncryptionKeyProvider());
    final EncryptionMetadataRepository metadata = EncryptionMetadataRepository(database);
    final StoreRef<String, Map<String, Object?>> history = stringMapStoreFactory.store('scan_history');
    await metadata.saveActiveKeyId(PayloadCipher.currentKeyId);
    await history.record('broken').put(database.database, <String, Object?>{'id': 'broken'});

    await expectLater(
      DataMaintenanceService(database, cipher, metadata).rotateEncryptionKey(),
      throwsA(isA<StateError>()),
    );
    expect(await metadata.loadActiveKeyId(), PayloadCipher.currentKeyId);
  });

  test('failed rotation removes a newly generated orphan key', () async {
    final AppDatabase database = await AppDatabase.openTemporary();
    addTearDown(database.close);
    final _TrackingKeyProvider provider = _TrackingKeyProvider();
    final PayloadCipher cipher = PayloadCipher(keyProvider: provider);
    final EncryptionMetadataRepository metadata = EncryptionMetadataRepository(database);
    final StoreRef<String, Map<String, Object?>> history = stringMapStoreFactory.store('scan_history');
    final StoreRef<String, Map<String, Object?>> inventory = stringMapStoreFactory.store('inventory_sessions');
    await metadata.saveActiveKeyId(PayloadCipher.currentKeyId);
    await history.record('valid').put(database.database, <String, Object?>{
      'payload': await cipher.encryptJson(<String, dynamic>{'id': 'valid'}),
    });
    await inventory.record('broken').put(database.database, <String, Object?>{'id': 'broken'});

    await expectLater(
      DataMaintenanceService(database, cipher, metadata).rotateEncryptionKey(),
      throwsA(isA<StateError>()),
    );

    expect(provider.lastCreated, isNotNull);
    expect(provider.forgotten, contains(provider.lastCreated));
    expect(await provider.read(provider.lastCreated!), isNull);
    expect(await metadata.loadActiveKeyId(), PayloadCipher.currentKeyId);
  });
}
