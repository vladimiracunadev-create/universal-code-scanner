class InventoryItem {
  const InventoryItem({
    required this.code,
    required this.format,
    required this.label,
    required this.quantity,
    required this.firstScannedAt,
    required this.lastScannedAt,
    this.notes = '',
  });

  final String code;
  final String format;
  final String label;
  final int quantity;
  final DateTime firstScannedAt;
  final DateTime lastScannedAt;
  final String notes;

  InventoryItem copyWith({int? quantity, DateTime? lastScannedAt, String? notes}) => InventoryItem(
        code: code,
        format: format,
        label: label,
        quantity: quantity ?? this.quantity,
        firstScannedAt: firstScannedAt,
        lastScannedAt: lastScannedAt ?? this.lastScannedAt,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'code': code,
        'format': format,
        'label': label,
        'quantity': quantity,
        'firstScannedAt': firstScannedAt.toIso8601String(),
        'lastScannedAt': lastScannedAt.toIso8601String(),
        'notes': notes,
      };

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        code: json['code'] as String,
        format: json['format'] as String? ?? 'Desconocido',
        label: json['label'] as String? ?? 'Producto',
        quantity: json['quantity'] as int? ?? 1,
        firstScannedAt: DateTime.parse(json['firstScannedAt'] as String),
        lastScannedAt: DateTime.parse(json['lastScannedAt'] as String),
        notes: json['notes'] as String? ?? '',
      );
}

class InventorySession {
  const InventorySession({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.items,
    this.closedAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime? closedAt;
  final Map<String, InventoryItem> items;

  bool get isOpen => closedAt == null;
  int get totalUnits => items.values.fold(0, (int sum, InventoryItem item) => sum + item.quantity);

  InventorySession copyWith({Map<String, InventoryItem>? items, DateTime? closedAt}) => InventorySession(
        id: id,
        name: name,
        createdAt: createdAt,
        closedAt: closedAt ?? this.closedAt,
        items: items ?? this.items,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'closedAt': closedAt?.toIso8601String(),
        'items': items.map((String key, InventoryItem value) => MapEntry(key, value.toJson())),
      };

  factory InventorySession.fromJson(Map<String, dynamic> json) => InventorySession(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        closedAt: json['closedAt'] == null ? null : DateTime.parse(json['closedAt'] as String),
        items: (json['items'] as Map<String, dynamic>? ?? <String, dynamic>{}).map(
          (String key, dynamic value) => MapEntry(key, InventoryItem.fromJson(Map<String, dynamic>.from(value as Map))),
        ),
      );
}
