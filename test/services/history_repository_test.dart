import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:universal_code_scanner/core/database/app_database.dart';
import 'package:universal_code_scanner/core/recovery/recovery_repository.dart';
import 'package:universal_code_scanner/core/security/payload_cipher.dart';
import 'package:universal_code_scanner/models/scan_record.dart';
import 'package:universal_code_scanner/services/history_repository.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  test('replaceAll atomically replaces the stored history', () async {
    final AppDatabase database = await AppDatabase.openTemporary();
    addTearDown(database.close);
    final HistoryRepository repository = HistoryRepository(
      database,
      PayloadCipher(keyProvider: MemoryEncryptionKeyProvider()),
      recovery: RecoveryRepository(database),
    );
    await repository.upsert(ScanRecord.manual(rawValue: 'old', format: 'QR', source: 'Test'));
    final ScanRecord replacement = ScanRecord.manual(rawValue: 'new', format: 'QR', source: 'Test');

    await repository.replaceAll(<ScanRecord>[replacement]);
    final List<ScanRecord> loaded = await repository.load();

    expect(loaded, hasLength(1));
    expect(loaded.single.id, replacement.id);
  });
}
