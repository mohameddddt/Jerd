import '../models/movement.dart';

abstract class MovementsRepo {
  /// Ledger rows for one product, newest first.
  Future<List<Movement>> getForProduct(String productUuid);

  /// Ledger rows created in [start, end).
  Future<List<Movement>> getBetween(DateTime start, DateTime end);

  Future<Movement> add(Movement movement);

  /// Appends several movements atomically — used when a stock count commits.
  Future<void> addBatch(List<Movement> movements);

  /// Sum of the ledger for one product.
  Future<int> getStock(String productUuid);

  /// Sum of the ledger for every product that has movements.
  Future<Map<String, int>> getAllStock();
}
