import '../../data/models/movement.dart';

/// Stock is never stored: it is the sum of the ledger.
int stockFromLedger(Iterable<Movement> movements) =>
    movements.fold(0, (total, movement) => total + movement.delta);

/// Stock per product uuid for a mixed ledger.
Map<String, int> stockByProduct(Iterable<Movement> movements) {
  final totals = <String, int>{};
  for (final movement in movements) {
    totals[movement.productUuid] = (totals[movement.productUuid] ?? 0) + movement.delta;
  }
  return totals;
}

/// Balance right after each movement, for a history list sorted newest first.
List<int> runningBalances(List<Movement> newestFirst, int currentStock) {
  final balances = List<int>.filled(newestFirst.length, 0);
  var running = currentStock;
  for (var i = 0; i < newestFirst.length; i++) {
    balances[i] = running;
    running -= newestFirst[i].delta;
  }
  return balances;
}
