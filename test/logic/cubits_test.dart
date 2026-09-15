import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jerd/data/databases/db_helper.dart';
import 'package:jerd/data/databases/db_sync_queue.dart';
import 'package:jerd/data/models/movement.dart';
import 'package:jerd/data/models/sync_models.dart';
import 'package:jerd/data/repositories/auth_demo.dart';
import 'package:jerd/data/repositories/movements_db.dart';
import 'package:jerd/data/repositories/movements_dummy.dart';
import 'package:jerd/data/repositories/products_db.dart';
import 'package:jerd/data/repositories/products_dummy.dart';
import 'package:jerd/data/repositories/stock_count_dummy.dart';
import 'package:jerd/data/services/data_change_bus.dart';
import 'package:jerd/data/services/sync_api.dart';
import 'package:jerd/data/services/sync_service.dart';
import 'package:jerd/infrastructure/api_client.dart';
import 'package:jerd/infrastructure/app_prefs.dart';
import 'package:jerd/logic/cubits/auth/auth_cubit.dart';
import 'package:jerd/logic/cubits/auth/auth_state.dart';
import 'package:jerd/logic/cubits/failure.dart';
import 'package:jerd/logic/cubits/products/products_cubit.dart';
import 'package:jerd/logic/cubits/products/products_state.dart';
import 'package:jerd/logic/cubits/stock_count/stock_count_cubit.dart';
import 'package:jerd/logic/cubits/stock_count/stock_count_state.dart';
import 'package:jerd/logic/cubits/sync/sync_cubit.dart';
import 'package:jerd/logic/cubits/sync/sync_state.dart';
import 'package:jerd/logic/domain/product_filter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers.dart';

class MockSyncService extends Mock implements SyncService {}

Future<AppPrefs> freshPrefs() async {
  SharedPreferences.setMockInitialValues({});
  return AppPrefs(await SharedPreferences.getInstance());
}

void main() {
  group('AuthCubit', () {
    late AppPrefs prefs;
    setUp(() async => prefs = await freshPrefs());

    blocTest<AuthCubit, AuthState>(
      'emits Loading then Authenticated and remembers the session',
      build: () => AuthCubit(repo: AuthDemo(currentUser: () => prefs.user), prefs: prefs),
      act: (cubit) => cubit.login('karim@example.com', '123456'),
      expect: () => [const AuthLoading(), isA<Authenticated>()],
      verify: (_) {
        expect(prefs.isLoggedIn, isTrue);
        expect(prefs.user?.name, 'Karim');
      },
    );

    blocTest<AuthCubit, AuthState>(
      'wrong password is an error state, not an exception',
      build: () => AuthCubit(repo: AuthDemo(currentUser: () => prefs.user), prefs: prefs),
      act: (cubit) => cubit.login('karim@example.com', 'nope123'),
      expect: () => [const AuthLoading(), const AuthError(Failure(FailureKind.invalidCredentials))],
    );

    blocTest<AuthCubit, AuthState>(
      'stays logged in across launches, and logout clears it',
      setUp: () => prefs.saveSession(owner, 'token'),
      build: () => AuthCubit(repo: AuthDemo(currentUser: () => prefs.user), prefs: prefs),
      act: (cubit) async {
        await cubit.restoreSession();
        await cubit.logout();
      },
      expect: () => [const Authenticated(owner), const Unauthenticated()],
      verify: (_) => expect(prefs.isLoggedIn, isFalse),
    );
  });

  group('ProductsCubit', () {
    late ProductsDummy products;
    late MovementsDummy movements;
    late StockCountDummy counts;
    late DataChangeBus bus;

    ProductsCubit build({bool asStaff = false}) => ProductsCubit(
          products: products,
          movements: movements,
          counts: counts,
          bus: bus,
          currentUser: () => asStaff ? staff : owner,
          newUuid: () => 'new-uuid',
          clock: () => testNow,
        );

    setUp(() {
      products = ProductsDummy(seed: [aProduct(uuid: 'oil', reorder: 6), aProduct(uuid: 'tea', name: 'Tea', barcode: '1111')],
          latency: Duration.zero);
      movements = MovementsDummy(seed: [aMovement(uuid: 'a', product: 'oil', delta: 3), aMovement(uuid: 'b', product: 'tea', delta: 40)]);
      counts = StockCountDummy(movements);
      bus = DataChangeBus();
    });

    blocTest<ProductsCubit, ProductsState>(
      'loads products with ledger stock and derived alerts',
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        const ProductsLoading(),
        isA<ProductsLoaded>()
            .having((s) => s.stockOf('oil'), 'oil stock', 3)
            .having((s) => s.alerts.single.product.uuid, 'alert', 'oil'),
      ],
    );

    blocTest<ProductsCubit, ProductsState>(
      'filter and search narrow the visible list without reloading',
      build: build,
      act: (cubit) async {
        await cubit.load();
        cubit.setFilter(ProductFilter.low);
        cubit.setQuery('tea');
      },
      skip: 2,
      expect: () => [
        isA<ProductsLoaded>().having((s) => s.visible.single.uuid, 'low', 'oil'),
        isA<ProductsLoaded>().having((s) => s.visible, 'low + tea', isEmpty),
      ],
    );

    test('recording a sale updates the list and the alert badge from one state', () async {
      final cubit = build();
      await cubit.load();
      final local = expectLater(bus.stream, emits(DataChange.local));
      final result = await cubit.recordMovement(productUuid: 'tea', reason: MovementReason.sold, quantity: 35);
      expect(result.ok, isTrue);
      await local;
      final state = cubit.state as ProductsLoaded;
      expect(state.stockOf('tea'), 5);
      expect(state.alerts.map((a) => a.product.uuid), containsAll(['oil', 'tea']));
      await cubit.close();
    });

    test('movements are blocked while a stock count is running', () async {
      final cubit = build();
      await counts.start();
      final result = await cubit.recordMovement(productUuid: 'oil', reason: MovementReason.received, quantity: 1);
      expect(result.failure?.kind, FailureKind.countInProgress);
      expect(await movements.getStock('oil'), 3);
      await cubit.close();
    });

    test('zero quantity is refused by the second validation layer', () async {
      final cubit = build();
      final result = await cubit.recordMovement(productUuid: 'oil', reason: MovementReason.adjusted, quantity: 0);
      expect(result.failure?.kind, FailureKind.validation);
      await cubit.close();
    });

    test('staff cannot delete products; owners can', () async {
      final asStaff = build(asStaff: true);
      expect((await asStaff.deleteProduct('oil')).failure?.kind, FailureKind.permissionDenied);
      final asOwner = build();
      expect((await asOwner.deleteProduct('oil')).ok, isTrue);
      expect(await products.getById('oil'), isNull);
      await asStaff.close();
      await asOwner.close();
    });

    test('duplicate barcode surfaces the owning product', () async {
      final cubit = build();
      final result = await cubit.saveProduct(name: 'Copy', barcode: '1111', unit: 'pcs', reorderPoint: 1);
      expect(result.failure, const Failure(FailureKind.duplicateBarcode, 'Tea'));
      await cubit.close();
    });

    test('reloads by itself when sync pulls remote data', () async {
      final cubit = build();
      await cubit.load();
      await movements.add(aMovement(uuid: 'remote', product: 'oil', delta: 10));
      bus.notify(DataChange.remote);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect((cubit.state as ProductsLoaded).stockOf('oil'), 13);
      await cubit.close();
    });
  });

  group('StockCountCubit', () {
    late MovementsDummy movements;
    late StockCountDummy counts;
    late StreamController<void> ticks;
    late DateTime now;

    StockCountCubit build() {
      var n = 0;
      return StockCountCubit(
        counts: counts,
        products: ProductsDummy(
          seed: [
            aProduct(uuid: 'sugar', name: 'Sugar', barcode: '6130000100034'),
            aProduct(uuid: 'water', name: 'Water', barcode: '6130000100027'),
            aProduct(uuid: 'tea', name: 'Tea', barcode: '6130000100041'),
          ],
          latency: Duration.zero,
        ),
        movements: movements,
        bus: DataChangeBus(),
        currentUser: () => owner,
        clock: () => now,
        ticker: () => ticks.stream,
        newUuid: () => 'adj-${n++}',
      );
    }

    setUp(() {
      now = testNow;
      ticks = StreamController<void>.broadcast();
      movements = MovementsDummy(seed: [
        aMovement(uuid: '1', product: 'sugar', delta: 21),
        aMovement(uuid: '2', product: 'water', delta: 48),
        aMovement(uuid: '3', product: 'tea', delta: 5),
      ]);
      counts = StockCountDummy(movements, clock: () => testNow);
    });

    tearDown(() => ticks.close());

    blocTest<StockCountCubit, StockCountState>(
      'open → Counting with expected stock from the ledger',
      build: build,
      act: (cubit) => cubit.open(),
      expect: () => [
        const StockCountLoading(),
        isA<StockCountCounting>()
            .having((s) => s.totalProducts, 'total', 3)
            .having((s) => s.expectedOf('water'), 'expected', 48)
            .having((s) => s.countedProducts, 'counted', 0),
      ],
    );

    blocTest<StockCountCubit, StockCountState>(
      'the timer shows count duration',
      build: build,
      act: (cubit) async {
        await cubit.open();
        now = now.add(const Duration(minutes: 12, seconds: 48));
        ticks.add(null);
      },
      skip: 2,
      expect: () => [
        isA<StockCountCounting>().having((s) => s.elapsed, 'elapsed', const Duration(minutes: 12, seconds: 48)),
      ],
    );

    blocTest<StockCountCubit, StockCountState>(
      'scan → adjust → reconcile lists only the differences',
      build: build,
      act: (cubit) async {
        await cubit.open();
        expect(await cubit.scan('6130000100034'), ScanOutcome.counted);
        await cubit.changeCounted('sugar', -3);
        await cubit.scan('6130000100027');
        await cubit.setCounted('water', 50);
        expect(await cubit.scan('0000'), ScanOutcome.unknownBarcode);
        cubit.finish();
      },
      verify: (cubit) {
        final state = cubit.state as StockCountReconciling;
        expect(state.differences.map((d) => (d.productUuid, d.delta)), [('sugar', -3), ('water', 2)]);
      },
    );

    test('commit writes one adjustment batch and closes the session', () async {
      final cubit = build();
      await cubit.open();
      await cubit.scan('6130000100034');
      await cubit.setCounted('sugar', 18);
      await cubit.scan('6130000100041');
      cubit.finish();
      final result = await cubit.commit();
      expect(result.ok, isTrue);
      expect(cubit.state, const StockCountCommitted(1));
      expect(await movements.getStock('sugar'), 18);
      expect(await movements.getStock('tea'), 5);
      expect(await counts.getActive(), isNull);
      await cubit.close();
    });

    test('an unfinished count resumes where it was left', () async {
      final first = build();
      await first.open();
      await first.scan('6130000100027');
      await first.setCounted('water', 44);
      await first.close();

      final second = build();
      await second.open();
      final state = second.state as StockCountCounting;
      expect(state.countedOf('water'), 44);
      expect(state.current, 'water');
      await second.close();
    });
  });

  group('SyncCubit', () {
    late DbHelper db;
    late SyncQueueDb queue;
    late MockSyncService service;
    late StreamController<bool> connectivity;
    late DataChangeBus bus;
    late AppPrefs prefs;

    setUp(() async {
      db = memoryDb();
      queue = SyncQueueDb(db);
      service = MockSyncService();
      connectivity = StreamController<bool>.broadcast();
      bus = DataChangeBus();
      prefs = await freshPrefs();
      when(() => service.api).thenReturn(_ConfiguredApi());
      await ProductsDb(db).save(aProduct());
      await MovementsDb(db).add(aMovement(delta: -1, reason: MovementReason.sold));
    });

    tearDown(() async {
      await connectivity.close();
      await db.close();
    });

    SyncCubit build() => SyncCubit(
          service: service,
          queue: queue,
          products: ProductsDb(db),
          prefs: prefs,
          bus: bus,
          connectivity: connectivity.stream,
          initiallyOnline: false,
          debounce: const Duration(milliseconds: 10),
        );

    blocTest<SyncCubit, SyncState>(
      'refresh lists what is waiting to upload, newest first',
      build: build,
      act: (cubit) => cubit.refresh(),
      expect: () => [
        isA<SyncIdle>().having(
          (s) => s.overview.pending.map((p) => (p.entity, p.productName)),
          'pending',
          [(SyncEntity.movement, 'Olive oil 1L'), (SyncEntity.product, 'Olive oil 1L')],
        ),
      ],
    );

    blocTest<SyncCubit, SyncState>(
      'coming back online triggers a sync: Syncing → Idle',
      build: build,
      setUp: () => when(() => service.run()).thenAnswer(
        (_) async => SyncReport(pushed: 2, pulled: 0, conflicts: 0, finishedAt: testNow),
      ),
      act: (cubit) => connectivity.add(true),
      wait: const Duration(milliseconds: 50),
      expect: () => [isA<SyncInProgress>(), isA<SyncIdle>().having((s) => s.lastReport?.pushed, 'pushed', 2)],
      verify: (_) => verify(() => service.run()).called(1),
    );

    blocTest<SyncCubit, SyncState>(
      'a failed run becomes Failed with the reason, keeping the queue visible',
      build: build,
      setUp: () => when(() => service.run()).thenThrow(const NetworkException('down')),
      act: (cubit) => cubit.syncNow(),
      expect: () => [
        isA<SyncInProgress>(),
        isA<SyncFailed>()
            .having((s) => s.failure.kind, 'kind', FailureKind.network)
            .having((s) => s.overview.pending.length, 'pending', 2),
      ],
    );

    blocTest<SyncCubit, SyncState>(
      'offline local writes do not attempt a sync',
      build: build,
      act: (cubit) => bus.notify(DataChange.local),
      wait: const Duration(milliseconds: 50),
      verify: (_) => verifyNever(() => service.run()),
    );
  });
}

class _ConfiguredApi extends Fake implements SyncApi {
  @override
  bool get isConfigured => true;
}
