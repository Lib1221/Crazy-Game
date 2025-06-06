import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../services/realtime_chat_service.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RealtimeChatService _chatService = RealtimeChatService();

  final Rx<User?> _user = Rx<User?>(null);
  User? get user => _user.value;

  final Rx<Map<String, dynamic>?> userData = Rx<Map<String, dynamic>?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _user.bindStream(_chatService.authStateChanges);
    ever(_user, _handleAuthChanged);
  }

  @override
  void onClose() {
    _user.close();
    super.onClose();
  }

  void _handleAuthChanged(User? user) {
    if (user != null) {
      _loadUserData(user.uid);
      Get.offAllNamed('/chats');
    } else {
      Get.offAllNamed('/auth');
    }
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

  Future<void> signIn(String email, String password) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      await _chatService.signIn(email, password);
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred. Please try again.';
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Check network connectivity first
      try {
        await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'network-request-failed') {
          throw Exception(
              'Please check your internet connection and try again.');
        }
        rethrow;
      }

      // If signup successful, update profile and store user data
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(name);
        await _chatService.storeUserInfo(
          userId: user.uid,
          name: name,
          email: email,
        );
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        errorMessage.value = 'No user found with this email.';
        break;
      case 'wrong-password':
        errorMessage.value = 'Wrong password provided.';
        break;
      case 'email-already-in-use':
        errorMessage.value = 'An account already exists with this email.';
        break;
      case 'invalid-email':
        errorMessage.value = 'Please enter a valid email address.';
        break;
      case 'weak-password':
        errorMessage.value =
            'Password is too weak. Please use a stronger password.';
        break;
      case 'network-request-failed':
        errorMessage.value =
            'Please check your internet connection and try again.';
        break;
      default:
        errorMessage.value = 'An error occurred. Please try again.';
    }
    Get.snackbar(
      'Error',
      errorMessage.value,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> signOut() async {
    try {
      await _chatService.logout();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to sign out',
        snackPosition: SnackPosition.BOTTOM,
      );
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
      if (user != null) {
        final updates = <String, dynamic>{
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (name != null) {
          updates['name'] = name;
          await user!.updateDisplayName(name);
        }
        if (status != null) updates['status'] = status;
        if (photoUrl != null) updates['photoUrl'] = photoUrl;
        if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
        if (bio != null) updates['bio'] = bio;

        await _firestore.collection('users').doc(user!.uid).update(updates);
        await _loadUserData(user!.uid);
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
      if (user != null) {
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

        await _firestore.collection('users').doc(user!.uid).update(updates);
        await _loadUserData(user!.uid);
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

  bool get isAuthenticated => user != null;
}
