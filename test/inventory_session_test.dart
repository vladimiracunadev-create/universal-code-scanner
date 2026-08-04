import 'package:flutter_test/flutter_test.dart';
import 'package:universal_code_scanner/models/inventory_session.dart';

void main() {
  test('calcula unidades y conserva datos al serializar', () {
    final DateTime now = DateTime.utc(2026, 8, 2);
    final InventorySession session = InventorySession(
      id: 'session-1',
      name: 'Bodega principal',
      createdAt: now,
      items: <String, InventoryItem>{
        '7801234567890': InventoryItem(
          code: '7801234567890',
          format: 'EAN-13',
          label: 'Producto',
          quantity: 3,
          firstScannedAt: now,
          lastScannedAt: now,
        ),
      },
    );

    final InventorySession restored = InventorySession.fromJson(session.toJson());

    expect(session.totalUnits, 3);
    expect(restored.name, 'Bodega principal');
    expect(restored.items['7801234567890']?.quantity, 3);
    expect(restored.isOpen, isTrue);
  });
}
