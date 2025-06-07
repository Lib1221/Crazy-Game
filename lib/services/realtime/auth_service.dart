import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _databaseService;

  AuthService(this._databaseService);

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Add authStateChanges getter
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<void> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user's online status
      if (userCredential.user != null) {
        await updateUserStatus(true);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Sign up with email and password
  Future<void> signUp(String email, String password, String name) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user profile with name
      await userCredential.user?.updateDisplayName(name);

      // Store user info in database
      if (userCredential.user != null) {
        await storeUserInfo(
          userId: userCredential.user!.uid,
          name: name,
          email: email,
        );
        await updateUserStatus(true);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Store user information
  Future<void> storeUserInfo({
    required String userId,
    required String name,
    required String email,
  }) async {
    try {
      final userData = {
        'name': name,
        'email': email.toLowerCase(),
        'createdAt': ServerValue.timestamp,
        'lastLogin': ServerValue.timestamp,
        'isOnline': true,
      };

      await _databaseService.getRef('users/$userId').set(userData);
    } catch (e) {
      rethrow;
    }
  }

  // Update user's online status
  Future<void> updateUserStatus(bool isOnline) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _databaseService.getRef('users/$userId').update({
      'isOnline': isOnline,
      'lastLogin': ServerValue.timestamp,
    });
  }

  // Logout user
  Future<void> logout() async {
    try {
      // Update user's online status to false
      final userId = currentUserId;
      if (userId != null) {
        await _databaseService.getRef('users/$userId').update({
          'isOnline': false,
          'lastLogin': ServerValue.timestamp,
        });
      }

      // Sign out from Firebase Auth
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }
}
