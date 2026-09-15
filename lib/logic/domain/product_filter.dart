import '../../data/models/product.dart';
import 'low_stock.dart';

enum ProductFilter { all, low, out }

/// Case-insensitive name match or barcode prefix/substring match, then filter.
List<Product> filterProducts({
  required List<Product> products,
  required Map<String, int> stocks,
  required String query,
  required ProductFilter filter,
}) {
  final needle = query.trim().toLowerCase();
  return [
    for (final product in products)
      if ((needle.isEmpty ||
              product.name.toLowerCase().contains(needle) ||
              product.barcode.contains(needle)) &&
          _matches(filter, stockLevel(stocks[product.uuid] ?? 0, product.reorderPoint)))
        product,
  ];
}

bool _matches(ProductFilter filter, StockLevel level) => switch (filter) {
      ProductFilter.all => true,
      ProductFilter.low => level == StockLevel.low,
      ProductFilter.out => level == StockLevel.out,
    };

int countLevel(List<Product> products, Map<String, int> stocks, StockLevel level) =>
    products.where((p) => stockLevel(stocks[p.uuid] ?? 0, p.reorderPoint) == level).length;
