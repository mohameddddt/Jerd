import '../models/product.dart';

abstract class ProductsRepo {
  /// Live (not deleted) products, sorted by name.
  Future<List<Product>> getProducts();

  Future<Product?> getById(String uuid);

  Future<Product?> getByBarcode(String barcode);

  /// Creates or updates. Throws [ValidationException] or [DuplicateBarcodeException].
  Future<Product> save(Product product);

  /// Soft delete, so the deletion itself can sync.
  Future<void> delete(String uuid, {String by = ''});
}
