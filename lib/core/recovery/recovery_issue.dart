enum RecoveryEntityType { history, inventory, migration, database, startup }

enum RecoveryIssueState { unresolved, recovered, deleted }

class RecoveryIssue {
  const RecoveryIssue({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.detectedAt,
    required this.code,
    required this.state,
    this.encryptedPayload,
  });

  final String id;
  final RecoveryEntityType entityType;
  final String entityId;
  final DateTime detectedAt;
  final String code;
  final RecoveryIssueState state;
  final String? encryptedPayload;

  RecoveryIssue copyWith({RecoveryIssueState? state}) => RecoveryIssue(
        id: id,
        entityType: entityType,
        entityId: entityId,
        detectedAt: detectedAt,
        code: code,
        state: state ?? this.state,
        encryptedPayload: encryptedPayload,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'entityType': entityType.name,
        'entityId': entityId,
        'detectedAt': detectedAt.toIso8601String(),
        'code': code,
        'state': state.name,
        'encryptedPayload': encryptedPayload,
      };

  factory RecoveryIssue.fromJson(Map<String, Object?> json) => RecoveryIssue(
        id: json['id'] as String,
        entityType: RecoveryEntityType.values.byName(json['entityType'] as String),
        entityId: json['entityId'] as String,
        detectedAt: DateTime.parse(json['detectedAt'] as String),
        code: json['code'] as String,
        state: RecoveryIssueState.values.byName(json['state'] as String),
        encryptedPayload: json['encryptedPayload'] as String?,
      );
}
