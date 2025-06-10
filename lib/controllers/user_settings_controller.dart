import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/error_service.dart';

class UserSettingsController extends GetxController {
  static UserSettingsController get to => Get.find();
  final ErrorService _errorService = Get.find<ErrorService>();

  // Observable settings
  final RxBool notifications = true.obs;
  final RxBool darkMode = false.obs;
  final RxString language = 'en'.obs;
  final RxBool isFirstLaunch = true.obs;

  // SharedPreferences instance
  late SharedPreferences _prefs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  // Initialize SharedPreferences and load settings
  Future<void> _loadSettings() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      // Load settings from SharedPreferences
      notifications.value = _prefs.getBool('notifications') ?? true;
      darkMode.value = _prefs.getBool('darkMode') ?? false;
      language.value = _prefs.getString('language') ?? 'en';
      isFirstLaunch.value = _prefs.getBool('isFirstLaunch') ?? true;

      // If it's first launch, set it to false for next time
      if (isFirstLaunch.value) {
        await _prefs.setBool('isFirstLaunch', false);
      }
    } catch (e) {
      _errorService.handleError('Failed to load settings');
    }
  }

  // Update notification settings
  Future<void> updateNotifications(bool value) async {
    try {
      await _prefs.setBool('notifications', value);
      notifications.value = value;
      _errorService.showSuccess('Notification settings updated');
    } catch (e) {
      _errorService.handleError('Failed to update notification settings');
    }
  }

  // Update theme mode
  Future<void> updateThemeMode(bool isDark) async {
    try {
      await _prefs.setBool('darkMode', isDark);
      darkMode.value = isDark;
      Get.changeThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
      _errorService.showSuccess('Theme updated');
    } catch (e) {
      _errorService.handleError('Failed to update theme');
    }
  }

  // Update language
  Future<void> updateLanguage(String langCode) async {
    try {
      await _prefs.setString('language', langCode);
      language.value = langCode;
      // Update app locale
      Get.updateLocale(Locale(langCode));
      _errorService.showSuccess('Language updated');
    } catch (e) {
      _errorService.handleError('Failed to update language');
    }
  }

  // Reset all settings to default
  Future<void> resetSettings() async {
    try {
      await _prefs.clear();
      await _loadSettings();
      _errorService.showSuccess('Settings reset to default');
    } catch (e) {
      _errorService.handleError('Failed to reset settings');
    }
  }
}
