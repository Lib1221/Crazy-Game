import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  final FirebaseDatabase _database;

  DatabaseService()
      : _database = FirebaseDatabase.instanceFor(
          app: FirebaseDatabase.instance.app,
          databaseURL: 'https://crazy-game-3c761-default-rtdb.firebaseio.com/',
        ) {
    _initializeDatabase();
  }

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
  DatabaseReference getRef([String path = '']) {
    try {
      return path.isEmpty ? _database.ref() : _database.ref(path);
    } catch (e) {
      rethrow;
    }
  }

  // Get database instance
  FirebaseDatabase get database => _database;
}
