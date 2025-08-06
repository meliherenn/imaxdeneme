import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/channel_model_for_db.dart';
import '../models/history_item_model.dart'; // <-- EKSİK OLAN IMPORT SATIRI EKLENDİ

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'favorites_v2.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE favorites(
        id INTEGER PRIMARY KEY,
        streamId INTEGER UNIQUE,
        name TEXT,
        streamIcon TEXT,
        mediaType TEXT,
        categoryId TEXT,
        containerExtension TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE history(
        id INTEGER PRIMARY KEY,
        streamId INTEGER UNIQUE,
        name TEXT,
        streamIcon TEXT,
        mediaType TEXT,
        lastPosition REAL,
        totalDuration REAL,
        lastWatched TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
      CREATE TABLE history(
        id INTEGER PRIMARY KEY,
        streamId INTEGER UNIQUE,
        name TEXT,
        streamIcon TEXT,
        mediaType TEXT,
        lastPosition REAL,
        totalDuration REAL,
        lastWatched TEXT
      )
    ''');
    }
  }

  // --- FAVORİ FONKSİYONLARI (İÇLERİ DOLDURULDU) ---
  Future<void> addFavorite(ChannelForDB channel) async {
    final db = await database;
    await db.insert(
      'favorites',
      channel.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeFavorite(int streamId) async {
    final db = await database;
    await db.delete(
      'favorites',
      where: 'streamId = ?',
      whereArgs: [streamId],
    );
  }

  Future<bool> isFavorite(int streamId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'favorites',
      where: 'streamId = ?',
      whereArgs: [streamId],
    );
    return maps.isNotEmpty;
  }

  Future<List<ChannelForDB>> getAllFavorites() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('favorites');
    return List.generate(maps.length, (i) {
      return ChannelForDB.fromMap(maps[i]);
    });
  }

  // --- İZLEME GEÇMİŞİ FONKSİYONLARI ---
  Future<void> updateHistory(HistoryItem item) async {
    final db = await database;
    await db.insert(
      'history',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<HistoryItem>> getHistory() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'history',
      orderBy: 'lastWatched DESC',
    );
    return List.generate(maps.length, (i) {
      return HistoryItem.fromMap(maps[i]);
    });
  }
}