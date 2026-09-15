import 'package:equatable/equatable.dart';
import '../../data/models/movement.dart';

class CountDifference extends Equatable {
  final String productUuid;
  final int expected;
  final int counted;

  const CountDifference({
    required this.productUuid,
    required this.expected,
    required this.counted,
  });

  int get delta => counted - expected;

  @override
  List<Object?> get props => [productUuid, expected, counted];
}

/// Products whose counted quantity differs from the ledger, in counting order.
/// Products that were not counted are left alone.
List<CountDifference> reconcileCount({
  required Map<String, int> expected,
  required Map<String, int> counted,
}) {
  return [
    for (final entry in counted.entries)
      if (entry.value != (expected[entry.key] ?? 0))
        CountDifference(
          productUuid: entry.key,
          expected: expected[entry.key] ?? 0,
          counted: entry.value,
        ),
  ];
}

/// One adjustment movement per difference — committed together as a batch.
List<Movement> adjustmentsForCount({
  required List<CountDifference> differences,
  required String Function() newUuid,
  required DateTime now,
  required String userId,
  required String userName,
  String? note,
}) {
  return [
    for (final difference in differences)
      Movement(
        uuid: newUuid(),
        productUuid: difference.productUuid,
        delta: difference.delta,
        reason: MovementReason.counted,
        note: note,
        createdAt: now,
        userId: userId,
        userName: userName,
      ),
  ];
}
