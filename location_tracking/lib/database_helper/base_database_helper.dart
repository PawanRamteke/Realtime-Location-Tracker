import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

abstract class BaseDatabaseHelper {
  static Database? _database;
  static const int _databaseVersion = 4;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<Database> _initDatabase() async {
    try {
      // Close any existing database connection
      await closeDatabase();

      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, getDatabaseName());
      debugPrint('Database path: $path');

      // Ensure the directory exists
      if (!await documentsDirectory.exists()) {
        await documentsDirectory.create(recursive: true);
      }

      // Open database with write access
      debugPrint('Opening database...');
      final db = await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: (db, version) async {
          debugPrint('Creating new database at version $version');
          await onCreate(db, version);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          debugPrint('Upgrading database from $oldVersion to $newVersion');
          await onUpgrade(db, oldVersion, newVersion);
        },
        onOpen: (db) async {
          debugPrint('Database opened successfully');
          await onOpen(db);
        },
      );

      debugPrint('Database initialization completed');
      return db;
    } catch (e, stackTrace) {
      debugPrint('Error initializing database: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> verifyTables(Database db) async {
    final tables = await db.query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
    debugPrint('Tables in database: ${tables.map((t) => t['name']).join(', ')}');
    
    // Verify table structures
    for (var table in tables) {
      if (table['name'] != 'android_metadata' && table['name'] != 'sqlite_sequence') {
        final tableInfo = await db.rawQuery('PRAGMA table_info(${table['name']})');
        debugPrint('Table ${table['name']} structure: $tableInfo');
      }
    }
  }

  // Abstract methods to be implemented by subclasses
  String getDatabaseName();
  Future<void> onCreate(Database db, int version);
  Future<void> onUpgrade(Database db, int oldVersion, int newVersion);
  Future<void> onOpen(Database db);
} 