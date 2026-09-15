import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/movement.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/movements_repo.dart';
import '../../../data/repositories/products_repo.dart';
import '../../../data/repositories/repo_exceptions.dart';
import '../../../data/repositories/stock_count_repo.dart';
import '../../../data/services/data_change_bus.dart';
import '../../../infrastructure/app_logger.dart';
import '../../domain/product_filter.dart';
import '../../domain/validators.dart';
import '../failure.dart';
import 'products_state.dart';

/// Owns the product list and every write that changes it.
class ProductsCubit extends Cubit<ProductsState> {
  final ProductsRepo products;
  final MovementsRepo movements;
  final StockCountRepo counts;
  final DataChangeBus bus;
  final AppUser? Function() currentUser;
  final String Function() newUuid;
  final DateTime Function() clock;
  StreamSubscription<DataChange>? _changes;

  ProductsCubit({
    required this.products,
    required this.movements,
    required this.counts,
    required this.bus,
    required this.currentUser,
    String Function()? newUuid,
    DateTime Function()? clock,
  })  : newUuid = newUuid ?? const Uuid().v4,
        clock = clock ?? DateTime.now,
        super(const ProductsLoading()) {
    _changes = bus.stream.where((c) => c == DataChange.remote).listen((_) => load(silent: true));
  }

  Future<void> load({bool silent = false}) async {
    final previous = state;
    if (!silent || previous is! ProductsLoaded) emit(const ProductsLoading());
    try {
      final list = await products.getProducts();
      final stocks = await movements.getAllStock();
      if (isClosed) return;
      if (list.isEmpty) {
        emit(const ProductsEmpty());
        return;
      }
      emit(ProductsLoaded(
        products: list,
        stocks: stocks,
        filter: previous is ProductsLoaded ? previous.filter : ProductFilter.all,
        query: previous is ProductsLoaded ? previous.query : '',
      ));
    } catch (e, st) {
      AppLogger.error('Loading products failed', e, st);
      if (!isClosed) emit(ProductsError(Failure.from(e)));
    }
  }

  void setFilter(ProductFilter filter) {
    final current = state;
    if (current is ProductsLoaded) emit(current.copyWith(filter: filter));
  }

  void setQuery(String query) {
    final current = state;
    if (current is ProductsLoaded) emit(current.copyWith(query: query));
  }

  Future<ActionResult> saveProduct({
    Product? existing,
    required String name,
    required String barcode,
    required String unit,
    required int reorderPoint,
    String? imageUrl,
  }) {
    return _run(() async {
      final now = clock();
      final by = currentUser()?.name ?? '';
      final product = existing == null
          ? Product(
              uuid: newUuid(),
              barcode: barcode.trim(),
              name: name.trim(),
              unit: unit,
              reorderPoint: reorderPoint,
              imageUrl: imageUrl,
              updatedAt: now,
              updatedBy: by,
            )
          : existing.copyWith(
              barcode: barcode.trim(),
              name: name.trim(),
              unit: unit,
              reorderPoint: reorderPoint,
              imageUrl: imageUrl,
              clearImage: imageUrl == null,
              updatedAt: now,
              updatedBy: by,
            );
      await products.save(product);
    });
  }

  /// Owners only: staff can add and edit but not remove products.
  Future<ActionResult> deleteProduct(String uuid) {
    return _run(() async {
      final user = currentUser();
      if (user == null || !user.isOwner) throw const PermissionDeniedException();
      await products.delete(uuid, by: user.name);
    });
  }

  /// The core write path. Blocked while a stock count is running.
  Future<ActionResult> recordMovement({
    required String productUuid,
    required MovementReason reason,
    required int quantity,
    String? note,
  }) {
    return _run(() async {
      final error = validateQuantity(quantity, allowNegative: reason == MovementReason.adjusted);
      if (error != null) throw ValidationException('quantity', error);
      if (await counts.getActive() != null) throw const CountInProgressException();
      final user = currentUser();
      final delta = switch (reason) {
        MovementReason.received => quantity.abs(),
        MovementReason.sold => -quantity.abs(),
        MovementReason.adjusted || MovementReason.counted => quantity,
      };
      await movements.add(Movement(
        uuid: newUuid(),
        productUuid: productUuid,
        delta: delta,
        reason: reason,
        note: note == null || note.trim().isEmpty ? null : note.trim(),
        createdAt: clock(),
        userId: user?.id ?? '',
        userName: user?.name ?? '',
      ));
    });
  }

  Future<ActionResult> _run(Future<void> Function() action) async {
    try {
      await action();
      bus.notify(DataChange.local);
      await load(silent: true);
      return const ActionResult.ok();
    } catch (e, st) {
      final failure = Failure.from(e);
      if (failure.kind == FailureKind.unknown) AppLogger.error('Product action failed', e, st);
      return ActionResult.failed(failure);
    }
  }

  @override
  Future<void> close() async {
    await _changes?.cancel();
    return super.close();
  }
}
