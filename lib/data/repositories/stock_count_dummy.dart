import 'package:uuid/uuid.dart';
import '../models/movement.dart';
import '../models/stock_count.dart';
import 'movements_repo.dart';
import 'stock_count_repo.dart';

class StockCountDummy implements StockCountRepo {
  final MovementsRepo movements;
  final DateTime Function() clock;
  StockCount? _active;
  final Map<String, CountLine> _lines = {};

  StockCountDummy(this.movements, {DateTime Function()? clock}) : clock = clock ?? DateTime.now;

  @override
  Future<ActiveCount?> getActive() async {
    final active = _active;
    if (active == null) return null;
    final lines = _lines.values.toList()..sort((a, b) => a.scannedAt.compareTo(b.scannedAt));
    return ActiveCount(active, lines);
  }

  @override
  Future<StockCount> start() async =>
      _active ??= StockCount(uuid: const Uuid().v4(), startedAt: clock());

  @override
  Future<void> saveLine(CountLine line) async {
    final existing = _lines[line.productUuid];
    _lines[line.productUuid] =
        existing == null ? line : existing.copyWith(countedQty: line.countedQty);
  }

  @override
  Future<void> commit(String countUuid, List<Movement> adjustments) async {
    await movements.addBatch(adjustments);
    _reset();
  }

  @override
  Future<void> cancel(String countUuid) async => _reset();

  void _reset() {
    _active = null;
    _lines.clear();
  }
}
