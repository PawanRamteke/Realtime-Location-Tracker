import 'package:location_tracking/database_helper/store_locations_database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import 'base_database_helper.dart';

class DatabaseHelper extends BaseDatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  final StoreLocationsDatabaseHelper _storeLocationsHelper;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal() : _storeLocationsHelper = StoreLocationsDatabaseHelper() {
    // Share the database instance with StoreLocationsHelper
    _storeLocationsHelper.setParentHelper(this);
  }

  // Public getter for store locations helper
  StoreLocationsDatabaseHelper get storeLocationsHelper => _storeLocationsHelper;

  @override
  String getDatabaseName() => 'location_tracking.db';

  @override
  Future<void> onCreate(Database db, int version) async {
    debugPrint('Creating database tables...');
    try {
      await createTables(db);
      debugPrint('Successfully created all tables');
    } catch (e, stackTrace) {
      debugPrint('Error creating tables: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading database from $oldVersion to $newVersion');
    
    if (oldVersion < 2) {
      await _storeLocationsHelper.createTables(db);
    }
    
    if (oldVersion < 3) {
      // Check if the table exists before trying to alter it
      final tables = await db.query(
        'sqlite_master',
        where: 'type = ? AND name = ?',
        whereArgs: ['table', 'tracking_sessions'],
      );
      
      if (tables.isNotEmpty) {
        // Table exists, add the new column
        await db.execute('ALTER TABLE tracking_sessions ADD COLUMN is_active INTEGER DEFAULT 0');
      } else {
        // Table doesn't exist, create it with all columns
        await createTables(db);
      }
    }
  }

  @override
  Future<void> onOpen(Database db) async {
    await _verifyTables(db);
  }

  Future<void> _verifyTables(Database db) async {
    try {
      final tables = await db.query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
      debugPrint('Tables in database: ${tables.map((t) => t['name']).join(', ')}');
      
      bool hasTrackingSessions = false;
      bool hasLocationHistory = false;
      bool hasStoreLocations = false;
      bool hasStoreVisits = false;
      
      // Verify table structures
      for (var table in tables) {
        if (table['name'] == 'tracking_sessions') hasTrackingSessions = true;
        if (table['name'] == 'location_history') hasLocationHistory = true;
        if (table['name'] == 'store_locations') hasStoreLocations = true;
        if (table['name'] == 'store_visits') hasStoreVisits = true;
        
        if (table['name'] != 'android_metadata' && table['name'] != 'sqlite_sequence') {
          final tableInfo = await db.rawQuery('PRAGMA table_info(${table['name']})');
          debugPrint('Table ${table['name']} structure: $tableInfo');
        }
      }

      // Create missing tables if necessary
      if (!hasTrackingSessions || !hasLocationHistory) {
        debugPrint('Missing tracking tables, creating them now...');
        await createTables(db);
      }

      if (!hasStoreLocations || !hasStoreVisits) {
        debugPrint('Missing store tables, creating them now...');
        await _storeLocationsHelper.createTables(db);
      }
    } catch (e, stackTrace) {
      debugPrint('Error verifying tables: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> createTables(Database db) async {
    try {
      // Create tracking_sessions table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS tracking_sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          start_time TEXT NOT NULL,
          end_time TEXT,
          distance REAL DEFAULT 0,
          average_speed REAL DEFAULT 0,
          is_active INTEGER DEFAULT 0
        )
      ''');
      debugPrint('Created tracking_sessions table');

      // Create location_history table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS location_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          session_id INTEGER NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          timestamp TEXT NOT NULL,
          accuracy REAL,
          altitude REAL,
          speed REAL,
          speed_accuracy REAL,
          heading REAL,
          FOREIGN KEY (session_id) REFERENCES tracking_sessions(id) ON DELETE CASCADE
        )
      ''');
      debugPrint('Created location_history table');

      // Create store-related tables
      await _storeLocationsHelper.createTables(db);
      
      // Verify the tables were created
      final tables = await db.query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
      debugPrint('Tables after creation: ${tables.map((t) => t['name']).join(', ')}');
    } catch (e, stackTrace) {
      debugPrint('Error in createTables: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<int> insertLocation(Map<String, dynamic> location) async {
    Database db = await database;
    try {
      final id = await db.insert('location_history', location);
      debugPrint('Inserted location with ID: $id for session: ${location['session_id']}');
      return id;
    } catch (e) {
      debugPrint('Error inserting location: $e');
      rethrow;
    }
  }

  Future<int> insertTrackingSession(Map<String, dynamic> session) async {
    Database db = await database;
    try {
      final id = await db.insert('tracking_sessions', session);
      debugPrint('Inserted tracking session with ID: $id');
      return id;
    } catch (e) {
      debugPrint('Error inserting tracking session: $e');
      rethrow;
    }
  }

  Future<void> updateTrackingSession(int id, Map<String, dynamic> session) async {
    Database db = await database;
    try {
      final count = await db.update(
        'tracking_sessions',
        session,
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('Updated tracking session $id, rows affected: $count');
    } catch (e) {
      debugPrint('Error updating tracking session: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getActiveSession() async {
    try {
      final Database db = await database;
      final List<Map<String, dynamic>> result = await db.query(
        'tracking_sessions',
        where: 'end_time IS NULL',
        orderBy: 'start_time DESC',
        limit: 1,
      );
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      debugPrint('Error getting active session: $e');
      return null;
    }
  }

  Future<void> markSessionAsActive(int sessionId, bool isActive) async {
    try {
      final Database db = await database;
      await db.update(
        'tracking_sessions',
        {'is_active': isActive ? 1 : 0},
        where: 'id = ?',
        whereArgs: [sessionId],
      );
    } catch (e) {
      debugPrint('Error marking session as active: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getLocationsForSession(int sessionId) async {
    Database db = await database;
    try {
      debugPrint('Fetching locations for session $sessionId');
      final locations = await db.query(
        'location_history',
        where: 'session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'timestamp ASC',
      );
      debugPrint('Found ${locations.length} locations for session $sessionId');
      return locations;
    } catch (e) {
      debugPrint('Error fetching locations: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllSessions() async {
    final db = await database;
    try {
      debugPrint('Fetching all tracking sessions');
      
      // Get all sessions with a count of their locations
      final sessions = await db.rawQuery('''
        SELECT 
          ts.*,
          (SELECT COUNT(*) FROM location_history WHERE session_id = ts.id) as location_count
        FROM tracking_sessions ts
        ORDER BY start_time DESC
      ''');
      
      debugPrint('Raw sessions query result: $sessions');
      return sessions;
    } catch (e) {
      debugPrint('Error in getAllSessions: $e');
      return [];
    }
  }

  Future<void> deleteSession(int sessionId) async {
    Database db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'tracking_sessions',
        where: 'id = ?',
        whereArgs: [sessionId],
      );
      await txn.delete(
        'location_history',
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
    });
  }

  Future<Map<String, dynamic>?> getLastLocationForSession(int sessionId) async {
    try {
      final Database db = await database;
      final List<Map<String, dynamic>> result = await db.query(
        'location_history',
        where: 'session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'timestamp DESC',
        limit: 1,
      );
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      debugPrint('Error getting last location for session: $e');
      return null;
    }
  }

  Future<void> clearAllData() async {
    Database db = await database;
    await db.transaction((txn) async {
      await txn.delete('tracking_sessions');
      await txn.delete('location_history');
    });
  }
} 