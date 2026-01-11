import 'package:location_updater/models/location_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;
  DBHelper._init();

  // initalizing the database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  //creating database
  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
    CREATE TABLE $sqlTableLocations(
      ${LocationFields.id} $idType,
      ${LocationFields.latitude} $realType
      ${LocationFields.longitude} $realType
      ${LocationFields.timestamp} $textType
    )

   ''');
  }

  // getting the database if null initialize a database

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('locations.db');
    return _database!;
  }

  // Location

  Future<LocationModel> create(LocationModel location) async {
    final db = await instance.database;
    final id = await db.insert(sqlTableLocations, location.toJson());
    return location.copy(id: id);
  }

  Future<LocationModel?> readLocation(int id) async {
    final db = await instance.database;

    final maps = await db.query(
      sqlTableLocations,
      columns: LocationFields.values,
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return LocationModel.fromJson(maps.first);
    } else {
      return null;
    }
  }

  Future<List<LocationModel>> readAllLocations() async {
    final db = await instance.database;
    const orderBy = '${LocationFields.timestamp} DESC';

    final result = await db.query(sqlTableLocations, orderBy: orderBy);
    return result.map((json) => LocationModel.fromJson(json)).toList();
  }

  Future<int> getLocationCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $sqlTableLocations');
    int? count = Sqflite.firstIntValue(result);
    return count ?? 0;
  }

  Future<int> update(LocationModel location) async {
    final db = await instance.database;
    return db.update(
      sqlTableLocations,
      location.toJson(),
      where: '${LocationFields.id} =?',
      whereArgs: [location.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;

    return await db.delete(
      sqlTableLocations,
      where: '${LocationFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAll() async {
    final db = await instance.database;
    return await db.delete(sqlTableLocations);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
