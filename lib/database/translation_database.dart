import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class TranslationHistory {
  final int? id;
  final String originalText;
  final String translatedText;
  final DateTime timestamp;

  TranslationHistory({
    this.id,
    required this.originalText,
    required this.translatedText,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'originalText': originalText,
      'translatedText': translatedText,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory TranslationHistory.fromMap(Map<String, dynamic> map) {
    return TranslationHistory(
      id: map['id'],
      originalText: map['originalText'],
      translatedText: map['translatedText'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }
}

class TranslationDatabase {
  static final TranslationDatabase instance = TranslationDatabase._init();
  static Database? _database;

  TranslationDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('translations.db');
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

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE translations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        originalText TEXT NOT NULL,
        translatedText TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insertTranslation(String originalText, String translatedText) async {
    final db = await instance.database;
    final translation = TranslationHistory(
      originalText: originalText,
      translatedText: translatedText,
      timestamp: DateTime.now(),
    );

    return await db.insert('translations', translation.toMap());
  }

  Future<List<TranslationHistory>> getAllTranslations() async {
    final db = await instance.database;
    final result = await db.query(
      'translations',
      orderBy: 'timestamp DESC',
    );

    return result.map((map) => TranslationHistory.fromMap(map)).toList();
  }

  Future<int> deleteTranslation(int id) async {
    final db = await instance.database;
    return await db.delete(
      'translations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearAllTranslations() async {
    final db = await instance.database;
    return await db.delete('translations');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
