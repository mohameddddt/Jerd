import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' show databaseFactorySqflitePlugin;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Opens the local database — the source of truth — and owns the schema.
class DbHelper {
  static const fileName = 'jerd.db';
  static const version = 1;

  final String? path;
  final DatabaseFactory? factory;
  Database? _db;

  /// [path] = `inMemoryDatabasePath` and an ffi [factory] for tests.
  DbHelper({this.path, this.factory});

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    var dbFactory = factory;
    if (dbFactory == null && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      dbFactory = databaseFactoryFfi;
    }
    dbFactory ??= databaseFactorySqflitePlugin;
    return dbFactory.openDatabase(
      path ?? p.join(await dbFactory.getDatabasesPath(), fileName),
      options: OpenDatabaseOptions(
        version: version,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, _) => createSchema(db),
        onUpgrade: _upgrade,
      ),
    );
  }

  static Future<void> createSchema(DatabaseExecutor db) async {
    final batch = db.batch();
    batch.execute('''
      CREATE TABLE products (
        uuid TEXT PRIMARY KEY,
        barcode TEXT NOT NULL,
        name TEXT NOT NULL,
        unit TEXT NOT NULL,
        reorder_point INTEGER NOT NULL DEFAULT 0,
        image_url TEXT,
        updated_at TEXT NOT NULL,
        updated_by TEXT NOT NULL DEFAULT '',
        deleted INTEGER NOT NULL DEFAULT 0
      )''');
    // A scan must resolve in under a second at 2,000 products.
    batch.execute('CREATE INDEX idx_products_barcode ON products(barcode)');
    batch.execute('''
      CREATE TABLE movements (
        uuid TEXT PRIMARY KEY,
        product_uuid TEXT NOT NULL,
        delta INTEGER NOT NULL,
        reason TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        user_id TEXT NOT NULL,
        user_name TEXT NOT NULL DEFAULT '',
        synced INTEGER NOT NULL DEFAULT 0
      )''');
    batch.execute('CREATE INDEX idx_movements_product ON movements(product_uuid, created_at)');
    batch.execute('''
      CREATE TABLE stock_counts (
        uuid TEXT PRIMARY KEY,
        started_at TEXT NOT NULL,
        finished_at TEXT,
        status TEXT NOT NULL
      )''');
    batch.execute('''
      CREATE TABLE count_lines (
        count_uuid TEXT NOT NULL REFERENCES stock_counts(uuid) ON DELETE CASCADE,
        product_uuid TEXT NOT NULL,
        counted_qty INTEGER NOT NULL,
        scanned_at TEXT NOT NULL,
        PRIMARY KEY (count_uuid, product_uuid)
      )''');
    batch.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity TEXT NOT NULL,
        entity_uuid TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        created_at TEXT NOT NULL,
        last_attempt_at TEXT
      )''');
    batch.execute('''
      CREATE TABLE sync_conflicts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_uuid TEXT NOT NULL,
        kept_name TEXT NOT NULL,
        kept_by TEXT NOT NULL,
        kept_at TEXT NOT NULL,
        lost_name TEXT NOT NULL,
        lost_by TEXT NOT NULL,
        lost_at TEXT NOT NULL,
        created_at TEXT NOT NULL
      )''');
    batch.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )''');
    await batch.commit(noResult: true);
  }

  /// v2 will add supplier fields here, e.g.
  /// `if (oldVersion < 2) await db.execute('ALTER TABLE products ADD COLUMN supplier TEXT');`
  Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {}

  /// Wipes local data on sign-out so the next user never sees another shop.
  Future<void> clearAll() async {
    final db = await database;
    await db.transaction((txn) async {
      for (final table in [
        'count_lines',
        'stock_counts',
        'sync_queue',
        'sync_conflicts',
        'movements',
        'products',
        'settings',
      ]) {
        await txn.delete(table);
      }
    });
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
