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
}
