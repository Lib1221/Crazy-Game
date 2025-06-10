import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ErrorService extends GetxService {
  static ErrorService get to => Get.find();

  // Observable for storing the current error message
  final RxString currentError = ''.obs;

  // Initialize the service
  Future<ErrorService> init() async {
    return this;
  }

  // Clear the current error
  void clearError() {
    currentError.value = '';
  }

  // Handle Firebase Auth errors
  void handleAuthError(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = 'No user found with this email.';
        break;
      case 'wrong-password':
        message = 'Wrong password provided.';
        break;
      case 'email-already-in-use':
        message = 'An account already exists with this email.';
        break;
      case 'invalid-email':
        message = 'Please enter a valid email address.';
        break;
      case 'weak-password':
        message = 'Password is too weak. Please use a stronger password.';
        break;
      case 'network-request-failed':
        message = 'Please check your internet connection and try again.';
        break;
      case 'too-many-requests':
        message = 'Too many attempts. Please try again later.';
        break;
      case 'user-disabled':
        message = 'This account has been disabled. Please contact support.';
        break;
      case 'operation-not-allowed':
        message = 'This operation is not allowed. Please contact support.';
        break;
      default:
        message = 'An unexpected error occurred. Please try again.';
    }
    _showError(message);
  }

  // Handle general errors
  void handleError(dynamic error) {
    String message;
    if (error is String) {
      message = error;
    } else if (error is FirebaseAuthException) {
      handleAuthError(error);
      return;
    } else {
      message = 'An unexpected error occurred. Please try again.';
    }
    _showError(message);
  }

  // Show error in snackbar and update current error
  void _showError(String message) {
    currentError.value = message;
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade900,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(8),
      borderRadius: 8,
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutBack,
    );
  }

  // Show success message
  void showSuccess(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade900,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(8),
      borderRadius: 8,
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutBack,
    );
  }
}
