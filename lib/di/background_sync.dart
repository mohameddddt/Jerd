import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import '../data/services/sync_service.dart';
import '../infrastructure/app_config.dart';
import '../infrastructure/app_logger.dart';
import '../infrastructure/app_prefs.dart';
import 'service_locator.dart';

@pragma('vm:entry-point')
void backgroundSyncDispatcher() {
  Workmanager().executeTask((task, _) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await initMyApp();
      final prefs = getIt<AppPrefs>();
      await prefs.reload();
      if (!prefs.isLoggedIn || !AppConfig.hasBackend) return true;
      await getIt<SyncService>().run();
      return true;
    } catch (e, st) {
      AppLogger.error('Background sync failed', e, st);
      // false asks WorkManager to retry with its own backoff.
      return false;
    }
  });
}

/// Periodic sync every 15 minutes — the Android floor — when a network is up.
abstract final class BackgroundSync {
  static bool get isSupported => Platform.isAndroid;

  static Future<void> register() async {
    if (!isSupported || !AppConfig.hasBackend) return;
    try {
      await Workmanager().initialize(backgroundSyncDispatcher);
      await Workmanager().registerPeriodicTask(
        AppConfig.backgroundSyncTask,
        AppConfig.backgroundSyncTask,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    } catch (e, st) {
      AppLogger.error('Could not schedule background sync', e, st);
    }
  }

  static Future<void> cancel() async {
    if (!isSupported) return;
    await Workmanager().cancelByUniqueName(AppConfig.backgroundSyncTask);
  }
}
