import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/databases/db_sync_queue.dart';
import '../../../data/models/movement.dart';
import '../../../data/models/product.dart';
import '../../../data/models/sync_models.dart';
import '../../../data/repositories/products_repo.dart';
import '../../../data/services/data_change_bus.dart';
import '../../../data/services/sync_service.dart';
import '../../../infrastructure/app_prefs.dart';
import '../failure.dart';
import 'sync_state.dart';

class SyncCubit extends Cubit<SyncState> {
  final SyncService service;
  final SyncQueueDb queue;
  final ProductsRepo products;
  final AppPrefs prefs;
  final DataChangeBus bus;
  final Duration debounce;
  bool _online;
  Timer? _debounceTimer;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  SyncCubit({
    required this.service,
    required this.queue,
    required this.products,
    required this.prefs,
    required this.bus,
    required Stream<bool> connectivity,
    bool initiallyOnline = true,
    this.debounce = const Duration(seconds: 3),
  })  : _online = initiallyOnline,
        super(const SyncIdle(SyncOverview())) {
    _subscriptions.add(bus.stream.listen((change) {
      refresh();
      // A local write syncs shortly after, batching quick successive taps.
      if (change == DataChange.local) _scheduleSync();
    }));
    _subscriptions.add(connectivity.listen((online) {
      final cameBack = online && !_online;
      _online = online;
      if (cameBack && service.api.isConfigured) syncNow();
    }));
  }

  bool get isOnline => _online;

  Future<void> refresh() async {
    final overview = await _overview();
    if (isClosed) return;
    emit(switch (state) {
      SyncInProgress() => SyncInProgress(overview),
      SyncFailed(:final failure) => SyncFailed(overview, failure),
      SyncIdle(:final lastReport) => SyncIdle(overview, lastReport),
    });
  }

  void _scheduleSync() {
    if (!service.api.isConfigured) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () {
      if (_online) syncNow();
    });
  }

  Future<void> syncNow() async {
    if (state is SyncInProgress || isClosed) return;
    emit(SyncInProgress(state.overview));
    try {
      final report = await service.run();
      if (!isClosed) emit(SyncIdle(await _overview(), report));
    } catch (e) {
      if (!isClosed) emit(SyncFailed(await _overview(), Failure.from(e)));
    }
  }

  Future<void> dismissConflict(int id) async {
    await queue.dismissConflict(id);
    await refresh();
  }

  Future<SyncOverview> _overview() async {
    final jobs = await queue.pending();
    final names = <String, String>{
      for (final Product p in await products.getProducts()) p.uuid: p.name,
    };
    final pending = [
      for (final job in jobs.reversed)
        switch (job.entity) {
          SyncEntity.movement => PendingChange(
              jobId: job.id!,
              entity: job.entity,
              productName: names[job.payload['product_uuid']] ?? '—',
              reason: MovementReason.parse(job.payload['reason'] as String),
              delta: (job.payload['delta'] as num).toInt(),
              createdAt: job.createdAt,
              attempts: job.attempts,
            ),
          SyncEntity.product => PendingChange(
              jobId: job.id!,
              entity: job.entity,
              productName: job.payload['name'] as String? ?? '—',
              createdAt: job.createdAt,
              attempts: job.attempts,
            ),
        },
    ];
    final last = prefs.lastSyncAt;
    return SyncOverview(
      pending: pending,
      conflicts: await queue.conflicts(),
      lastSyncAt: last == null ? null : DateTime.tryParse(last)?.toLocal(),
      serverConfigured: service.api.isConfigured,
    );
  }

  @override
  Future<void> close() async {
    _debounceTimer?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
