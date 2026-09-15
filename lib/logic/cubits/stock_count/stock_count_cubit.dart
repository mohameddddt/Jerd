import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/stock_count.dart';
import '../../../data/repositories/movements_repo.dart';
import '../../../data/repositories/products_repo.dart';
import '../../../data/repositories/stock_count_repo.dart';
import '../../../data/services/data_change_bus.dart';
import '../../../infrastructure/app_logger.dart';
import '../../domain/reconcile_count.dart';
import '../failure.dart';
import 'stock_count_state.dart';

enum ScanOutcome { counted, unknownBarcode, notCounting }

/// Walk the shelves, count, then commit every difference as one batch.
/// While a count is open, ordinary movements are blocked (see ProductsCubit).
class StockCountCubit extends Cubit<StockCountState> {
  final StockCountRepo counts;
  final ProductsRepo products;
  final MovementsRepo movements;
  final DataChangeBus bus;
  final AppUser? Function() currentUser;
  final DateTime Function() clock;
  final Stream<void> Function() ticker;
  final String Function() newUuid;
  StreamSubscription<void>? _tick;

  StockCountCubit({
    required this.counts,
    required this.products,
    required this.movements,
    required this.bus,
    required this.currentUser,
    DateTime Function()? clock,
    Stream<void> Function()? ticker,
    String Function()? newUuid,
  })  : clock = clock ?? DateTime.now,
        ticker = ticker ?? (() => Stream<void>.periodic(const Duration(seconds: 1))),
        newUuid = newUuid ?? const Uuid().v4,
        super(const StockCountIdle());

  StockCountCounting? get _counting => switch (state) {
        StockCountCounting s => s,
        StockCountReconciling(:final counting) => counting,
        _ => null,
      };

  /// Resumes an unfinished count (e.g. after a force-close) or starts a new one.
  Future<void> open() async {
    emit(const StockCountLoading());
    try {
      final list = await products.getProducts();
      final expected = await movements.getAllStock();
      final active = await counts.getActive();
      final StockCount count = active?.count ?? await counts.start();
      final lines = [
        for (final line in active?.lines ?? const <CountLine>[])
          if (list.any((p) => p.uuid == line.productUuid)) MapEntry(line.productUuid, line.countedQty),
      ];
      if (isClosed) return;
      emit(StockCountCounting(
        count: count,
        products: {for (final p in list) p.uuid: p},
        expected: {for (final p in list) p.uuid: expected[p.uuid] ?? 0},
        lines: lines,
        elapsed: clock().difference(count.startedAt),
        current: lines.isEmpty ? null : lines.last.key,
      ));
      _startTicker();
    } catch (e, st) {
      AppLogger.error('Opening stock count failed', e, st);
      if (!isClosed) emit(StockCountError(Failure.from(e)));
    }
  }

  void _startTicker() {
    _tick ??= ticker().listen((_) {
      final counting = state;
      if (counting is StockCountCounting) {
        emit(counting.copyWith(elapsed: clock().difference(counting.count.startedAt)));
      }
    });
  }

  /// A scanned or typed barcode. First scan starts at the expected quantity,
  /// so a shelf that matches needs no typing; rescans just select it.
  Future<ScanOutcome> scan(String barcode) async {
    final counting = state;
    if (counting is! StockCountCounting) return ScanOutcome.notCounting;
    final match = counting.products.values.where((p) => p.barcode == barcode.trim()).firstOrNull;
    if (match == null) return ScanOutcome.unknownBarcode;
    if (!counting.counted.containsKey(match.uuid)) {
      await _setLine(counting, match.uuid, counting.expectedOf(match.uuid));
    } else {
      emit(counting.copyWith(current: match.uuid));
    }
    return ScanOutcome.counted;
  }

  /// Picks the next uncounted product — for shelves without barcodes.
  Future<bool> countNextUncounted() async {
    final counting = state;
    if (counting is! StockCountCounting) return false;
    final next = counting.products.values
        .where((p) => !counting.counted.containsKey(p.uuid))
        .firstOrNull;
    if (next == null) return false;
    await _setLine(counting, next.uuid, counting.expectedOf(next.uuid));
    return true;
  }

  void select(String productUuid) {
    final counting = state;
    if (counting is StockCountCounting) emit(counting.copyWith(current: productUuid));
  }

  Future<void> changeCounted(String productUuid, int by) async {
    final counting = state;
    if (counting is! StockCountCounting) return;
    await setCounted(productUuid, counting.countedOf(productUuid) + by);
  }

  Future<void> setCounted(String productUuid, int value) async {
    final counting = state;
    if (counting is! StockCountCounting) return;
    await _setLine(counting, productUuid, value.clamp(0, 999999));
  }

  Future<void> _setLine(StockCountCounting counting, String productUuid, int qty) async {
    final lines = [...counting.lines];
    final index = lines.indexWhere((e) => e.key == productUuid);
    if (index == -1) {
      lines.add(MapEntry(productUuid, qty));
    } else {
      lines[index] = MapEntry(productUuid, qty);
    }
    emit(counting.copyWith(lines: lines, current: productUuid));
    // Persist every change so a force-close loses nothing.
    await counts.saveLine(CountLine(
      countUuid: counting.count.uuid,
      productUuid: productUuid,
      countedQty: qty,
      scannedAt: clock(),
    ));
  }

  void finish() {
    final counting = state;
    if (counting is StockCountCounting) emit(StockCountReconciling(counting));
  }

  void keepCounting() {
    final reconciling = state;
    if (reconciling is StockCountReconciling) emit(reconciling.counting);
  }

  Future<ActionResult> commit() async {
    final counting = _counting;
    if (counting == null) return const ActionResult.failed(Failure(FailureKind.notFound));
    try {
      final user = currentUser();
      final adjustments = adjustmentsForCount(
        differences: counting.differences,
        newUuid: newUuid,
        now: clock(),
        userId: user?.id ?? '',
        userName: user?.name ?? '',
      );
      await counts.commit(counting.count.uuid, adjustments);
      await _stopTicker();
      bus.notify(DataChange.local);
      emit(StockCountCommitted(adjustments.length));
      return const ActionResult.ok();
    } catch (e, st) {
      AppLogger.error('Committing stock count failed', e, st);
      return ActionResult.failed(Failure.from(e));
    }
  }

  Future<void> discard() async {
    final counting = _counting;
    if (counting != null) await counts.cancel(counting.count.uuid);
    await _stopTicker();
    emit(const StockCountIdle());
  }

  Future<void> _stopTicker() async {
    await _tick?.cancel();
    _tick = null;
  }

  @override
  Future<void> close() async {
    await _stopTicker();
    return super.close();
  }
}
