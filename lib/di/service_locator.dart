import 'package:get_it/get_it.dart';
import '../data/repositories/movements_dummy.dart';
import '../data/repositories/movements_repo.dart';
import '../data/repositories/products_dummy.dart';
import '../data/repositories/products_repo.dart';

final getIt = GetIt.instance;

void initMyApp() {
  if (!getIt.isRegistered<ProductsRepo>()) {
    getIt.registerLazySingleton<ProductsRepo>(ProductsDummy.new);
  }
  if (!getIt.isRegistered<MovementsRepo>()) {
    getIt.registerLazySingleton<MovementsRepo>(MovementsDummy.new);
  }
}