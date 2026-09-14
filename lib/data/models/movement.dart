class Movement {
  final String uuid;
  final String productUuid;
  final int delta;
  final String reason;
  final String? note;
  final DateTime createdAt;
  final String userId;
  final bool synced;

  const Movement({
    required this.uuid,
    required this.productUuid,
    required this.delta,
    required this.reason,
    this.note,
    required this.createdAt,
    required this.userId,
    required this.synced,
  });
}
