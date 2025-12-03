import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/payment_event.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('autoverify.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE payment_events (
        id TEXT PRIMARY KEY,
        provider TEXT NOT NULL,
        rawText TEXT NOT NULL,
        sender TEXT NOT NULL,
        parsedAmount REAL,
        parsedTrx TEXT,
        parsedPhone TEXT,
        timestamp INTEGER NOT NULL,
        status TEXT NOT NULL
      )
    ''');
  }

  Future<void> insertEvent(PaymentEvent event) async {
    final db = await instance.database;
    
    // Prevent duplicates based on Trx ID if present
    if (event.parsedTrx != null && event.parsedTrx!.isNotEmpty) {
      final List<Map<String, dynamic>> maps = await db.query(
        'payment_events',
        where: 'parsedTrx = ?',
        whereArgs: [event.parsedTrx],
      );
      if (maps.isNotEmpty) {
        // Duplicate transaction found, skip insertion
        return;
      }
    }

    await db.insert(
      'payment_events',
      event.toJson(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<PaymentEvent>> getPendingEvents() async {
    final db = await instance.database;
    final result = await db.query(
      'payment_events',
      where: 'status = ?',
      whereArgs: ['pending'],
    );
    return result.map((json) => PaymentEvent.fromJson(json)).toList();
  }
  
  Future<List<PaymentEvent>> getAllEvents() async {
    final db = await instance.database;
    final result = await db.query('payment_events', orderBy: 'timestamp DESC', limit: 50);
    return result.map((json) => PaymentEvent.fromJson(json)).toList();
  }

  Future<void> markEventsAsUploaded(List<String> ids) async {
    final db = await instance.database;
    final batch = db.batch();
    for (final id in ids) {
      batch.update(
        'payment_events',
        {'status': 'uploaded'},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await batch.commit(noResult: true);
  }
}
