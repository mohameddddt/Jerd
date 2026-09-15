import '../../logic/domain/stock_from_ledger.dart';
import '../models/movement.dart';
import 'demo_data.dart';
import 'movements_repo.dart';

/// In-memory ledger for early UI work and widget tests.
class MovementsDummy implements MovementsRepo {
  final List<Movement> _movements;

  MovementsDummy({List<Movement>? seed}) : _movements = seed ?? DemoData.movements();

  @override
  Future<List<Movement>> getForProduct(String productUuid) async {
    return _movements.where((m) => m.productUuid == productUuid).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<Movement>> getBetween(DateTime start, DateTime end) async => _movements
      .where((m) => !m.createdAt.isBefore(start) && m.createdAt.isBefore(end))
      .toList();

  @override
  Future<Movement> add(Movement movement) async {
    if (!_movements.any((m) => m.uuid == movement.uuid)) _movements.add(movement);
    return movement;
  }

  @override
  Future<void> addBatch(List<Movement> movements) async {
    for (final movement in movements) {
      await add(movement);
    }
  }

  @override
  Future<int> getStock(String productUuid) async =>
      stockFromLedger(_movements.where((m) => m.productUuid == productUuid));

  @override
  Future<Map<String, int>> getAllStock() async => stockByProduct(_movements);
}
