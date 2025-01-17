import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:the_carbon_conscious_traveller/models/trip.dart';

class TripDatabase {
  static final TripDatabase instance = TripDatabase._init();
  static Database? _database;

  TripDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'trips.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE trips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        origin TEXT NOT NULL,
        origLat REAL NOT NULL DEFAULT 0,
        origLng REAL NOT NULL DEFAULT 0,
        destination TEXT NOT NULL,
        destLat REAL NOT NULL DEFAULT 0,
        destLng REAL NOT NULL DEFAULT 0,
        distance TEXT NOT NULL,
        emissions REAL NOT NULL,
        mode TEXT NOT NULL,
        vehicle TEXT NULL  -- Allow vehicle to be NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE trips ADD COLUMN vehicle TEXT NULL
      ''');
    }
  }

  Future<int> insertTrip(Trip trip) async {
    final db = await instance.database;
    return await db.insert(
      'trips',
      trip.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Trip>> getAllTrips() async {
    final db = await instance.database;
    final result = await db.query('trips');
    return result.map((json) => Trip.fromMap(json)).toList();
  }

  Future<int> deleteTrip(int id) async {
    final db = await instance.database;
    return await db.delete(
      'trips',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await _database;
    if (db != null) {
      await db.close();
    }
  }
}
