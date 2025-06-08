import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;

  final FirebaseDatabase _database;

  DatabaseService._internal() : _database = FirebaseDatabase.instance;

  // Initialize database connection

  // Get database reference with error handling
  DatabaseReference getRef([String? path]) {
    return path != null ? _database.ref(path) : _database.ref();
  }

  // Get database instance
  FirebaseDatabase get database => _database;
}
