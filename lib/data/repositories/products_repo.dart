import '../models/product.dart';

abstract class ProductsRepo {
  Future<List<Product>> getProducts();
  Future<Product?> getById(String uuid);
  Future<Product?> getByBarcode(String barcode);
  Future<Product> save(Product product);
  Future<void> delete(String uuid);
}