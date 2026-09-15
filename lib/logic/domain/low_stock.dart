import 'package:equatable/equatable.dart';
import '../../data/models/product.dart';

enum StockLevel { ok, low, out }

StockLevel stockLevel(int stock, int reorderPoint) {
  if (stock <= 0) return StockLevel.out;
  if (stock <= reorderPoint) return StockLevel.low;
  return StockLevel.ok;
}

class LowStockItem extends Equatable {
  final Product product;
  final int stock;

  const LowStockItem(this.product, this.stock);

  StockLevel get level => stockLevel(stock, product.reorderPoint);

  /// 0 means empty; 1 means exactly at the reorder point.
  double get urgency {
    if (stock <= 0) return 0;
    if (product.reorderPoint <= 0) return 1;
    return stock / product.reorderPoint;
  }

  @override
  List<Object?> get props => [product, stock];
}

/// Items at or below their reorder point, most urgent first.
/// Derived on demand — never stored.
List<LowStockItem> lowStockItems(Iterable<Product> products, Map<String, int> stocks) {
  final items = [
    for (final product in products)
      if (!product.deleted && stockLevel(stocks[product.uuid] ?? 0, product.reorderPoint) != StockLevel.ok)
        LowStockItem(product, stocks[product.uuid] ?? 0),
  ];
  items.sort((a, b) {
    final byUrgency = a.urgency.compareTo(b.urgency);
    if (byUrgency != 0) return byUrgency;
    return a.product.name.toLowerCase().compareTo(b.product.name.toLowerCase());
  });
  return items;
}
