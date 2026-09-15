import 'package:jerd/data/databases/db_helper.dart';
import 'package:jerd/data/models/app_user.dart';
import 'package:jerd/data/models/movement.dart';
import 'package:jerd/data/models/product.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

DbHelper memoryDb() {
  sqfliteFfiInit();
  return DbHelper(path: inMemoryDatabasePath, factory: databaseFactoryFfiNoIsolate);
}

final testNow = DateTime(2026, 9, 14, 10);

const owner = AppUser(
  id: 'u-owner',
  name: 'Karim',
  email: 'karim@example.com',
  role: UserRole.owner,
  shopId: 's1',
);

const staff = AppUser(
  id: 'u-staff',
  name: 'Amina',
  email: 'amina@example.com',
  role: UserRole.staff,
  shopId: 's1',
);

Product aProduct({
  String uuid = 'p1',
  String name = 'Olive oil 1L',
  String barcode = '6130000100010',
  int reorder = 6,
  DateTime? updatedAt,
  String by = 'Karim',
}) =>
    Product(
      uuid: uuid,
      barcode: barcode,
      name: name,
      unit: 'bottles',
      reorderPoint: reorder,
      updatedAt: updatedAt ?? testNow,
      updatedBy: by,
    );

Movement aMovement({
  String uuid = 'm1',
  String product = 'p1',
  int delta = 10,
  MovementReason reason = MovementReason.received,
  DateTime? at,
}) =>
    Movement(
      uuid: uuid,
      productUuid: product,
      delta: delta,
      reason: reason,
      createdAt: at ?? testNow,
      userId: 'u-owner',
      userName: 'Karim',
    );
