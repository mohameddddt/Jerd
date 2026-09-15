import '../models/movement.dart';
import '../models/stock_count.dart';

class ActiveCount {
  final StockCount count;

  /// In scanning order.
  final List<CountLine> lines;

  const ActiveCount(this.count, this.lines);
}

abstract class StockCountRepo {
  Future<ActiveCount?> getActive();

  Future<StockCount> start();

  /// Saved on every change, so a force-close never loses a count.
  Future<void> saveLine(CountLine line);

  /// Writes the adjustments and closes the session in one transaction.
  Future<void> commit(String countUuid, List<Movement> adjustments);

  Future<void> cancel(String countUuid);
}
