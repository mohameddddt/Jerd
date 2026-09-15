import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../databases/db_helper.dart';
import '../models/movement.dart';
import '../models/stock_count.dart';
import 'movements_db.dart';
import 'stock_count_repo.dart';

class StockCountDb implements StockCountRepo {
  final DbHelper helper;
  final DateTime Function() clock;

  StockCountDb(this.helper, {DateTime Function()? clock}) : clock = clock ?? DateTime.now;

  @override
  Future<ActiveCount?> getActive() async {
    final db = await helper.database;
    final counts = await db.query(
      'stock_counts',
      where: 'status = ?',
      whereArgs: [StockCountStatus.inProgress.name],
      orderBy: 'started_at DESC',
      limit: 1,
    );
    if (counts.isEmpty) return null;
    final count = StockCount.fromMap(counts.first);
    final lines = await db.query(
      'count_lines',
      where: 'count_uuid = ?',
      whereArgs: [count.uuid],
      orderBy: 'scanned_at ASC',
    );
    return ActiveCount(count, lines.map(CountLine.fromMap).toList());
  }

  @override
  Future<StockCount> start() async {
    final existing = await getActive();
    if (existing != null) return existing.count;
    final count = StockCount(uuid: const Uuid().v4(), startedAt: clock());
    final db = await helper.database;
    await db.insert('stock_counts', count.toMap());
    return count;
  }

  @override
  Future<void> saveLine(CountLine line) async {
    final db = await helper.database;
    // Keep the first scan time so the list keeps its counting order.
    await db.rawInsert(
      'INSERT INTO count_lines (count_uuid, product_uuid, counted_qty, scanned_at) '
      'VALUES (?, ?, ?, ?) '
      'ON CONFLICT(count_uuid, product_uuid) DO UPDATE SET counted_qty = excluded.counted_qty',
      [line.countUuid, line.productUuid, line.countedQty, line.scannedAt.toUtc().toIso8601String()],
    );
  }

  @override
  Future<void> commit(String countUuid, List<Movement> adjustments) async {
    final db = await helper.database;
    final now = clock();
    await db.transaction((txn) async {
      for (final movement in adjustments) {
        await MovementsDb.insertAndEnqueue(txn, movement, now);
      }
      await _close(txn, countUuid, StockCountStatus.committed, now);
    });
  }

  @override
  Future<void> cancel(String countUuid) async {
    final db = await helper.database;
    await db.transaction((txn) async {
      await _close(txn, countUuid, StockCountStatus.cancelled, clock());
      await txn.delete('count_lines', where: 'count_uuid = ?', whereArgs: [countUuid]);
    });
  }

  Future<void> _close(Transaction txn, String uuid, StockCountStatus status, DateTime now) =>
      txn.update(
        'stock_counts',
        {'status': status.name, 'finished_at': now.toUtc().toIso8601String()},
        where: 'uuid = ?',
        whereArgs: [uuid],
      );
}
