import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import 'base_database_helper.dart';

class StoreLocationsDatabaseHelper {
  static final StoreLocationsDatabaseHelper _instance = StoreLocationsDatabaseHelper._internal();
  BaseDatabaseHelper? _parentHelper;

  factory StoreLocationsDatabaseHelper() => _instance;

  StoreLocationsDatabaseHelper._internal();

  void setParentHelper(BaseDatabaseHelper helper) {
    _parentHelper = helper;
  }

  Future<Database> get database async {
    if (_parentHelper == null) {
      throw Exception('StoreLocationsDatabaseHelper not properly initialized');
    }
    return await _parentHelper!.database;
  }

  String getDatabaseName() => 'store_locations.db';

  Future<void> onCreate(Database db, int version) async {
    debugPrint('Creating store database tables...');
    try {
      await createTables(db);
      debugPrint('Successfully created store tables');
    } catch (e, stackTrace) {
      debugPrint('Error creating store tables: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading store database from $oldVersion to $newVersion');
    // No upgrades needed yet
  }

  Future<void> onOpen(Database db) async {
    debugPrint('Store database opened');
  }

  Future<void> createTables(Database db) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS store_locations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          radius REAL NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
      debugPrint('Created store_locations table');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS store_visits (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          store_id INTEGER NOT NULL,
          entry_time TEXT NOT NULL,
          exit_time TEXT,
          FOREIGN KEY (store_id) REFERENCES store_locations(id) ON DELETE CASCADE
        )
      ''');
      debugPrint('Created store_visits table');
    } catch (e, stackTrace) {
      debugPrint('Error creating store tables: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<int> insertStoreLocation(Map<String, dynamic> location) async {
    try {
      final Database db = await database;
      final id = await db.insert('store_locations', location);
      debugPrint('Inserted store location with ID: $id');
      return id;
    } catch (e) {
      debugPrint('Error inserting store location: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllStoreLocations() async {
    try {
      final Database db = await database;
      return await db.query('store_locations', orderBy: 'created_at DESC');
    } catch (e) {
      debugPrint('Error getting store locations: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getStoreLocation(int id) async {
    try {
      final Database db = await database;
      List<Map<String, dynamic>> results = await db.query(
        'store_locations',
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('Retrieved store location with ID $id: ${results.isNotEmpty}');
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      debugPrint('Error getting store location: $e');
      return null;
    }
  }

  Future<int> updateStoreLocation(int id, Map<String, dynamic> location) async {
    try {
      final Database db = await database;
      final count = await db.update(
        'store_locations',
        location,
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('Updated store location with ID $id: $count rows affected');
      return count;
    } catch (e) {
      debugPrint('Error updating store location: $e');
      rethrow;
    }
  }

  Future<int> deleteStoreLocation(int id) async {
    try {
      final Database db = await database;
      final count = await db.delete(
        'store_locations',
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('Deleted store location with ID $id: $count rows affected');
      return count;
    } catch (e) {
      debugPrint('Error deleting store location: $e');
      rethrow;
    }
  }

  Future<int> insertStoreVisit(Map<String, dynamic> visit) async {
    try {
      final Database db = await database;
      final id = await db.insert('store_visits', visit);
      debugPrint('Inserted store visit with ID: $id');
      return id;
    } catch (e) {
      debugPrint('Error inserting store visit: $e');
      rethrow;
    }
  }

  Future<int> updateStoreVisit(int id, Map<String, dynamic> visit) async {
    try {
      final Database db = await database;
      final count = await db.update(
        'store_visits',
        visit,
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('Updated store visit with ID $id: $count rows affected');
      return count;
    } catch (e) {
      debugPrint('Error updating store visit: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getStoreVisits(int storeId) async {
    try {
      final Database db = await database;
      return await db.query(
        'store_visits',
        where: 'store_id = ?',
        whereArgs: [storeId],
        orderBy: 'entry_time DESC',
      );
    } catch (e) {
      debugPrint('Error getting store visits: $e');
      return [];
    }
  }
} 