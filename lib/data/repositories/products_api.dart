import '../../infrastructure/api_client.dart';
import '../models/product.dart';
import 'products_repo.dart';
import 'repo_exceptions.dart';

/// Online-only implementation, straight against the backend.
class ProductsApi implements ProductsRepo {
  final ApiClient api;
  final DateTime Function() clock;

  ProductsApi(this.api, {DateTime Function()? clock}) : clock = clock ?? DateTime.now;

  @override
  Future<List<Product>> getProducts() async {
    final json = await api.get('/products');
    return _parse(json).where((p) => !p.deleted).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  @override
  Future<Product?> getById(String uuid) async {
    try {
      final json = await api.get('/products/$uuid');
      final product = Product.fromJson(json['product'] as Map<String, dynamic>);
      return product.deleted ? null : product;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<Product?> getByBarcode(String barcode) async {
    final json = await api.get('/products', query: {'barcode': barcode.trim()});
    return _parse(json).where((p) => !p.deleted).firstOrNull;
  }

  @override
  Future<Product> save(Product product) async {
    ensureValidProduct(product);
    final existing = await getByBarcode(product.barcode);
    if (existing != null && existing.uuid != product.uuid) {
      throw DuplicateBarcodeException(product.barcode, existing.name);
    }
    await api.post('/products/upsert', {
      'products': [product.toJson()],
    });
    return product;
  }

  @override
  Future<void> delete(String uuid, {String by = ''}) async {
    final product = await getById(uuid);
    if (product == null) throw NotFoundException('product $uuid');
    await api.post('/products/upsert', {
      'products': [product.copyWith(deleted: true, updatedAt: clock(), updatedBy: by).toJson()],
    });
  }

  List<Product> _parse(Map<String, dynamic> json) => (json['products'] as List? ?? const [])
      .map((row) => Product.fromJson(row as Map<String, dynamic>))
      .toList();
}
