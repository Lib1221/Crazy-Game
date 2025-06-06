import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../services/realtime_chat_service.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RealtimeChatService _chatService = RealtimeChatService();

  final Rx<User?> currentUser = Rx<User?>(null);
  final Rx<Map<String, dynamic>?> userData = Rx<Map<String, dynamic>?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    currentUser.value = _auth.currentUser;
    _auth.authStateChanges().listen((User? user) {
      currentUser.value = user;
      if (user != null) {
        _loadUserData(user.uid);
        Get.offAllNamed('/chats');
      } else {
        userData.value = null;
        Get.offAllNamed('/auth');
      }
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        userData.value = doc.data();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load user data',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login time
      await _firestore
          .collection('users')
          .doc(userCredential.user?.uid)
          .update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      // Update user's online status
      await _chatService.updateUserStatus(true);
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'user-not-found':
          errorMessage.value = 'No user found for that email.';
          break;
        case 'wrong-password':
          errorMessage.value = 'Wrong password provided.';
          break;
        case 'invalid-email':
          errorMessage.value = 'The email address is not valid.';
          break;
        default:
          errorMessage.value = 'An error occurred during sign in: ${e.message}';
      }
      rethrow;
    } catch (e) {
      print('Sign In Error: $e');
      errorMessage.value = 'An unexpected error occurred: $e';
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createUserWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Create user in Firebase Auth
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user profile with name
      await userCredential.user?.updateDisplayName(name);

      // Store user data in Firestore
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      // Store user data in Realtime Database
      await _chatService.storeUserInfo(
        userId: userCredential.user!.uid,
        name: name,
        email: email,
      );

      // Update user's online status
      await _chatService.updateUserStatus(true);
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'weak-password':
          errorMessage.value = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage.value = 'An account already exists for that email.';
          break;
        case 'invalid-email':
          errorMessage.value = 'The email address is not valid.';
          break;
        default:
          errorMessage.value =
              'An error occurred during registration: ${e.message}';
      }
      rethrow;
    } catch (e) {
      print('Registration Error: $e');
      errorMessage.value = 'An unexpected error occurred: $e';
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      // Update user's online status before signing out
      if (_auth.currentUser != null) {
        await _chatService.updateUserStatus(false);
      }
      await _auth.signOut();
      userData.value = null;
      Get.offAllNamed('/auth');
    } catch (e) {
      print('Sign Out Error: $e');
      errorMessage.value = 'Error signing out: $e';
      rethrow;
    }
  }

  Future<void> updateUserProfile({
    String? name,
    String? status,
    String? photoUrl,
    String? phoneNumber,
    String? bio,
  }) async {
    try {
      if (currentUser.value != null) {
        final updates = <String, dynamic>{
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (name != null) {
          updates['name'] = name;
          await currentUser.value!.updateDisplayName(name);
        }
        if (status != null) updates['status'] = status;
        if (photoUrl != null) updates['photoUrl'] = photoUrl;
        if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
        if (bio != null) updates['bio'] = bio;

        await _firestore
            .collection('users')
            .doc(currentUser.value!.uid)
            .update(updates);
        await _loadUserData(currentUser.value!.uid);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    }
  }

  Future<void> updateUserSettings({
    bool? notifications,
    bool? darkMode,
    String? language,
  }) async {
    try {
      if (currentUser.value != null) {
        final updates = <String, dynamic>{
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (notifications != null) {
          updates['settings.notifications'] = notifications;
        }
        if (darkMode != null) {
          updates['settings.darkMode'] = darkMode;
        }
        if (language != null) {
          updates['settings.language'] = language;
        }

        await _firestore
            .collection('users')
            .doc(currentUser.value!.uid)
            .update(updates);
        await _loadUserData(currentUser.value!.uid);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    }
  }

  bool get isAuthenticated => currentUser.value != null;
}
