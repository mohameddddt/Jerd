import 'package:flutter_test/flutter_test.dart';
import 'package:jerd/data/databases/db_helper.dart';
import 'package:jerd/data/databases/db_sync_queue.dart';
import 'package:jerd/data/models/movement.dart';
import 'package:jerd/data/models/stock_count.dart';
import 'package:jerd/data/models/sync_models.dart';
import 'package:jerd/data/repositories/movements_db.dart';
import 'package:jerd/data/repositories/products_db.dart';
import 'package:jerd/data/repositories/repo_exceptions.dart';
import 'package:jerd/data/repositories/stock_count_db.dart';
import 'package:jerd/logic/domain/stock_from_ledger.dart';
import '../helpers.dart';

void main() {
  late DbHelper db;
  late ProductsDb products;
  late MovementsDb movements;
  late SyncQueueDb queue;

  setUp(() {
    db = memoryDb();
    products = ProductsDb(db, clock: () => testNow);
    movements = MovementsDb(db, clock: () => testNow);
    queue = SyncQueueDb(db);
  });

  tearDown(() => db.close());

  group('ProductsDb', () {
    test('save writes the row and queues one sync job in the same transaction', () async {
      await products.save(aProduct());
      expect((await products.getProducts()).single.name, 'Olive oil 1L');
      final jobs = await queue.pending();
      expect(jobs.single.entity, SyncEntity.product);
      expect(jobs.single.payload['name'], 'Olive oil 1L');
    });

    test('a second edit replaces the unsent job instead of stacking', () async {
      await products.save(aProduct());
      await products.save(aProduct(name: 'Olive oil 1 litre'));
      final jobs = await queue.pending();
      expect(jobs, hasLength(1));
      expect(jobs.single.payload['name'], 'Olive oil 1 litre');
    });

    test('rejects a barcode that belongs to another product, and writes nothing', () async {
      await products.save(aProduct(uuid: 'sugar', name: 'Sugar 1kg', barcode: '6130000100034'));
      await expectLater(
        products.save(aProduct(uuid: 'oil', barcode: '6130000100034')),
        throwsA(isA<DuplicateBarcodeException>().having((e) => e.existingName, 'name', 'Sugar 1kg')),
      );
      expect(await products.getById('oil'), isNull);
      expect(await queue.pendingCount(), 1);
    });

    test('repository validation catches what a form might miss', () async {
      await expectLater(products.save(aProduct(name: '  ')), throwsA(isA<ValidationException>()));
      await expectLater(products.save(aProduct(reorder: -1)), throwsA(isA<ValidationException>()));
    });

    test('delete is soft and syncs', () async {
      await products.save(aProduct());
      await products.delete('p1', by: 'Karim');
      expect(await products.getProducts(), isEmpty);
      expect(await products.getByBarcode('6130000100010'), isNull);
      expect((await queue.pending()).single.payload['deleted'], true);
    });

    test('barcode lookup stays fast at 2,000 products', () async {
      final database = await db.database;
      await database.transaction((txn) async {
        for (var i = 0; i < 2000; i++) {
          await ProductsDb.writeLocal(
            txn,
            aProduct(uuid: 'p$i', name: 'Item $i', barcode: '${6130000000000 + i}'),
          );
        }
      });
      final watch = Stopwatch()..start();
      final found = await products.getByBarcode('${6130000000000 + 1999}');
      watch.stop();
      expect(found?.uuid, 'p1999');
      expect(watch.elapsedMilliseconds, lessThan(1000));
    });
  });

  group('MovementsDb', () {
    test('displayed stock always equals the sum of the ledger', () async {
      final ledger = [
        aMovement(uuid: 'a', delta: 25),
        aMovement(uuid: 'b', delta: -17, reason: MovementReason.sold),
        aMovement(uuid: 'c', delta: -2, reason: MovementReason.adjusted),
        aMovement(uuid: 'd', product: 'p2', delta: 7),
      ];
      for (final m in ledger) {
        await movements.add(m);
      }
      expect(await movements.getStock('p1'), stockFromLedger(ledger.where((m) => m.productUuid == 'p1')));
      expect(await movements.getAllStock(), stockByProduct(ledger));
    });

    test('every write enqueues a sync job; a retried write does not double-apply', () async {
      await movements.add(aMovement(uuid: 'same'));
      await movements.add(aMovement(uuid: 'same'));
      expect(await movements.getStock('p1'), 10);
      expect(await queue.pendingCount(), 1);
    });

    test('history is newest first', () async {
      await movements.add(aMovement(uuid: 'old', at: DateTime(2026, 9, 13)));
      await movements.add(aMovement(uuid: 'new', at: DateTime(2026, 9, 14)));
      expect((await movements.getForProduct('p1')).map((m) => m.uuid), ['new', 'old']);
    });

    test('remote rows are stored as synced and never queued', () async {
      final added = await movements.applyRemote([aMovement(uuid: 'r1'), aMovement(uuid: 'r1')]);
      expect(added, 1);
      expect(await queue.pendingCount(), 0);
      expect((await movements.getForProduct('p1')).single.synced, isTrue);
    });
  });

  group('StockCountDb', () {
    test('an unfinished count survives reopening, in scanning order', () async {
      final counts = StockCountDb(db, clock: () => testNow);
      final count = await counts.start();
      await counts.saveLine(CountLine(countUuid: count.uuid, productUuid: 'b', countedQty: 3, scannedAt: testNow));
      await counts.saveLine(CountLine(
          countUuid: count.uuid, productUuid: 'a', countedQty: 9, scannedAt: testNow.add(const Duration(minutes: 1))));
      // Re-counting b later must not move it to the end.
      await counts.saveLine(CountLine(
          countUuid: count.uuid, productUuid: 'b', countedQty: 4, scannedAt: testNow.add(const Duration(minutes: 2))));

      final reopened = StockCountDb(db);
      final active = await reopened.getActive();
      expect(active!.count.uuid, count.uuid);
      expect(active.lines.map((l) => (l.productUuid, l.countedQty)), [('b', 4), ('a', 9)]);
      expect((await reopened.start()).uuid, count.uuid, reason: 'start resumes instead of duplicating');
    });

    test('commit writes all adjustments and closes the session atomically', () async {
      final counts = StockCountDb(db, clock: () => testNow);
      final count = await counts.start();
      await counts.commit(count.uuid, [
        aMovement(uuid: 'x', delta: -3, reason: MovementReason.counted),
        aMovement(uuid: 'y', product: 'p2', delta: 2, reason: MovementReason.counted),
      ]);
      expect(await counts.getActive(), isNull);
      expect(await movements.getAllStock(), {'p1': -3, 'p2': 2});
      expect(await queue.pendingCount(), 2);
    });
  });
}
