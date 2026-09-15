import 'package:equatable/equatable.dart';
import '../../../data/models/movement.dart';
import '../../../data/models/product.dart';
import '../../domain/low_stock.dart';
import '../../domain/stock_from_ledger.dart';
import '../failure.dart';

sealed class ProductDetailState extends Equatable {
  const ProductDetailState();

  @override
  List<Object?> get props => [];
}

class ProductDetailLoading extends ProductDetailState {
  const ProductDetailLoading();
}

class ProductDetailLoaded extends ProductDetailState {
  final Product product;

  /// Newest first.
  final List<Movement> movements;

  const ProductDetailLoaded(this.product, this.movements);

  /// Always the ledger sum — never a stored number.
  int get stock => stockFromLedger(movements);

  StockLevel get level => stockLevel(stock, product.reorderPoint);

  List<int> get balances => runningBalances(movements, stock);

  @override
  List<Object?> get props => [product, movements];
}

/// The product was deleted (here or on another phone).
class ProductDetailGone extends ProductDetailState {
  const ProductDetailGone();
}

class ProductDetailError extends ProductDetailState {
  final Failure failure;

  const ProductDetailError(this.failure);

  @override
  List<Object?> get props => [failure];
}
