import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;

  final FirebaseDatabase _database;

  DatabaseService._internal() : _database = FirebaseDatabase.instance;

  // Initialize database connection
  void _initializeDatabase() {
    try {
      // Only enable persistence on non-web platforms
      if (!kIsWeb) {
        _database.setPersistenceEnabled(true);
        _database.setPersistenceCacheSizeBytes(10000000); // 10MB cache
      }

      // Set connection state logging
      _database.ref('.info/connected').onValue.listen((event) {});
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing database: $e');
      }
    }
  }

  // Get database reference with error handling
  DatabaseReference getRef([String? path]) {
    return path != null ? _database.ref(path) : _database.ref();
  }

  // Get database instance
  FirebaseDatabase get database => _database;
}
