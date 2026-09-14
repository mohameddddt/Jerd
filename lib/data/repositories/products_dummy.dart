import '../models/product.dart';
import 'products_repo.dart';

class ProductsDummy implements ProductsRepo {
  final List<Product> _products = [
    Product(
      uuid: 'p-001',
      barcode: '613043000001',
      name: 'Milk 1L',
      unit: 'bottle',
      reorderPoint: 10,
      updatedAt: DateTime(2026, 9, 10),
    ),
    Product(
      uuid: 'p-002',
      barcode: '613043000002',
      name: 'Basmati Rice 1kg',
      unit: 'bag',
      reorderPoint: 8,
      updatedAt: DateTime(2026, 9, 11),
    ),
    Product(
      uuid: 'p-003',
      barcode: '613043000003',
      name: 'Olive Oil 1L',
      unit: 'bottle',
      reorderPoint: 5,
      updatedAt: DateTime(2026, 9, 12),
    ),
    Product(
      uuid: 'p-004',
      barcode: '613043000004',
      name: 'Tomato Sauce 500g',
      unit: 'jar',
      reorderPoint: 6,
      updatedAt: DateTime(2026, 9, 12),
    ),
    Product(
      uuid: 'p-005',
      barcode: '613043000005',
      name: 'Green Tea 25 bags',
      unit: 'box',
      reorderPoint: 4,
      updatedAt: DateTime(2026, 9, 13),
    ),
  ];

  @override
  Future<List<Product>> getProducts() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List<Product>.from(_products.where((p) => !p.deleted));
  }

  @override
  Future<Product?> getById(String uuid) async {
    return _find(uuid);
  }

  @override
  Future<Product?> getByBarcode(String barcode) async {
    for (final product in _products) {
      if (!product.deleted && product.barcode == barcode) return product;
    }
    return null;
  }

  @override
  Future<Product> save(Product product) async {
    final index = _products.indexWhere((p) => p.uuid == product.uuid);
    if (index == -1) {
      _products.add(product);
    } else {
      _products[index] = product;
    }
    return product;
  }

  @override
  Future<void> delete(String uuid) async {
    final index = _products.indexWhere((p) => p.uuid == uuid);
    if (index != -1) {
      _products[index] = _products[index].copyWith(deleted: true);
    }
  }

  Product? _find(String uuid) {
    for (final product in _products) {
      if (product.uuid == uuid && !product.deleted) return product;
    }
    return null;
  }
}
