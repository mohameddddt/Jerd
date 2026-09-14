import '../models/movement.dart';
import 'movements_repo.dart';

class MovementsDummy implements MovementsRepo {
  final List<Movement> _movements = [
    Movement(
      uuid: 'm-001',
      productUuid: 'p-001',
      delta: 25,
      reason: 'received',
      note: 'Morning delivery',
      createdAt: DateTime(2026, 9, 13, 8, 30),
      userId: 'demo-user',
      synced: true,
    ),
    Movement(
      uuid: 'm-002',
      productUuid: 'p-001',
      delta: -17,
      reason: 'sold',
      createdAt: DateTime(2026, 9, 13, 18),
      userId: 'demo-user',
      synced: true,
    ),
    Movement(
      uuid: 'm-003',
      productUuid: 'p-002',
      delta: 20,
      reason: 'received',
      createdAt: DateTime(2026, 9, 12, 9),
      userId: 'demo-user',
      synced: true,
    ),
    Movement(
      uuid: 'm-004',
      productUuid: 'p-002',
      delta: -14,
      reason: 'sold',
      createdAt: DateTime(2026, 9, 13, 17),
      userId: 'demo-user',
      synced: false,
    ),
    Movement(
      uuid: 'm-005',
      productUuid: 'p-003',
      delta: 12,
      reason: 'received',
      createdAt: DateTime(2026, 9, 12, 10),
      userId: 'demo-user',
      synced: true,
    ),
    Movement(
      uuid: 'm-006',
      productUuid: 'p-003',
      delta: -8,
      reason: 'sold',
      createdAt: DateTime(2026, 9, 13, 16),
      userId: 'demo-user',
      synced: true,
    ),
    Movement(
      uuid: 'm-007',
      productUuid: 'p-004',
      delta: 4,
      reason: 'received',
      createdAt: DateTime(2026, 9, 13, 11),
      userId: 'demo-user',
      synced: true,
    ),
    Movement(
      uuid: 'm-008',
      productUuid: 'p-005',
      delta: 18,
      reason: 'received',
      createdAt: DateTime(2026, 9, 13, 12),
      userId: 'demo-user',
      synced: true,
    ),
    Movement(
      uuid: 'm-009',
      productUuid: 'p-005',
      delta: -15,
      reason: 'sold',
      createdAt: DateTime(2026, 9, 13, 19),
      userId: 'demo-user',
      synced: true,
    ),
  ];

  @override
  Future<List<Movement>> getForProduct(String productUuid) async {
    await Future<void>.delayed(const Duration(microseconds: 150));
    final result = _movements
        .where((movement) => movement.productUuid == productUuid)
        .toList();
    return result;
  }

  @override
  Future<Movement> add(Movement movement) async {
    _movements.add(movement);
    return movement;
  }

  @override
  Future<int> getStock(String productUuid) async {
    int total = 0;
    for (final movement in _movements) {
      if (movement.productUuid == productUuid) {
        total += movement.delta;
      }
    }
    return total;
  }
}
