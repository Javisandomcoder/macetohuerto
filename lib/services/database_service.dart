import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/plant.dart';
import '../models/care_log.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = join(appDir.path, 'macetohuerto.db');

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Plants table
    await db.execute('''
      CREATE TABLE plants (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        species TEXT,
        location TEXT,
        planted_at TEXT,
        notes TEXT,
        reminder_enabled INTEGER NOT NULL DEFAULT 0,
        watering_interval_days INTEGER,
        watering_time TEXT,
        reminder_paused INTEGER NOT NULL DEFAULT 0,
        last_watered_at TEXT,
        tags TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Plant images table
    await db.execute('''
      CREATE TABLE plant_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plant_id TEXT NOT NULL,
        image_path TEXT NOT NULL,
        caption TEXT,
        taken_at TEXT NOT NULL,
        FOREIGN KEY (plant_id) REFERENCES plants (id) ON DELETE CASCADE
      )
    ''');

    // Care logs table (historial de cuidados)
    await db.execute('''
      CREATE TABLE care_logs (
        id TEXT PRIMARY KEY,
        plant_id TEXT NOT NULL,
        care_type TEXT NOT NULL,
        notes TEXT,
        performed_at TEXT NOT NULL,
        FOREIGN KEY (plant_id) REFERENCES plants (id) ON DELETE CASCADE
      )
    ''');

    // Indexes for better performance
    await db.execute('CREATE INDEX idx_plant_images_plant_id ON plant_images(plant_id)');
    await db.execute('CREATE INDEX idx_care_logs_plant_id ON care_logs(plant_id)');
    await db.execute('CREATE INDEX idx_care_logs_performed_at ON care_logs(performed_at)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future schema migrations
  }

  // Plant operations
  Future<List<Plant>> getAllPlants() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'plants',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return maps.map((map) => Plant.fromDb(map)).toList();
  }

  Future<Plant?> getPlant(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'plants',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Plant.fromDb(maps.first);
  }

  Future<void> insertPlant(Plant plant) async {
    final db = await database;
    await db.insert(
      'plants',
      plant.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updatePlant(Plant plant) async {
    final db = await database;
    await db.update(
      'plants',
      plant.toDb(),
      where: 'id = ?',
      whereArgs: [plant.id],
    );
  }

  Future<void> deletePlant(String id) async {
    final db = await database;
    await db.delete(
      'plants',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Plant images operations
  Future<List<PlantImage>> getPlantImages(String plantId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'plant_images',
      where: 'plant_id = ?',
      whereArgs: [plantId],
      orderBy: 'taken_at DESC',
    );
    return maps.map((map) => PlantImage.fromDb(map)).toList();
  }

  Future<int> insertPlantImage(PlantImage image) async {
    final db = await database;
    return await db.insert('plant_images', image.toDb());
  }

  Future<void> deletePlantImage(int id) async {
    final db = await database;
    await db.delete(
      'plant_images',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Care logs operations
  Future<List<CareLog>> getCareLogs(String plantId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'care_logs',
      where: 'plant_id = ?',
      whereArgs: [plantId],
      orderBy: 'performed_at DESC',
    );
    return maps.map((map) => CareLog.fromDb(map)).toList();
  }

  Future<List<CareLog>> getAllCareLogs({int limit = 50}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'care_logs',
      orderBy: 'performed_at DESC',
      limit: limit,
    );
    return maps.map((map) => CareLog.fromDb(map)).toList();
  }

  Future<void> insertCareLog(CareLog log) async {
    final db = await database;
    await db.insert(
      'care_logs',
      log.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteCareLog(String id) async {
    final db = await database;
    await db.delete(
      'care_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Migration from SharedPreferences
  Future<void> migrateFromSharedPreferences(List<Plant> plants) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final plant in plants) {
        await txn.insert(
          'plants',
          plant.toDb(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final db = await database;

    final totalPlants = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM plants'),
    ) ?? 0;

    final totalCareLogs = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM care_logs'),
    ) ?? 0;

    final recentCareLogs = await db.rawQuery('''
      SELECT care_type, COUNT(*) as count
      FROM care_logs
      WHERE performed_at >= date('now', '-30 days')
      GROUP BY care_type
    ''');

    return {
      'totalPlants': totalPlants,
      'totalCareLogs': totalCareLogs,
      'recentCareByType': Map.fromEntries(
        recentCareLogs.map((row) => MapEntry(
          row['care_type'] as String,
          row['count'] as int,
        )),
      ),
    };
  }

  // Export/Import
  Future<Map<String, dynamic>> exportData() async {
    final db = await database;

    final plants = await db.query('plants');
    final images = await db.query('plant_images');
    final careLogs = await db.query('care_logs');

    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'plants': plants,
      'plant_images': images,
      'care_logs': careLogs,
    };
  }

  Future<void> importData(Map<String, dynamic> data) async {
    final db = await database;

    await db.transaction((txn) async {
      // Clear existing data
      await txn.delete('care_logs');
      await txn.delete('plant_images');
      await txn.delete('plants');

      // Import plants
      if (data['plants'] != null) {
        for (final plant in data['plants'] as List) {
          await txn.insert('plants', plant as Map<String, dynamic>);
        }
      }

      // Import images
      if (data['plant_images'] != null) {
        for (final image in data['plant_images'] as List) {
          await txn.insert('plant_images', image as Map<String, dynamic>);
        }
      }

      // Import care logs
      if (data['care_logs'] != null) {
        for (final log in data['care_logs'] as List) {
          await txn.insert('care_logs', log as Map<String, dynamic>);
        }
      }
    });
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
