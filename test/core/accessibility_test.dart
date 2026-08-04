import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_code_scanner/core/database/app_database.dart';
import 'package:universal_code_scanner/core/recovery/recovery_repository.dart';
import 'package:universal_code_scanner/core/recovery/recovery_service.dart';
import 'package:universal_code_scanner/core/security/payload_cipher.dart';
import 'package:universal_code_scanner/features/recovery/recovery_screen.dart';

void main() {
  testWidgets('recovery center remains accessible with enlarged text', (WidgetTester tester) async {
    // The database and its readers rely on real timers, so they must be driven
    // outside the fake-async clock used by testWidgets.
    late final AppDatabase database;
    late final RecoveryService service;
    await tester.runAsync(() async {
      database = await AppDatabase.openTemporary();
      final PayloadCipher cipher = PayloadCipher(keyProvider: MemoryEncryptionKeyProvider());
      final RecoveryRepository repository = RecoveryRepository(database);
      service = RecoveryService(database, cipher, repository);
    });
    addTearDown(() => tester.runAsync(database.close));

    await tester.pumpWidget(MaterialApp(
      builder: (BuildContext context, Widget? child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: RecoveryScreen(service: service),
    ));
    // Let the pending read finish in real time before rebuilding and asserting.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();

    expect(find.text('Centro de recuperación'), findsOneWidget);
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}
