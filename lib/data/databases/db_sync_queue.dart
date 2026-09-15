import 'package:sqflite/sqflite.dart';
import '../models/movement.dart';
import '../models/product.dart';
import '../models/sync_models.dart';
import 'db_helper.dart';

/// Outbox and conflict log. Enqueue helpers take the caller's transaction so a
/// local write and its sync job always commit together.
class SyncQueueDb {
  final DbHelper helper;

  SyncQueueDb(this.helper);

  static Future<void> enqueueProduct(DatabaseExecutor txn, Product product, DateTime now) async {
    // A newer edit replaces an older unsent one for the same product.
    await txn.delete(
      'sync_queue',
      where: 'entity = ? AND entity_uuid = ?',
      whereArgs: [SyncEntity.product.name, product.uuid],
    );
    await txn.insert(
      'sync_queue',
      SyncJob(
        entity: SyncEntity.product,
        entityUuid: product.uuid,
        operation: SyncOperation.upsert,
        payload: product.toJson(),
        createdAt: now,
      ).toMap(),
    );
  }

  static Future<void> enqueueMovement(DatabaseExecutor txn, Movement movement, DateTime now) =>
      txn.insert(
        'sync_queue',
        SyncJob(
          entity: SyncEntity.movement,
          entityUuid: movement.uuid,
          operation: SyncOperation.insert,
          payload: movement.toJson(),
          createdAt: now,
        ).toMap(),
      );

  /// Oldest first.
  Future<List<SyncJob>> pending({SyncEntity? entity, int? limit}) async {
    final db = await helper.database;
    final rows = await db.query(
      'sync_queue',
      where: entity == null ? null : 'entity = ?',
      whereArgs: entity == null ? null : [entity.name],
      orderBy: 'id ASC',
      limit: limit,
    );
    return rows.map(SyncJob.fromMap).toList();
  }

  Future<int> pendingCount() async {
    final db = await helper.database;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM sync_queue')) ?? 0;
  }

  Future<bool> hasPendingFor(SyncEntity entity, String uuid) async {
    final db = await helper.database;
    final rows = await db.query(
      'sync_queue',
      columns: ['id'],
      where: 'entity = ? AND entity_uuid = ?',
      whereArgs: [entity.name, uuid],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> remove(Iterable<int> ids) async {
    if (ids.isEmpty) return;
    final db = await helper.database;
    await db.delete('sync_queue', where: 'id IN (${_marks(ids.length)})', whereArgs: ids.toList());
  }

  Future<void> markFailed(Iterable<int> ids, String error, DateTime now) async {
    if (ids.isEmpty) return;
    final db = await helper.database;
    await db.rawUpdate(
      'UPDATE sync_queue SET attempts = attempts + 1, last_error = ?, last_attempt_at = ? '
      'WHERE id IN (${_marks(ids.length)})',
      [error, now.toUtc().toIso8601String(), ...ids],
    );
  }

  /// Rewrites a queued product payload, e.g. once its photo has been uploaded.
  Future<void> updatePayload(int id, Map<String, dynamic> payload) async {
    final db = await helper.database;
    final job = (await db.query('sync_queue', where: 'id = ?', whereArgs: [id])).firstOrNull;
    if (job == null) return;
    final updated = SyncJob.fromMap(job);
    await db.update(
      'sync_queue',
      SyncJob(
        id: id,
        entity: updated.entity,
        entityUuid: updated.entityUuid,
        operation: updated.operation,
        payload: payload,
        attempts: updated.attempts,
        lastError: updated.lastError,
        createdAt: updated.createdAt,
        lastAttemptAt: updated.lastAttemptAt,
      ).toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> addConflict(SyncConflict conflict) async {
    final db = await helper.database;
    await db.insert('sync_conflicts', conflict.toMap());
  }

  Future<List<SyncConflict>> conflicts() async {
    final db = await helper.database;
    final rows = await db.query('sync_conflicts', orderBy: 'created_at DESC', limit: 50);
    return rows.map(SyncConflict.fromMap).toList();
  }

  Future<void> dismissConflict(int id) async {
    final db = await helper.database;
    await db.delete('sync_conflicts', where: 'id = ?', whereArgs: [id]);
  }

  static String _marks(int n) => List.filled(n, '?').join(',');
}
