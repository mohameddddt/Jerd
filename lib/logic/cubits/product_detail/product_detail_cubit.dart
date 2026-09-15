import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/movements_repo.dart';
import '../../../data/repositories/products_repo.dart';
import '../../../data/services/data_change_bus.dart';
import '../failure.dart';
import 'product_detail_state.dart';

/// Provided per screen.
class ProductDetailCubit extends Cubit<ProductDetailState> {
  final String productUuid;
  final ProductsRepo products;
  final MovementsRepo movements;
  StreamSubscription<DataChange>? _changes;

  ProductDetailCubit({
    required this.productUuid,
    required this.products,
    required this.movements,
    required DataChangeBus bus,
  }) : super(const ProductDetailLoading()) {
    // Any write — here, from the scan sheet, or pulled by sync — refreshes the page.
    _changes = bus.stream.listen((_) => load());
  }

  Future<void> load() async {
    try {
      final product = await products.getById(productUuid);
      if (isClosed) return;
      if (product == null) {
        emit(const ProductDetailGone());
        return;
      }
      final history = await movements.getForProduct(productUuid);
      if (!isClosed) emit(ProductDetailLoaded(product, history));
    } catch (e) {
      if (!isClosed) emit(ProductDetailError(Failure.from(e)));
    }
  }

  @override
  Future<void> close() async {
    await _changes?.cancel();
    return super.close();
  }
}
