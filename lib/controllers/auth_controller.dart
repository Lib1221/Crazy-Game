import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:crazygame/services/auth_service.dart';
import 'package:crazygame/routes/app_pages.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  // Form controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Loading states
  final isLoading = false.obs;
  final isEmailChecking = false.obs;
  final isEmailAvailable = true.obs;

  // Error messages
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Listen to email changes for real-time validation
    emailController.addListener(_checkEmailAvailability);

    // Check initial auth state
    if (_authService.currentUser != null) {
      Get.offAllNamed(Routes.HOME);
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  // Check email availability in real-time
  Future<void> _checkEmailAvailability() async {
    final email = emailController.text.trim();
    if (email.isEmpty || !GetUtils.isEmail(email)) {
      isEmailAvailable.value = true;
      return;
    }

    isEmailChecking.value = true;
    try {
      final exists = await _authService.isEmailExists(email);
      isEmailAvailable.value = !exists;
    } catch (e) {
      isEmailAvailable.value = true;
    } finally {
      isEmailChecking.value = false;
    }
  }

  // Register new user
  Future<void> register() async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final name = nameController.text.trim();
      final email = emailController.text.trim();
      final password = passwordController.text;
      final confirmPassword = confirmPasswordController.text;

      // Validate inputs
      if (name.isEmpty) throw 'Please enter your name';
      if (email.isEmpty) throw 'Please enter your email';
      if (!GetUtils.isEmail(email)) throw 'Please enter a valid email';
      if (password.isEmpty) throw 'Please enter your password';
      if (password.length < 6) throw 'Password must be at least 6 characters';
      if (password != confirmPassword) throw 'Passwords do not match';
      if (!isEmailAvailable.value) throw 'Email is already registered';

      // Register user
      await _authService.registerWithEmailAndPassword(name, email, password);

      // Clear form
      nameController.clear();
      emailController.clear();
      passwordController.clear();
      confirmPasswordController.clear();
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // Login user
  Future<void> login() async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final email = emailController.text.trim();
      final password = passwordController.text;

      // Validate inputs
      if (email.isEmpty) throw 'Please enter your email';
      if (!GetUtils.isEmail(email)) throw 'Please enter a valid email';
      if (password.isEmpty) throw 'Please enter your password';

      // Login user
      await _authService.loginWithEmailAndPassword(email, password);

      // Clear form
      emailController.clear();
      passwordController.clear();
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }
}
