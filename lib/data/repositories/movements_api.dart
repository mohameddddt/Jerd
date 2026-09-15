import '../../infrastructure/api_client.dart';
import '../models/movement.dart';
import 'movements_repo.dart';

/// Online-only implementation, straight against the backend.
class MovementsApi implements MovementsRepo {
  final ApiClient api;

  MovementsApi(this.api);

  @override
  Future<List<Movement>> getForProduct(String productUuid) async {
    final json = await api.get('/movements', query: {'product_uuid': productUuid});
    return _parse(json)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<Movement>> getBetween(DateTime start, DateTime end) async {
    final json = await api.get('/movements', query: {
      'from': start.toUtc().toIso8601String(),
      'to': end.toUtc().toIso8601String(),
    });
    return _parse(json);
  }

  @override
  Future<Movement> add(Movement movement) async {
    await addBatch([movement]);
    return movement.copyWith(synced: true);
  }

  @override
  Future<void> addBatch(List<Movement> movements) async {
    await api.post('/movements/push', {
      'movements': movements.map((m) => m.toJson()).toList(),
    });
  }

  @override
  Future<int> getStock(String productUuid) async {
    final json = await api.get('/stock', query: {'product_uuid': productUuid});
    return (json['stock'] as num? ?? 0).toInt();
  }

  @override
  Future<Map<String, int>> getAllStock() async {
    final json = await api.get('/stock');
    final stocks = json['stocks'] as Map<String, dynamic>? ?? const {};
    return stocks.map((key, value) => MapEntry(key, (value as num).toInt()));
  }

  List<Movement> _parse(Map<String, dynamic> json) => (json['movements'] as List? ?? const [])
      .map((row) => Movement.fromJson(row as Map<String, dynamic>))
      .toList();
}
