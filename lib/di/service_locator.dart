import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/databases/db_helper.dart';
import '../data/databases/db_sync_queue.dart';
import '../data/databases/demo_seed.dart';
import '../data/models/app_user.dart';
import '../data/repositories/auth_api.dart';
import '../data/repositories/auth_demo.dart';
import '../data/repositories/auth_repo.dart';
import '../data/repositories/movements_api.dart';
import '../data/repositories/movements_db.dart';
import '../data/repositories/movements_dummy.dart';
import '../data/repositories/movements_repo.dart';
import '../data/repositories/products_api.dart';
import '../data/repositories/products_db.dart';
import '../data/repositories/products_dummy.dart';
import '../data/repositories/products_repo.dart';
import '../data/repositories/stock_count_db.dart';
import '../data/repositories/stock_count_dummy.dart';
import '../data/repositories/stock_count_repo.dart';
import '../data/services/ai_service.dart';
import '../data/services/connectivity_service.dart';
import '../data/services/data_change_bus.dart';
import '../data/services/messaging_service.dart';
import '../data/services/storage_service.dart';
import '../data/services/sync_api.dart';
import '../data/services/sync_service.dart';
import '../data/services/upgrade_service.dart';
import '../infrastructure/api_client.dart';
import '../infrastructure/app_config.dart';
import '../infrastructure/app_prefs.dart';

final getIt = GetIt.instance;

enum DataSource { dummy, db, api }

/// Registers everything as lazy singletons. Runs from `main` before the app
/// starts, and from the WorkManager isolate before a background sync.
Future<void> initMyApp({DataSource? source}) async {
  if (getIt.isRegistered<AppPrefs>()) return;

  getIt.registerSingleton<AppPrefs>(AppPrefs(await SharedPreferences.getInstance()));
  getIt.registerLazySingleton<DataChangeBus>(DataChangeBus.new);
  getIt.registerLazySingleton<DbHelper>(DbHelper.new);
  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(baseUrl: AppConfig.apiBaseUrl, tokenProvider: () => getIt<AppPrefs>().token),
  );

  // Infrastructure-backed stores that the sync engine needs whatever the source.
  getIt.registerLazySingleton<SyncQueueDb>(() => SyncQueueDb(getIt()));
  getIt.registerLazySingleton<ProductsDb>(() => ProductsDb(getIt()));
  getIt.registerLazySingleton<MovementsDb>(() => MovementsDb(getIt()));

  // The one-line swap between dummy, SQLite and API repositories.
  _registerRepositories(source ?? _configuredSource());

  getIt.registerLazySingleton<AuthRepo>(
    () => AppConfig.hasBackend
        ? AuthApi(getIt())
        : AuthDemo(currentUser: () => getIt<AppPrefs>().user),
  );

  getIt.registerLazySingleton<ConnectivityService>(ConnectivityService.new);
  getIt.registerLazySingleton<StorageService>(StorageService.new);
  getIt.registerLazySingleton<SyncApi>(() => SyncApi(getIt()));
  getIt.registerLazySingleton<SyncService>(
    () => SyncService(
      db: getIt(),
      queue: getIt(),
      products: getIt(),
      movements: getIt(),
      api: getIt(),
      storage: getIt(),
      prefs: getIt(),
      bus: getIt(),
    ),
  );
  getIt.registerLazySingleton<MessagingService>(() => MessagingService(getIt()));
  getIt.registerLazySingleton<AiService>(() => AiService(getIt()));
  getIt.registerLazySingleton<UpgradeService>(() => UpgradeService(getIt()));
}

DataSource _configuredSource() => DataSource.values.firstWhere(
      (s) => s.name == AppConfig.dataSource,
      orElse: () => DataSource.db,
    );

void _registerRepositories(DataSource source) {
  switch (source) {
    case DataSource.dummy:
      getIt.registerLazySingleton<ProductsRepo>(ProductsDummy.new);
      getIt.registerLazySingleton<MovementsRepo>(MovementsDummy.new);
      getIt.registerLazySingleton<StockCountRepo>(() => StockCountDummy(getIt()));
    case DataSource.db:
      getIt.registerLazySingleton<ProductsRepo>(() => getIt<ProductsDb>());
      getIt.registerLazySingleton<MovementsRepo>(() => getIt<MovementsDb>());
      getIt.registerLazySingleton<StockCountRepo>(() => StockCountDb(getIt()));
    case DataSource.api:
      getIt.registerLazySingleton<ProductsRepo>(() => ProductsApi(getIt()));
      getIt.registerLazySingleton<MovementsRepo>(() => MovementsApi(getIt()));
      getIt.registerLazySingleton<StockCountRepo>(() => StockCountDummy(getIt()));
  }
}

/// Runs after a successful login (and on restored sessions).
Future<void> onSignedIn(AppUser user) async {
  if (!AppConfig.hasBackend && _configuredSource() == DataSource.db) {
    await seedDemoData(getIt<DbHelper>());
  }
  await getIt<MessagingService>().registerForShop(user.shopId);
}

/// Runs before sign-out: another staff member may use this phone next.
Future<void> onSigningOut(AppUser user) async {
  await getIt<MessagingService>().unregisterFromShop(user.shopId);
  await getIt<DbHelper>().clearAll();
  await getIt<AppPrefs>().setActiveCountUuid(null);
}

Future<void> resetServiceLocator() => getIt.reset();
