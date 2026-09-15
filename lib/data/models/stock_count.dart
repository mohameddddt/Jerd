import 'package:equatable/equatable.dart';

enum StockCountStatus {
  inProgress,
  committed,
  cancelled;

  static StockCountStatus parse(String value) => StockCountStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => StockCountStatus.cancelled,
      );
}

/// One stock-take session.
class StockCount extends Equatable {
  final String uuid;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final StockCountStatus status;

  const StockCount({
    required this.uuid,
    required this.startedAt,
    this.finishedAt,
    this.status = StockCountStatus.inProgress,
  });

  Map<String, Object?> toMap() => {
        'uuid': uuid,
        'started_at': startedAt.toUtc().toIso8601String(),
        'finished_at': finishedAt?.toUtc().toIso8601String(),
        'status': status.name,
      };

  factory StockCount.fromMap(Map<String, Object?> map) => StockCount(
        uuid: map['uuid'] as String,
        startedAt: DateTime.parse(map['started_at'] as String).toLocal(),
        finishedAt: map['finished_at'] == null
            ? null
            : DateTime.parse(map['finished_at'] as String).toLocal(),
        status: StockCountStatus.parse(map['status'] as String),
      );

  @override
  List<Object?> get props => [uuid, startedAt, finishedAt, status];
}

/// Counted quantity for one product within a session.
class CountLine extends Equatable {
  final String countUuid;
  final String productUuid;
  final int countedQty;
  final DateTime scannedAt;

  const CountLine({
    required this.countUuid,
    required this.productUuid,
    required this.countedQty,
    required this.scannedAt,
  });

  CountLine copyWith({int? countedQty, DateTime? scannedAt}) => CountLine(
        countUuid: countUuid,
        productUuid: productUuid,
        countedQty: countedQty ?? this.countedQty,
        scannedAt: scannedAt ?? this.scannedAt,
      );

  Map<String, Object?> toMap() => {
        'count_uuid': countUuid,
        'product_uuid': productUuid,
        'counted_qty': countedQty,
        'scanned_at': scannedAt.toUtc().toIso8601String(),
      };

  factory CountLine.fromMap(Map<String, Object?> map) => CountLine(
        countUuid: map['count_uuid'] as String,
        productUuid: map['product_uuid'] as String,
        countedQty: (map['counted_qty'] as num).toInt(),
        scannedAt: DateTime.parse(map['scanned_at'] as String).toLocal(),
      );

  @override
  List<Object?> get props => [countUuid, productUuid, countedQty, scannedAt];
}
