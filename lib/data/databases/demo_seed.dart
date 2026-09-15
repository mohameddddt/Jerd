import 'package:sqflite/sqflite.dart';
import '../repositories/demo_data.dart';
import 'db_helper.dart';

/// Fills an empty database with the sample shop for offline demo logins.
/// Rows are marked synced and never queued: they are not real changes.
Future<void> seedDemoData(DbHelper helper) async {
  final db = await helper.database;
  final existing = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM products')) ?? 0;
  if (existing > 0) return;
  await db.transaction((txn) async {
    for (final product in DemoData.products()) {
      await txn.insert('products', product.toMap());
    }
    for (final movement in DemoData.movements()) {
      await txn.insert('movements', movement.toMap());
    }
  });
}
