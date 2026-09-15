import '../../infrastructure/api_client.dart';
import '../models/movement.dart';
import '../models/product.dart';

class ProductPushResult {
  final String uuid;
  final bool applied;

  /// The server's row when the push lost (`applied == false`).
  final Product? serverProduct;

  const ProductPushResult({required this.uuid, required this.applied, this.serverProduct});
}

class PullResult<T> {
  final List<T> items;
  final String serverTime;

  const PullResult(this.items, this.serverTime);
}

/// The sync endpoints. Every write carries a client UUID, so retries are idempotent.
class SyncApi {
  final ApiClient api;

  SyncApi(this.api);

  bool get isConfigured => api.isConfigured;

  Future<List<ProductPushResult>> pushProducts(List<Map<String, dynamic>> products) async {
    final json = await api.post('/products/upsert', {'products': products});
    return (json['results'] as List? ?? const []).map((row) {
      final map = row as Map<String, dynamic>;
      final server = map['product'] as Map<String, dynamic>?;
      return ProductPushResult(
        uuid: map['uuid'] as String,
        applied: map['status'] == 'applied',
        serverProduct: server == null ? null : Product.fromJson(server),
      );
    }).toList();
  }

  /// Returns the uuids the server now holds — including ones it already had.
  Future<Set<String>> pushMovements(List<Map<String, dynamic>> movements) async {
    final json = await api.post('/movements/push', {'movements': movements});
    return (json['accepted'] as List? ?? const []).cast<String>().toSet();
  }

  Future<PullResult<Product>> pullProducts(String? since) async {
    final json = await api.get('/products', query: {'since': ?since});
    return PullResult(
      (json['products'] as List? ?? const [])
          .map((row) => Product.fromJson(row as Map<String, dynamic>))
          .toList(),
      json['server_time'] as String,
    );
  }

  Future<PullResult<Movement>> pullMovements(String? since) async {
    final json = await api.get('/movements', query: {'since': ?since});
    return PullResult(
      (json['movements'] as List? ?? const [])
          .map((row) => Movement.fromJson(row as Map<String, dynamic>))
          .toList(),
      json['server_time'] as String,
    );
  }
}
