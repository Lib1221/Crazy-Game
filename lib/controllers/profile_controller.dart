import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/error_service.dart';

class ProfileController extends GetxController {
  static ProfileController get to => Get.find();
  final ErrorService _errorService = Get.find<ErrorService>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable profile data
  final Rx<Map<String, dynamic>?> profile = Rx<Map<String, dynamic>?>(null);
  final RxBool isLoading = false.obs;

  // Get current user
  User? get currentUser => FirebaseAuth.instance.currentUser;

  @override
  void onInit() {
    super.onInit();
    if (currentUser != null) {
      loadProfile();
    }
  }

  // Load user profile from Firestore
  Future<void> loadProfile() async {
    if (currentUser == null) return;

    try {
      isLoading.value = true;
      final doc =
          await _firestore.collection('users').doc(currentUser!.uid).get();
      if (doc.exists) {
        profile.value = doc.data();
      }
    } catch (e) {
      _errorService.handleError('Failed to load profile');
    } finally {
      isLoading.value = false;
    }
  }

  // Update user profile
  Future<void> updateProfile({
    String? name,
    String? status,
    String? photoUrl,
    String? phoneNumber,
    String? bio,
  }) async {
    if (currentUser == null) return;

    try {
      isLoading.value = true;
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) {
        updates['name'] = name;
        await currentUser!.updateDisplayName(name);
      }
      if (status != null) updates['status'] = status;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (bio != null) updates['bio'] = bio;

      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .update(updates);
      await loadProfile();
      _errorService.showSuccess('Profile updated successfully');
    } catch (e) {
      _errorService.handleError('Failed to update profile');
    } finally {
      isLoading.value = false;
    }
  }

  // Update profile picture
  Future<void> updateProfilePicture(String photoUrl) async {
    if (currentUser == null) return;

    try {
      isLoading.value = true;
      await currentUser!.updatePhotoURL(photoUrl);
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await loadProfile();
      _errorService.showSuccess('Profile picture updated');
    } catch (e) {
      _errorService.handleError('Failed to update profile picture');
    } finally {
      isLoading.value = false;
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    if (currentUser == null) return;

    try {
      isLoading.value = true;
      // Delete user data from Firestore
      await _firestore.collection('users').doc(currentUser!.uid).delete();
      // Delete user account
      await currentUser!.delete();
      _errorService.showSuccess('Account deleted successfully');
    } catch (e) {
      _errorService.handleError('Failed to delete account');
    } finally {
      isLoading.value = false;
    }
  }
}
