import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/trip.dart';

class TripDatabaseHelper {
  static final TripDatabaseHelper instance = TripDatabaseHelper._init();
  static Database? _database;

  TripDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('trips.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // In lib/helpers/trip_database_helper.dart
  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE trips (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      location TEXT NOT NULL,
      startDate TEXT NOT NULL,
      endDate TEXT NOT NULL,
      description TEXT NOT NULL,  
      imageUrls TEXT,
      isFavorite INTEGER NOT NULL,
      toRepeat INTEGER NOT NULL,  
      category TEXT NOT NULL
    )
  ''');
  }

  Future<int> insertTrip(Trip trip) async {
    final db = await instance.database;
    return await db.insert('trips', trip.toMap());
  }

  Future<List<Trip>> getAllTrips() async {
    final db = await instance.database;
    final result = await db.query('trips');

    return result.map((json) => Trip.fromMap(json)).toList();
  }

  Future<int> updateTrip(Trip trip) async {
    final db = await instance.database;
    return db.update(
      'trips',
      trip.toMap(),
      where: 'id = ?',
      whereArgs: [trip.id],
    );
  }

  Future<int> deleteTrip(int id) async {
    final db = await instance.database;
    return await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }
}
