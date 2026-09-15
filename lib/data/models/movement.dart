import 'package:equatable/equatable.dart';

enum MovementReason {
  received,
  sold,
  adjusted,

  /// Correction committed by a stock count.
  counted;

  static MovementReason parse(String value) => MovementReason.values.firstWhere(
        (reason) => reason.name == value,
        orElse: () => MovementReason.adjusted,
      );
}

/// One row of the append-only ledger. Stock is always the sum of these.
class Movement extends Equatable {
  final String uuid;
  final String productUuid;
  final int delta;
  final MovementReason reason;
  final String? note;
  final DateTime createdAt;
  final String userId;
  final String userName;
  final bool synced;

  const Movement({
    required this.uuid,
    required this.productUuid,
    required this.delta,
    required this.reason,
    this.note,
    required this.createdAt,
    required this.userId,
    this.userName = '',
    this.synced = false,
  });

  Movement copyWith({bool? synced}) => Movement(
        uuid: uuid,
        productUuid: productUuid,
        delta: delta,
        reason: reason,
        note: note,
        createdAt: createdAt,
        userId: userId,
        userName: userName,
        synced: synced ?? this.synced,
      );

  Map<String, Object?> toMap() => {
        'uuid': uuid,
        'product_uuid': productUuid,
        'delta': delta,
        'reason': reason.name,
        'note': note,
        'created_at': createdAt.toUtc().toIso8601String(),
        'user_id': userId,
        'user_name': userName,
        'synced': synced ? 1 : 0,
      };

  factory Movement.fromMap(Map<String, Object?> map) => Movement(
        uuid: map['uuid'] as String,
        productUuid: map['product_uuid'] as String,
        delta: (map['delta'] as num).toInt(),
        reason: MovementReason.parse(map['reason'] as String),
        note: map['note'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
        userId: map['user_id'] as String,
        userName: (map['user_name'] as String?) ?? '',
        synced: map['synced'] == 1 || map['synced'] == true,
      );

  Map<String, Object?> toJson() {
    final json = toMap()..remove('synced');
    return json;
  }

  factory Movement.fromJson(Map<String, dynamic> json) =>
      Movement.fromMap({...json, 'synced': 1});

  @override
  List<Object?> get props =>
      [uuid, productUuid, delta, reason, note, createdAt, userId, userName, synced];
}
