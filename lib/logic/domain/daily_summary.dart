import 'package:equatable/equatable.dart';
import '../../data/models/movement.dart';

class DailySummary extends Equatable {
  final int received;
  final int sold;

  /// Net change from manual adjustments and stock counts.
  final int adjusted;
  final int movements;

  const DailySummary({
    this.received = 0,
    this.sold = 0,
    this.adjusted = 0,
    this.movements = 0,
  });

  @override
  List<Object?> get props => [received, sold, adjusted, movements];
}

DailySummary summarizeDay(Iterable<Movement> ledger, DateTime day) {
  var received = 0, sold = 0, adjusted = 0, count = 0;
  for (final movement in ledger) {
    final at = movement.createdAt;
    if (at.year != day.year || at.month != day.month || at.day != day.day) continue;
    count++;
    switch (movement.reason) {
      case MovementReason.received:
        received += movement.delta;
      case MovementReason.sold:
        sold += -movement.delta;
      case MovementReason.adjusted:
      case MovementReason.counted:
        adjusted += movement.delta;
    }
  }
  return DailySummary(received: received, sold: sold, adjusted: adjusted, movements: count);
}
