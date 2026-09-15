import 'package:equatable/equatable.dart';
import '../../../data/models/product.dart';
import '../../domain/low_stock.dart';
import '../../domain/product_filter.dart';
import '../failure.dart';

sealed class ProductsState extends Equatable {
  const ProductsState();

  @override
  List<Object?> get props => [];
}

class ProductsLoading extends ProductsState {
  const ProductsLoading();
}

/// The shop has no products at all yet.
class ProductsEmpty extends ProductsState {
  const ProductsEmpty();
}

class ProductsLoaded extends ProductsState {
  final List<Product> products;
  final Map<String, int> stocks;
  final ProductFilter filter;
  final String query;

  const ProductsLoaded({
    required this.products,
    required this.stocks,
    this.filter = ProductFilter.all,
    this.query = '',
  });

  int stockOf(String uuid) => stocks[uuid] ?? 0;

  List<Product> get visible =>
      filterProducts(products: products, stocks: stocks, query: query, filter: filter);

  int get lowCount => countLevel(products, stocks, StockLevel.low);
  int get outCount => countLevel(products, stocks, StockLevel.out);

  /// Feeds both the Alerts tab and its badge.
  List<LowStockItem> get alerts => lowStockItems(products, stocks);

  ProductsLoaded copyWith({
    List<Product>? products,
    Map<String, int>? stocks,
    ProductFilter? filter,
    String? query,
  }) =>
      ProductsLoaded(
        products: products ?? this.products,
        stocks: stocks ?? this.stocks,
        filter: filter ?? this.filter,
        query: query ?? this.query,
      );

  @override
  List<Object?> get props => [products, stocks, filter, query];
}

class ProductsError extends ProductsState {
  final Failure failure;

  const ProductsError(this.failure);

  @override
  List<Object?> get props => [failure];
}
