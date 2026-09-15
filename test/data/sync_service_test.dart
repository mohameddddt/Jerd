import 'package:flutter_test/flutter_test.dart';
import 'package:jerd/data/databases/db_helper.dart';
import 'package:jerd/data/databases/db_sync_queue.dart';
import 'package:jerd/data/models/movement.dart';
import 'package:jerd/data/models/product.dart';
import 'package:jerd/data/repositories/movements_db.dart';
import 'package:jerd/data/repositories/products_db.dart';
import 'package:jerd/data/services/data_change_bus.dart';
import 'package:jerd/data/services/storage_service.dart';
import 'package:jerd/data/services/sync_api.dart';
import 'package:jerd/data/services/sync_service.dart';
import 'package:jerd/infrastructure/api_client.dart';
import 'package:jerd/infrastructure/app_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers.dart';

/// An in-memory stand-in for the Flask backend with the same rules:
/// idempotent movement inserts and last-write-wins products.
class FakeServer implements SyncApi {
  final Map<String, Product> products = {};
  final Map<String, Movement> movements = {};
  bool offline = false;
  int movementPushCalls = 0;
  String time = '2026-09-14T10:00:00.000Z';

  @override
  ApiClient get api => ApiClient(baseUrl: 'http://fake', tokenProvider: () => null);

  @override
  bool get isConfigured => true;

  void _check() {
    if (offline) throw const NetworkException('offline');
  }

  @override
  Future<List<ProductPushResult>> pushProducts(List<Map<String, dynamic>> payload) async {
    _check();
    return [
      for (final json in payload)
        () {
          final incoming = Product.fromJson(json);
          final current = products[incoming.uuid];
          if (current != null && current.updatedAt.isAfter(incoming.updatedAt)) {
            return ProductPushResult(uuid: incoming.uuid, applied: false, serverProduct: current);
          }
          products[incoming.uuid] = incoming;
          return ProductPushResult(uuid: incoming.uuid, applied: true);
        }(),
    ];
  }

  @override
  Future<Set<String>> pushMovements(List<Map<String, dynamic>> payload) async {
    _check();
    movementPushCalls++;
    for (final json in payload) {
      final movement = Movement.fromJson(json);
      movements.putIfAbsent(movement.uuid, () => movement);
    }
    return payload.map((json) => json['uuid'] as String).toSet();
  }

  @override
  Future<PullResult<Product>> pullProducts(String? since) async {
    _check();
    return PullResult(products.values.toList(), time);
  }

  @override
  Future<PullResult<Movement>> pullMovements(String? since) async {
    _check();
    return PullResult(movements.values.toList(), time);
  }
}

void main() {
  late DbHelper db;
  late ProductsDb products;
  late MovementsDb movements;
  late SyncQueueDb queue;
  late FakeServer server;
  late AppPrefs prefs;
  late SyncService sync;
  late DateTime now;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    now = testNow;
    db = memoryDb();
    products = ProductsDb(db, clock: () => now);
    movements = MovementsDb(db, clock: () => now);
    queue = SyncQueueDb(db);
    server = FakeServer();
    prefs = AppPrefs(await SharedPreferences.getInstance());
    sync = SyncService(
      db: db,
      queue: queue,
      products: products,
      movements: movements,
      api: server,
      storage: StorageService(),
      prefs: prefs,
      bus: DataChangeBus(),
      clock: () => now,
    );
  });

  tearDown(() => db.close());

  test('airplane mode → record → reconnect → it is on the server', () async {
    server.offline = true;
    await products.save(aProduct());
    await movements.add(aMovement(uuid: 'sale', delta: -1, reason: MovementReason.sold));

    await expectLater(sync.run(), throwsA(isA<NetworkException>()));
    expect(await queue.pendingCount(), 2, reason: 'nothing is lost while offline');
    expect(prefs.lastSyncAt, isNull, reason: 'the cursor never advances on failure');

    server.offline = false;
    now = now.add(const Duration(hours: 1)); // past the backoff
    final report = await sync.run();

    expect(report.pushed, 2);
    expect(await queue.pendingCount(), 0);
    expect(server.movements.keys, ['sale']);
    expect(server.products['p1']?.name, 'Olive oil 1L');
    expect((await movements.getForProduct('p1')).single.synced, isTrue);
    expect(prefs.lastSyncAt, server.time);
  });

  test('a retried push can never double-apply a movement', () async {
    await movements.add(aMovement(uuid: 'm1', delta: 12));
    await sync.run();
    // Simulate a lost response: the same job pushed again.
    await server.pushMovements([aMovement(uuid: 'm1', delta: 12).toJson()]);
    await sync.run();
    expect(server.movements, hasLength(1));
    expect(await movements.getStock('p1'), 12);
  });

  test('failed jobs back off instead of hammering the server', () async {
    await movements.add(aMovement());
    server.offline = true;
    await expectLater(sync.run(), throwsA(isA<NetworkException>()));
    server.offline = false;
    final pushesBefore = server.movementPushCalls;
    await sync.run(); // still inside the 30 s backoff window
    expect(server.movementPushCalls, pushesBefore);
    expect(await queue.pendingCount(), 1);
  });

  test('pull brings other devices\' movements and products in', () async {
    server.products['p9'] = aProduct(uuid: 'p9', name: 'Sugar 1kg', barcode: '6130000100034');
    server.movements['remote'] = aMovement(uuid: 'remote', product: 'p9', delta: 21);
    final report = await sync.run();
    expect(report.pulled, 2);
    expect((await products.getById('p9'))?.name, 'Sugar 1kg');
    expect(await movements.getStock('p9'), 21);
  });

  test('movements never conflict: both phones\' sales are kept', () async {
    await movements.add(aMovement(uuid: 'base', delta: 10));
    await sync.run();
    server.movements['other-phone-sale'] =
        aMovement(uuid: 'other-phone-sale', delta: -1, reason: MovementReason.sold);
    await movements.add(aMovement(uuid: 'this-phone-sale', delta: -1, reason: MovementReason.sold));
    await sync.run();
    expect(await movements.getStock('p1'), 8);
    expect(server.movements, hasLength(3));
  });

  test('product rename conflict: last write wins and the loss is recorded', () async {
    await products.save(aProduct(uuid: 'pasta', name: 'Spaghetti 500g', barcode: '6130000100058',
        updatedAt: DateTime(2026, 9, 14, 10, 58), by: 'Karim'));
    server.products['pasta'] = aProduct(uuid: 'pasta', name: 'Pasta 500g', barcode: '6130000100058',
        updatedAt: DateTime(2026, 9, 14, 11, 2), by: 'Amina');

    final report = await sync.run();

    expect(report.conflicts, 1);
    expect((await products.getById('pasta'))?.name, 'Pasta 500g');
    final conflict = (await queue.conflicts()).single;
    expect(conflict.keptName, 'Pasta 500g');
    expect(conflict.keptBy, 'Amina');
    expect(conflict.lostName, 'Spaghetti 500g');
    expect(conflict.lostBy, 'Karim');
    expect(await queue.pendingCount(), 0);
  });

  test('a pending local edit is not overwritten by an older pull', () async {
    await products.save(aProduct(name: 'Local edit'));
    server.offline = true;
    await expectLater(sync.run(), throwsA(isA<NetworkException>()));
    server.offline = false;
    server.products['p1'] = aProduct(name: 'Old server name', updatedAt: DateTime(2026, 9, 1));
    // Push is still backing off, so this run only pulls.
    await sync.run();
    expect((await products.getById('p1'))?.name, 'Local edit');
  });

  test('concurrent triggers share a single run', () async {
    await movements.add(aMovement());
    final results = await Future.wait([sync.run(), sync.run(), sync.run()]);
    expect(server.movementPushCalls, 1);
    expect(identical(results[0], results[1]), isTrue);
  });
}
