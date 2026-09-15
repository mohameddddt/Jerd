import 'package:equatable/equatable.dart';
import '../../../data/models/product.dart';
import '../../../data/models/stock_count.dart';
import '../../domain/reconcile_count.dart';
import '../failure.dart';

sealed class StockCountState extends Equatable {
  const StockCountState();

  @override
  List<Object?> get props => [];
}

class StockCountIdle extends StockCountState {
  const StockCountIdle();
}

class StockCountLoading extends StockCountState {
  const StockCountLoading();
}

class StockCountCounting extends StockCountState {
  final StockCount count;
  final Map<String, Product> products;
  final Map<String, int> expected;

  /// Counted quantity per product, in scanning order.
  final List<MapEntry<String, int>> lines;
  final Duration elapsed;

  /// The product shown in the "Just scanned" card.
  final String? current;

  const StockCountCounting({
    required this.count,
    required this.products,
    required this.expected,
    required this.lines,
    required this.elapsed,
    this.current,
  });

  Map<String, int> get counted => Map.fromEntries(lines);

  int get totalProducts => products.length;
  int get countedProducts => lines.length;
  double get progress => totalProducts == 0 ? 0 : countedProducts / totalProducts;

  List<CountDifference> get differences =>
      reconcileCount(expected: expected, counted: counted);

  int countedOf(String uuid) => counted[uuid] ?? 0;
  int expectedOf(String uuid) => expected[uuid] ?? 0;

  bool get hasUnsavedWork => lines.isNotEmpty;

  StockCountCounting copyWith({
    List<MapEntry<String, int>>? lines,
    Duration? elapsed,
    String? current,
  }) =>
      StockCountCounting(
        count: count,
        products: products,
        expected: expected,
        lines: lines ?? this.lines,
        elapsed: elapsed ?? this.elapsed,
        current: current ?? this.current,
      );

  @override
  List<Object?> get props => [count, products, expected, lines, elapsed, current];
}

/// The user tapped "Finish": review the differences before committing.
class StockCountReconciling extends StockCountState {
  final StockCountCounting counting;

  const StockCountReconciling(this.counting);

  List<CountDifference> get differences => counting.differences;

  @override
  List<Object?> get props => [counting];
}

class StockCountCommitted extends StockCountState {
  final int adjustments;

  const StockCountCommitted(this.adjustments);

  @override
  List<Object?> get props => [adjustments];
}

class StockCountError extends StockCountState {
  final Failure failure;

  const StockCountError(this.failure);

  @override
  List<Object?> get props => [failure];
}
