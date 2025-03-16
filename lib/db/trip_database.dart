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
        origLat REAL NOT NULL,
        origLng REAL NOT NULL,
        destination TEXT NOT NULL,
        destLat REAL NOT NULL,
        destLng REAL NOT NULL,
        distance TEXT NOT NULL,
        emissions REAL NOT NULL,
        mode TEXT NOT NULL,
        reduction REAL NOT NULL DEFAULT 0,
        complete INTEGER NOT NULL DEFAULT 0,
        model TEXT NOT NULL DEFAULT ""
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE trips ADD COLUMN reduction REAL NOT NULL DEFAULT 0');
      await db.execute(
          'ALTER TABLE trips ADD COLUMN complete INTEGER NOT NULL DEFAULT 0');
      await db.execute(
          'ALTER TABLE trips ADD COLUMN model TEXT NOT NULL DEFAULT ""');
    }
  }

  Future<int> insertTrip(Trip trip) async {
    final db = await instance.database;
    return await db.insert('trips', trip.toMap());
  }

  Future<int> updateTripCompletion(int id, bool complete) async {
    final db = await instance.database;
    return await db.update(
      'trips',
      {'complete': complete ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Trip>> getAllTrips() async {
    final db = await instance.database;
    final result = await db.query('trips');
    return result.map((map) => Trip.fromMap(map)).toList();
  }

  Future<int> deleteTrip(int id) async {
    final db = await instance.database;
    return await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }

  Future<Trip?> getTripById(int id) async {
    final db = await database;
    final maps = await db.query(
      'trips',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Trip.fromMap(maps.first);
    }
    return null;
  }
}
