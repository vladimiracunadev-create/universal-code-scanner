import 'package:universal_code_scanner/core/database/app_database.dart';
import 'package:universal_code_scanner/core/recovery/recovery_repository.dart';
import 'package:universal_code_scanner/core/recovery/recovery_service.dart';
import 'package:universal_code_scanner/core/security/payload_cipher.dart';
import 'package:universal_code_scanner/core/security/encryption_metadata_repository.dart';
import 'package:universal_code_scanner/core/security/data_maintenance_service.dart';
import 'package:universal_code_scanner/services/history_repository.dart';
import 'package:universal_code_scanner/services/inventory_repository.dart';
import 'package:universal_code_scanner/services/settings_repository.dart';
import 'package:universal_code_scanner/state/inventory_store.dart';
import 'package:universal_code_scanner/state/scan_store.dart';
import 'package:universal_code_scanner/state/settings_store.dart';

class AppServices {
  const AppServices({
    required this.database,
    required this.scanStore,
    required this.inventoryStore,
    required this.settingsStore,
    required this.recoveryRepository,
    required this.recoveryService,
    required this.dataMaintenanceService,
  });

  final AppDatabase database;
  final ScanStore scanStore;
  final InventoryStore inventoryStore;
  final SettingsStore settingsStore;
  final RecoveryRepository recoveryRepository;
  final RecoveryService recoveryService;
  final DataMaintenanceService dataMaintenanceService;

  bool get temporary => database.temporary;
}

abstract final class AppBootstrapper {
  static Future<AppServices> initialize({bool temporary = false}) async {
    AppDatabase? database;
    try {
      database = temporary ? await AppDatabase.openTemporary() : await AppDatabase.open();
      final RecoveryRepository recovery = RecoveryRepository(database);
      final EncryptionMetadataRepository encryptionMetadata = EncryptionMetadataRepository(database);
      final String activeKeyId = temporary ? PayloadCipher.currentKeyId : await encryptionMetadata.loadActiveKeyId();
      final PayloadCipher cipher = PayloadCipher(
        keyProvider: temporary ? MemoryEncryptionKeyProvider() : null,
        activeKeyId: activeKeyId,
      );
      final SettingsStore settings = SettingsStore(SettingsRepository());
      final ScanStore scans = ScanStore(HistoryRepository(database, cipher, recovery: recovery));
      final InventoryStore inventory = InventoryStore(InventoryRepository(database, cipher, recovery: recovery));

      if (temporary) {
        try {
          await settings.initialize();
        } on Object {
          // Temporary mode remains available even when preferences are unavailable.
        }
      } else {
        await settings.initialize();
      }
      await Future.wait(<Future<void>>[scans.initialize(), inventory.initialize()]);
      await scans.pruneOlderThan(settings.value.historyRetentionDays);
      return AppServices(
        database: database,
        scanStore: scans,
        inventoryStore: inventory,
        settingsStore: settings,
        recoveryRepository: recovery,
        recoveryService: RecoveryService(database, cipher, recovery),
        dataMaintenanceService: DataMaintenanceService(database, cipher, encryptionMetadata),
      );
    } on Object {
      await database?.close();
      rethrow;
    }
  }
}
