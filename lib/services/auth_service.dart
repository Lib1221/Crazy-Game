import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:crazygame/routes/app_pages.dart';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable user state
  final Rx<User?> user = Rx<User?>(null);

  // Initialize the service
  Future<AuthService> init() async {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      this.user.value = user;
      if (user == null) {
        Get.offAllNamed(Routes.LOGIN);
      } else {
        Get.offAllNamed(Routes.HOME);
      }
    });
    return this;
  }

  // Check if email exists
  Future<bool> isEmailExists(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
    String name,
    String email,
    String password,
  ) async {
    try {
      // Check if email already exists
      if (await isEmailExists(email)) {
        throw 'Email already exists';
      }

      // Create user
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Login with email and password
  Future<UserCredential> loginWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login timestamp
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user
  User? get currentUser => _auth.currentUser;
}
