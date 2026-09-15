import '../models/product.dart';
import 'demo_data.dart';
import 'products_repo.dart';
import 'repo_exceptions.dart';

/// In-memory products for early UI work and widget tests.
class ProductsDummy implements ProductsRepo {
  final List<Product> _products;
  final Duration latency;

  ProductsDummy({List<Product>? seed, this.latency = const Duration(milliseconds: 150)})
      : _products = seed ?? DemoData.products();

  @override
  Future<List<Product>> getProducts() async {
    await Future<void>.delayed(latency);
    return _products.where((p) => !p.deleted).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  @override
  Future<Product?> getById(String uuid) async => _find((p) => p.uuid == uuid);

  @override
  Future<Product?> getByBarcode(String barcode) async => _find((p) => p.barcode == barcode);

  @override
  Future<Product> save(Product product) async {
    ensureValidProduct(product);
    final clash = _find((p) => p.barcode == product.barcode && p.uuid != product.uuid);
    if (clash != null) throw DuplicateBarcodeException(product.barcode, clash.name);
    final index = _products.indexWhere((p) => p.uuid == product.uuid);
    if (index == -1) {
      _products.add(product);
    } else {
      _products[index] = product;
    }
    return product;
  }

  @override
  Future<void> delete(String uuid, {String by = ''}) async {
    final index = _products.indexWhere((p) => p.uuid == uuid);
    if (index == -1) throw NotFoundException('product $uuid');
    _products[index] =
        _products[index].copyWith(deleted: true, updatedAt: DateTime.now(), updatedBy: by);
  }

  Product? _find(bool Function(Product) test) {
    for (final product in _products) {
      if (!product.deleted && test(product)) return product;
    }
    return null;
  }
}
