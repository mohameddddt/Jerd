import 'dart:async';
import '../../infrastructure/app_config.dart';
import '../../infrastructure/app_logger.dart';
import '../../infrastructure/app_prefs.dart';
import '../../logic/domain/product_conflict.dart';
import '../../logic/domain/sync_backoff.dart';
import '../databases/db_helper.dart';
import '../databases/db_sync_queue.dart';
import '../models/product.dart';
import '../models/sync_models.dart';
import '../repositories/movements_db.dart';
import '../repositories/products_db.dart';
import 'data_change_bus.dart';
import 'storage_service.dart';
import 'sync_api.dart';

class SyncNotConfiguredException implements Exception {
  const SyncNotConfiguredException();
}

/// Drains the outbox, then pulls what changed on the server.
///
/// Writes never wait for this: the UI is done as soon as the local
/// transaction commits. This runs on app start, on reconnect, on "sync now"
/// and every 15 minutes from WorkManager.
class SyncService {
  final DbHelper db;
  final SyncQueueDb queue;
  final ProductsDb products;
  final MovementsDb movements;
  final SyncApi api;
  final StorageService storage;
  final AppPrefs prefs;
  final DataChangeBus bus;
  final DateTime Function() clock;

  Future<SyncReport>? _running;

  SyncService({
    required this.db,
    required this.queue,
    required this.products,
    required this.movements,
    required this.api,
    required this.storage,
    required this.prefs,
    required this.bus,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;

  bool get isRunning => _running != null;

  /// Concurrent callers share the same run.
  Future<SyncReport> run() {
    if (!api.isConfigured) return Future.error(const SyncNotConfiguredException());
    return _running ??= _run().whenComplete(() => _running = null);
  }

  Future<SyncReport> _run() async {
    var pushed = 0, pulled = 0, conflicts = 0;

    await _uploadPendingPhotos();
    final productPush = await _pushProducts();
    pushed += productPush.$1;
    conflicts += productPush.$2;
    pushed += await _pushMovements();

    pulled += await _pull();

    if (pulled > 0 || conflicts > 0) bus.notify(DataChange.remote);
    final report = SyncReport(
      pushed: pushed,
      pulled: pulled,
      conflicts: conflicts,
      finishedAt: clock(),
    );
    AppLogger.info('Sync done: pushed $pushed, pulled $pulled, conflicts $conflicts');
    return report;
  }

  List<SyncJob> _due(List<SyncJob> jobs) => jobs
      .where((job) => isRetryDue(attempts: job.attempts, lastAttemptAt: job.lastAttemptAt, now: clock()))
      .toList();

  Future<void> _uploadPendingPhotos() async {
    if (!storage.isConfigured) return;
    for (final job in await queue.pending(entity: SyncEntity.product)) {
      final product = Product.fromJson(job.payload);
      if (!product.hasLocalImage) continue;
      try {
        final url = await storage.upload(product.imageUrl!, productUuid: product.uuid);
        if (url == null) continue;
        final withUrl = product.copyWith(imageUrl: url);
        await queue.updatePayload(job.id!, withUrl.toJson());
        final current = await products.getAnyById(product.uuid);
        // Only swap the path if nobody edited the product meanwhile.
        if (current != null && current.imageUrl == product.imageUrl) {
          final database = await db.database;
          await ProductsDb.writeLocal(database, current.copyWith(imageUrl: url));
        }
      } catch (e, st) {
        // The product still syncs; the photo retries next run.
        AppLogger.error('Photo upload failed', e, st);
      }
    }
  }

  /// Returns (pushed, conflicts).
  Future<(int, int)> _pushProducts() async {
    final jobs = _due(await queue.pending(entity: SyncEntity.product))
        // A photo still on the phone must upload before its product can go.
        .where((job) => !Product.fromJson(job.payload).hasLocalImage || !storage.isConfigured)
        .toList();
    var pushed = 0, conflicts = 0;
    for (var i = 0; i < jobs.length; i += AppConfig.syncBatchSize) {
      final batch = jobs.skip(i).take(AppConfig.syncBatchSize).toList();
      final results = await _guard(batch, () => api.pushProducts(
            batch.map((job) => _withoutLocalImage(job.payload)).toList(),
          ));
      final byUuid = {for (final result in results) result.uuid: result};
      final done = <int>[];
      for (final job in batch) {
        final result = byUuid[job.entityUuid];
        if (result == null) continue;
        done.add(job.id!);
        if (result.applied) {
          pushed++;
        } else if (result.serverProduct != null) {
          conflicts += await _acceptServerVersion(Product.fromJson(job.payload), result.serverProduct!);
        }
      }
      await queue.remove(done);
    }
    return (pushed, conflicts);
  }

  Future<int> _pushMovements() async {
    final jobs = _due(await queue.pending(entity: SyncEntity.movement));
    var pushed = 0;
    for (var i = 0; i < jobs.length; i += AppConfig.syncBatchSize) {
      final batch = jobs.skip(i).take(AppConfig.syncBatchSize).toList();
      final accepted = await _guard(batch, () => api.pushMovements(batch.map((j) => j.payload).toList()));
      final done = batch.where((job) => accepted.contains(job.entityUuid)).toList();
      await queue.remove(done.map((job) => job.id!));
      await movements.markSynced(done.map((job) => job.entityUuid));
      pushed += done.length;
    }
    return pushed;
  }

  /// Pulls products and movements changed since the last cursor.
  Future<int> _pull() async {
    final since = prefs.lastSyncAt;
    final productResult = await api.pullProducts(since);
    final movementResult = await api.pullMovements(since);

    var pulled = 0;
    final database = await db.database;
    for (final remote in productResult.items) {
      // A local edit still waiting to go is resolved by the next push; don't clobber it.
      if (await queue.hasPendingFor(SyncEntity.product, remote.uuid)) continue;
      if (await products.getAnyById(remote.uuid) == remote) continue;
      await ProductsDb.writeLocal(database, remote);
      pulled++;
    }
    pulled += await movements.applyRemote(movementResult.items);

    // Advance the cursor only after every local write succeeded, and to the
    // earlier server time so nothing changed between the two requests is skipped.
    final times = [productResult.serverTime, movementResult.serverTime]..sort();
    await prefs.setLastSyncAt(times.first);
    return pulled;
  }

  /// Server kept a newer version: apply it and record what this phone lost.
  Future<int> _acceptServerVersion(Product local, Product server) async {
    final resolution = resolveProductConflict(local: local, remote: server);
    final database = await db.database;
    await ProductsDb.writeLocal(database, resolution.winner);
    final loser = resolution.loser;
    if (loser == null) return 0;
    await queue.addConflict(SyncConflict(
      productUuid: server.uuid,
      keptName: resolution.winner.name,
      keptBy: resolution.winner.updatedBy,
      keptAt: resolution.winner.updatedAt,
      lostName: loser.name,
      lostBy: loser.updatedBy,
      lostAt: loser.updatedAt,
      createdAt: clock(),
    ));
    return 1;
  }

  Future<T> _guard<T>(List<SyncJob> batch, Future<T> Function() call) async {
    try {
      return await call();
    } catch (e) {
      await queue.markFailed(batch.map((job) => job.id!), e.toString(), clock());
      rethrow;
    }
  }

  Map<String, dynamic> _withoutLocalImage(Map<String, dynamic> payload) {
    final product = Product.fromJson(payload);
    return product.hasLocalImage ? product.copyWith(clearImage: true).toJson() : payload;
  }
}
