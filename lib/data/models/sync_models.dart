import 'dart:convert';
import 'package:equatable/equatable.dart';

enum SyncEntity { product, movement }

enum SyncOperation { upsert, insert }

/// A row of the outbox: a local change the server has not accepted yet.
class SyncJob extends Equatable {
  final int? id;
  final SyncEntity entity;
  final String entityUuid;
  final SyncOperation operation;
  final Map<String, dynamic> payload;
  final int attempts;
  final String? lastError;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;

  const SyncJob({
    this.id,
    required this.entity,
    required this.entityUuid,
    required this.operation,
    required this.payload,
    this.attempts = 0,
    this.lastError,
    required this.createdAt,
    this.lastAttemptAt,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'entity': entity.name,
        'entity_uuid': entityUuid,
        'operation': operation.name,
        'payload': jsonEncode(payload),
        'attempts': attempts,
        'last_error': lastError,
        'created_at': createdAt.toUtc().toIso8601String(),
        'last_attempt_at': lastAttemptAt?.toUtc().toIso8601String(),
      };

  factory SyncJob.fromMap(Map<String, Object?> map) => SyncJob(
        id: map['id'] as int?,
        entity: SyncEntity.values.byName(map['entity'] as String),
        entityUuid: map['entity_uuid'] as String,
        operation: SyncOperation.values.byName(map['operation'] as String),
        payload: jsonDecode(map['payload'] as String) as Map<String, dynamic>,
        attempts: (map['attempts'] as num?)?.toInt() ?? 0,
        lastError: map['last_error'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
        lastAttemptAt: map['last_attempt_at'] == null
            ? null
            : DateTime.parse(map['last_attempt_at'] as String).toLocal(),
      );

  @override
  List<Object?> get props =>
      [id, entity, entityUuid, operation, payload, attempts, lastError, createdAt, lastAttemptAt];
}

/// The losing side of a last-write-wins product conflict, kept for the user to inspect.
class SyncConflict extends Equatable {
  final int? id;
  final String productUuid;
  final String keptName;
  final String keptBy;
  final DateTime keptAt;
  final String lostName;
  final String lostBy;
  final DateTime lostAt;
  final DateTime createdAt;

  const SyncConflict({
    this.id,
    required this.productUuid,
    required this.keptName,
    required this.keptBy,
    required this.keptAt,
    required this.lostName,
    required this.lostBy,
    required this.lostAt,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'product_uuid': productUuid,
        'kept_name': keptName,
        'kept_by': keptBy,
        'kept_at': keptAt.toUtc().toIso8601String(),
        'lost_name': lostName,
        'lost_by': lostBy,
        'lost_at': lostAt.toUtc().toIso8601String(),
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  factory SyncConflict.fromMap(Map<String, Object?> map) => SyncConflict(
        id: map['id'] as int?,
        productUuid: map['product_uuid'] as String,
        keptName: map['kept_name'] as String,
        keptBy: map['kept_by'] as String,
        keptAt: DateTime.parse(map['kept_at'] as String).toLocal(),
        lostName: map['lost_name'] as String,
        lostBy: map['lost_by'] as String,
        lostAt: DateTime.parse(map['lost_at'] as String).toLocal(),
        createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      );

  @override
  List<Object?> get props =>
      [id, productUuid, keptName, keptBy, keptAt, lostName, lostBy, lostAt, createdAt];
}

/// What one sync run achieved.
class SyncReport extends Equatable {
  final int pushed;
  final int pulled;
  final int conflicts;
  final DateTime finishedAt;

  const SyncReport({
    required this.pushed,
    required this.pulled,
    required this.conflicts,
    required this.finishedAt,
  });

  @override
  List<Object?> get props => [pushed, pulled, conflicts, finishedAt];
}
