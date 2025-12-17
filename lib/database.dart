import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'model/history_tracker.dart';

// Simple SQLite helper using `sqflite`. It creates a `rates` table
// and provides methods to insert snapshots, fetch the latest value for a
// currency/base pair, and to fetch either the latest snapshot per currency
// or the full history for a specific currency/base pair.

class DatabaseHelper {
  // ensure only one database connection exists
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  // returns same instance
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  // Cached database instance
  Database? _db;

  Future<Database> get database async {
    // return if database is already open
    if (_db != null) return _db!;
    // if not, initialize
    _db = await _initDb();
    return _db!;
  }

  // Initializes the SQLite database and creates tables if needed
  Future<Database> _initDb() async {
    // create dabase file path
    String path = join(await getDatabasesPath(), 'currency_tracker.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create a simple `rates` table. `date` is stored as TEXT (ISO
        // timestamp string) so we can order by it. Each insert replaces
        // conflicting rows to keep the latest value when needed.
        await db.execute('''
          CREATE TABLE rates(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            currency TEXT,
            baseCurrency TEXT,
            rate REAL,
            date TEXT
          )
        ''');
      },
    );
  }

  // inserts a rate into the db
  // replaced existing rows if a conflict occurs
  Future<void> insertRate(HistoryTracker rate) async {
    final db = await database;
    await db.insert(
      'rates',
      rate.toMap(), // Convert model object to Map<String, dynamic>
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Fetch the most recent rate for a given base/currency pair
  Future<HistoryTracker?> getLatestRate(String base, String currency) async {
    final db = await database;
    final result = await db.query(
      'rates',
      where: 'baseCurrency = ? AND currency = ?',
      whereArgs: [base, currency],
      orderBy: 'date DESC',
      limit: 1,
    );

    // return latest rate
    if (result.isNotEmpty) return HistoryTracker.fromMap(result.first);
    return null;
  }

  Future<List<HistoryTracker>> getCurrencyHistory(String currencyOrBase,
      [String? baseCurrency]) async {
    final db = await database;

    // if 'baseCurrency is NULL' returns the latest for each currency
    if (baseCurrency == null) {
      final result = await db.rawQuery('''
        SELECT r.*
        FROM rates r
        INNER JOIN (
          SELECT currency, MAX(date) AS maxDate
          FROM rates
          WHERE baseCurrency = ?
          GROUP BY currency
        ) grouped
        ON r.currency = grouped.currency
        AND r.date = grouped.maxDate
        WHERE r.baseCurrency = ?
        ORDER BY r.currency ASC
      ''', [currencyOrBase, currencyOrBase]);

      return result.map((e) => HistoryTracker.fromMap(e)).toList();
    } else {
      // if provided, returns full historical data for currency/base pair
      final result = await db.query(
        'rates',
        where: 'currency = ? AND baseCurrency = ?',
        whereArgs: [currencyOrBase, baseCurrency],
        orderBy: 'date DESC',
      );
      return result.map((e) => HistoryTracker.fromMap(e)).toList();
    }
  }
}
