import 'package:sqflite/sqflite.dart';
import '../databases/db_helper.dart';
import '../databases/db_sync_queue.dart';
import '../models/product.dart';
import 'products_repo.dart';
import 'repo_exceptions.dart';

class ProductsDb implements ProductsRepo {
  final DbHelper helper;
  final DateTime Function() clock;

  ProductsDb(this.helper, {DateTime Function()? clock}) : clock = clock ?? DateTime.now;

  @override
  Future<List<Product>> getProducts() async {
    final db = await helper.database;
    final rows = await db.query('products', where: 'deleted = 0', orderBy: 'name COLLATE NOCASE');
    return rows.map(Product.fromMap).toList();
  }

  @override
  Future<Product?> getById(String uuid) async {
    final db = await helper.database;
    final rows = await db.query('products', where: 'uuid = ? AND deleted = 0', whereArgs: [uuid]);
    return rows.isEmpty ? null : Product.fromMap(rows.first);
  }

  @override
  Future<Product?> getByBarcode(String barcode) async {
    final db = await helper.database;
    final rows = await db.query(
      'products',
      where: 'barcode = ? AND deleted = 0',
      whereArgs: [barcode.trim()],
      limit: 1,
    );
    return rows.isEmpty ? null : Product.fromMap(rows.first);
  }

  @override
  Future<Product> save(Product product) async {
    ensureValidProduct(product);
    final db = await helper.database;
    await db.transaction((txn) async {
      final clash = await txn.query(
        'products',
        columns: ['name'],
        where: 'barcode = ? AND uuid != ? AND deleted = 0',
        whereArgs: [product.barcode, product.uuid],
        limit: 1,
      );
      if (clash.isNotEmpty) {
        throw DuplicateBarcodeException(product.barcode, clash.first['name'] as String);
      }
      await writeLocal(txn, product);
      await SyncQueueDb.enqueueProduct(txn, product, clock());
    });
    return product;
  }

  @override
  Future<void> delete(String uuid, {String by = ''}) async {
    final db = await helper.database;
    await db.transaction((txn) async {
      final rows = await txn.query('products', where: 'uuid = ?', whereArgs: [uuid]);
      if (rows.isEmpty) throw NotFoundException('product $uuid');
      final deleted = Product.fromMap(rows.first)
          .copyWith(deleted: true, updatedAt: clock(), updatedBy: by);
      await writeLocal(txn, deleted);
      await SyncQueueDb.enqueueProduct(txn, deleted, clock());
    });
  }

  /// Row write without queueing — also used when applying server data.
  static Future<void> writeLocal(DatabaseExecutor txn, Product product) =>
      txn.insert('products', product.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<Product?> getAnyById(String uuid) async {
    final db = await helper.database;
    final rows = await db.query('products', where: 'uuid = ?', whereArgs: [uuid]);
    return rows.isEmpty ? null : Product.fromMap(rows.first);
  }
}
