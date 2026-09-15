import 'package:sqflite/sqflite.dart';
import '../databases/db_helper.dart';
import '../databases/db_sync_queue.dart';
import '../models/movement.dart';
import 'movements_repo.dart';

class MovementsDb implements MovementsRepo {
  final DbHelper helper;
  final DateTime Function() clock;

  MovementsDb(this.helper, {DateTime Function()? clock}) : clock = clock ?? DateTime.now;

  @override
  Future<List<Movement>> getForProduct(String productUuid) async {
    final db = await helper.database;
    final rows = await db.query(
      'movements',
      where: 'product_uuid = ?',
      whereArgs: [productUuid],
      orderBy: 'created_at DESC',
    );
    return rows.map(Movement.fromMap).toList();
  }

  @override
  Future<List<Movement>> getBetween(DateTime start, DateTime end) async {
    final db = await helper.database;
    final rows = await db.query(
      'movements',
      where: 'created_at >= ? AND created_at < ?',
      whereArgs: [start.toUtc().toIso8601String(), end.toUtc().toIso8601String()],
      orderBy: 'created_at DESC',
    );
    return rows.map(Movement.fromMap).toList();
  }

  @override
  Future<Movement> add(Movement movement) async {
    final db = await helper.database;
    await db.transaction((txn) => insertAndEnqueue(txn, movement, clock()));
    return movement;
  }

  @override
  Future<void> addBatch(List<Movement> movements) async {
    final db = await helper.database;
    await db.transaction((txn) async {
      for (final movement in movements) {
        await insertAndEnqueue(txn, movement, clock());
      }
    });
  }

  /// Ledger row + outbox row in the caller's transaction.
  static Future<void> insertAndEnqueue(DatabaseExecutor txn, Movement movement, DateTime now) async {
    final inserted = await txn.insert(
      'movements',
      movement.copyWith(synced: false).toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    // A retried write with the same uuid must not queue twice.
    if (inserted != 0) await SyncQueueDb.enqueueMovement(txn, movement, now);
  }

  @override
  Future<int> getStock(String productUuid) async {
    final db = await helper.database;
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(delta), 0) AS stock FROM movements WHERE product_uuid = ?',
      [productUuid],
    );
    return (rows.first['stock'] as num).toInt();
  }

  @override
  Future<Map<String, int>> getAllStock() async {
    final db = await helper.database;
    final rows = await db.rawQuery(
      'SELECT product_uuid, SUM(delta) AS stock FROM movements GROUP BY product_uuid',
    );
    return {for (final row in rows) row['product_uuid'] as String: (row['stock'] as num).toInt()};
  }

  /// Rows pulled from the server: already synced, never re-queued.
  Future<int> applyRemote(List<Movement> movements) async {
    if (movements.isEmpty) return 0;
    final db = await helper.database;
    var added = 0;
    await db.transaction((txn) async {
      for (final movement in movements) {
        added += await txn.insert(
          'movements',
          movement.copyWith(synced: true).toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        ) ==
                0
            ? 0
            : 1;
      }
    });
    return added;
  }

  Future<void> markSynced(Iterable<String> uuids) async {
    if (uuids.isEmpty) return;
    final db = await helper.database;
    final list = uuids.toList();
    await db.update(
      'movements',
      {'synced': 1},
      where: 'uuid IN (${List.filled(list.length, '?').join(',')})',
      whereArgs: list,
    );
  }
}
