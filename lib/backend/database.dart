import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class TranslationHistory {
  final int? id;
  final String originalText;
  final String translatedText;
  final String targetLanguage; // Add target language field
  final DateTime timestamp;

  TranslationHistory({
    this.id,
    required this.originalText,
    required this.translatedText,
    required this.targetLanguage,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'originalText': originalText,
      'translatedText': translatedText,
      'targetLanguage': targetLanguage,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory TranslationHistory.fromMap(Map<String, dynamic> map) {
    return TranslationHistory(
      id: map['id'],
      originalText: map['originalText'],
      translatedText: map['translatedText'],
      targetLanguage: map['targetLanguage'] ?? 'malay', // Default fallback
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }
}

class AppSettingsModel {
  final bool isFirstTime;
  final String defaultPage;
  final String translationLanguage;

  AppSettingsModel({
    required this.isFirstTime,
    required this.defaultPage,
    required this.translationLanguage,
  });

  Map<String, dynamic> toMap() {
    return {
      'isFirstTime': isFirstTime ? 1 : 0,
      'defaultPage': defaultPage,
      'translationLanguage': translationLanguage,
    };
  }

  factory AppSettingsModel.fromMap(Map<String, dynamic> map) {
    return AppSettingsModel(
      isFirstTime: map['isFirstTime'] == 1,
      defaultPage: map['defaultPage'],
      translationLanguage: map['translationLanguage'] ?? 'malay',
    );
  }
}

class SpeechHistory {
  final int? id;
  final String originalAudio; // Path to audio file or audio description
  final String transcribedText;
  final DateTime timestamp;

  SpeechHistory({
    this.id,
    required this.originalAudio,
    required this.transcribedText,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'originalAudio': originalAudio,
      'transcribedText': transcribedText,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory SpeechHistory.fromMap(Map<String, dynamic> map) {
    return SpeechHistory(
      id: map['id'],
      originalAudio: map['originalAudio'],
      transcribedText: map['transcribedText'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }
}

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

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
      version: 1, // Set version to 1, as all schema is now in initial create
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE translations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        originalText TEXT NOT NULL,
        translatedText TEXT NOT NULL,
        targetLanguage TEXT NOT NULL DEFAULT 'malay',
        timestamp INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        isFirstTime INTEGER NOT NULL DEFAULT 1,
        defaultPage TEXT NOT NULL DEFAULT 'detector',
        translationLanguage TEXT NOT NULL DEFAULT 'malay'
      )
    ''');

    await db.execute('''
      CREATE TABLE speech_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        originalAudio TEXT NOT NULL,
        transcribedText TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    // Insert default settings
    await db.insert('settings', {
      'isFirstTime': 1,
      'defaultPage': 'detector',
      'translationLanguage': 'malay',
    });
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Reserved for future schema upgrades
  }

  Future<int> insertTranslation(String originalText, String translatedText, {String? targetLanguage}) async {
    final db = await instance.database;
    
    // Get current language setting if not provided
    String language = targetLanguage ?? 'malay';
    if (targetLanguage == null) {
      try {
        final settings = await getSettings();
        language = settings.translationLanguage;
      } catch (e) {
        language = 'malay'; // fallback
      }
    }
    
    final translation = TranslationHistory(
      originalText: originalText,
      translatedText: translatedText,
      targetLanguage: language,
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

  // Speech history methods
  Future<int> insertSpeechHistory(String originalAudio, String transcribedText) async {
    final db = await instance.database;
    final speechHistory = SpeechHistory(
      originalAudio: originalAudio,
      transcribedText: transcribedText,
      timestamp: DateTime.now(),
    );

    return await db.insert('speech_history', speechHistory.toMap());
  }

  Future<List<SpeechHistory>> getAllSpeechHistory() async {
    final db = await instance.database;
    final result = await db.query(
      'speech_history',
      orderBy: 'timestamp DESC',
    );

    return result.map((map) => SpeechHistory.fromMap(map)).toList();
  }

  Future<int> deleteSpeechHistory(int id) async {
    final db = await instance.database;
    return await db.delete(
      'speech_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearAllSpeechHistory() async {
    final db = await instance.database;
    return await db.delete('speech_history');
  }

  // Settings methods
  Future<AppSettingsModel> getSettings() async {
    final db = await instance.database;
    final result = await db.query('settings', limit: 1);
    
    if (result.isNotEmpty) {
      return AppSettingsModel.fromMap(result.first);
    } else {
      // If no settings exist, create default settings
      final defaultSettings = AppSettingsModel(
        isFirstTime: true,
        defaultPage: 'detector',
        translationLanguage: 'malay',
      );
      await saveSettings(defaultSettings);
      return defaultSettings;
    }
  }

  Future<int> saveSettings(AppSettingsModel settings) async {
    final db = await instance.database;
    
    // Check if settings exist
    final result = await db.query('settings', limit: 1);
    
    if (result.isNotEmpty) {
      // Update existing settings - no WHERE clause needed since there's only one record
      return await db.update('settings', settings.toMap());
    } else {
      // Insert new settings
      return await db.insert('settings', settings.toMap());
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
