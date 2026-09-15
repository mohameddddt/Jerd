import 'package:equatable/equatable.dart';
import '../../../data/models/movement.dart';
import '../../../data/models/sync_models.dart';
import '../failure.dart';

/// One row of "Waiting to upload".
class PendingChange extends Equatable {
  final int jobId;
  final SyncEntity entity;
  final String productName;
  final MovementReason? reason;
  final int delta;
  final DateTime createdAt;
  final int attempts;

  const PendingChange({
    required this.jobId,
    required this.entity,
    required this.productName,
    this.reason,
    this.delta = 0,
    required this.createdAt,
    this.attempts = 0,
  });

  @override
  List<Object?> get props => [jobId, entity, productName, reason, delta, createdAt, attempts];
}

/// What the sync screen always shows, whatever the phase.
class SyncOverview extends Equatable {
  final List<PendingChange> pending;
  final List<SyncConflict> conflicts;
  final DateTime? lastSyncAt;
  final bool serverConfigured;

  const SyncOverview({
    this.pending = const [],
    this.conflicts = const [],
    this.lastSyncAt,
    this.serverConfigured = false,
  });

  @override
  List<Object?> get props => [pending, conflicts, lastSyncAt, serverConfigured];
}

sealed class SyncState extends Equatable {
  final SyncOverview overview;

  const SyncState(this.overview);

  @override
  List<Object?> get props => [overview];
}

class SyncIdle extends SyncState {
  final SyncReport? lastReport;

  const SyncIdle(super.overview, [this.lastReport]);

  @override
  List<Object?> get props => [overview, lastReport];
}

class SyncInProgress extends SyncState {
  const SyncInProgress(super.overview);
}

class SyncFailed extends SyncState {
  final Failure failure;

  const SyncFailed(super.overview, this.failure);

  @override
  List<Object?> get props => [overview, failure];
}
