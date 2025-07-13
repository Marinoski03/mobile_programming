// lib/helpers/trip_database_helper.dart

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

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE trips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        location TEXT NOT NULL,
        continent TEXT NOT NULL DEFAULT 'Sconosciuto',
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        category TEXT NOT NULL,
        notes TEXT,
        imageUrls TEXT,
        isFavorite INTEGER NOT NULL DEFAULT 0,
        toBeRepeated INTEGER NOT NULL DEFAULT 0  -- <--- CORRETTO: da toRepeat a toBeRepeated
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE trips ADD COLUMN isFavorite INTEGER DEFAULT 0;',
      );
      if (oldVersion < 2) {
        await db.execute(
          'ALTER TABLE trips ADD COLUMN toBeRepeated INTEGER DEFAULT 0;',
        );
      }
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE trips ADD COLUMN continent TEXT DEFAULT "Sconosciuto";',
      );
    }
  }

  Future<Trip> insertTrip(Trip trip) async {
    final db = await instance.database;
    final id = await db.insert(
      'trips',
      trip.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return trip.copy(id: id);
  }

  Future<Trip> getTripById(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'trips',
      columns: [
        'id',
        'title',
        'location',
        'continent',
        'startDate',
        'endDate',
        'category',
        'notes',
        'imageUrls',
        'isFavorite',
        'toBeRepeated',
      ],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Trip.fromMap(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<Trip>> getAllTrips() async {
    final db = await instance.database;
    final result = await db.query('trips', orderBy: 'endDate DESC');
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

  Future close() async {
    final db = await instance.database;
    if (_database != null) {
      await db.close();
      _database = null;
    }
  }
}
