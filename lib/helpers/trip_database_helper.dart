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
      version: 3, // <<< Assicurati che la versione sia 3 o superiore
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // --- METODO PER LA CREAZIONE DEL DATABASE ---
  Future _createDB(Database db, int version) async {
    // Ho cambiato 'toRepeat' in 'toBeRepeated' qui per coerenza con il modello Trip
    // Ricorda che 'BOOLEAN' in SQLite è rappresentato da INTEGER (0 o 1)
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

  // --- METODO PER L'UPGRADE DEL DATABASE ---
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Upgrade dalla versione 1 alla 2 (isFavorite, toRepeat)
      await db.execute(
        'ALTER TABLE trips ADD COLUMN isFavorite INTEGER DEFAULT 0;',
      );
      // CORREZIONE: Aggiungi anche la colonna 'toBeRepeated' se l'hai chiamata così nel modello
      // Esegui SOLO se non l'hai già fatto in una versione precedente
      if (oldVersion < 2) {
        // Questo if controlla solo per upgrade dalla v1 alla v2
        await db.execute(
          'ALTER TABLE trips ADD COLUMN toBeRepeated INTEGER DEFAULT 0;', // <--- CORRETTO
        );
      }
    }
    if (oldVersion < 3) {
      // Upgrade dalla versione 2 alla 3 (continent)
      await db.execute(
        'ALTER TABLE trips ADD COLUMN continent TEXT DEFAULT "Sconosciuto";',
      );
    }
  }

  // --- METODI CRUD PER TRIP ---

  Future<Trip> insertTrip(Trip trip) async {
    final db = await instance.database;
    final id = await db.insert(
      'trips',
      trip.toMap(), // <--- CORRETTO: da toJson() a toMap()
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // IMPORTANTE: recupera il viaggio appena inserito dal database per avere l'ID corretto
    // o aggiorna l'oggetto Trip esistente con l'ID
    return trip.copy(
      id: id,
    ); // Usa il metodo copy che abbiamo corretto nel modello
  }

  Future<Trip> getTripById(int id) async {
    // Rinominato per chiarezza, getTrip era troppo generico
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
        'toBeRepeated', // <--- CORRETTO
      ],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Trip.fromMap(
        maps.first,
      ); // <--- CORRETTO: da fromJson() a fromMap()
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<Trip>> getAllTrips() async {
    final db = await instance.database;
    final result = await db.query('trips', orderBy: 'endDate DESC');
    return result
        .map((json) => Trip.fromMap(json))
        .toList(); // <--- CORRETTO: da fromJson() a fromMap()
  }

  Future<int> updateTrip(Trip trip) async {
    final db = await instance.database;
    return db.update(
      'trips',
      trip.toMap(), // <--- CORRETTO: da toJson() a toMap()
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
    // È importante controllare che _database non sia già null prima di tentare di chiuderlo
    if (_database != null) {
      await db.close();
      _database =
          null; // Resetta la variabile statica dopo aver chiuso il database
    }
  }
}
