import '../models/movement.dart';

abstract class MovementsRepo {
  Future<List<Movement>> getForProduct(String productUuid);
  Future<Movement> add(Movement movement);
  Future<int> getStock(String productUuid);
}
