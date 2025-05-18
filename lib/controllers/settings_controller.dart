import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends GetxController {
  static SettingsController get to => Get.find();

  final _isDarkMode = false.obs;
  final _isSoundEnabled = true.obs;
  final _isVibrationEnabled = true.obs;
  final _isNotificationsEnabled = true.obs;

  bool get isDarkMode => _isDarkMode.value;
  bool get isSoundEnabled => _isSoundEnabled.value;
  bool get isVibrationEnabled => _isVibrationEnabled.value;
  bool get isNotificationsEnabled => _isNotificationsEnabled.value;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode.value = prefs.getBool('isDarkMode') ?? false;
    _isSoundEnabled.value = prefs.getBool('isSoundEnabled') ?? true;
    _isVibrationEnabled.value = prefs.getBool('isVibrationEnabled') ?? true;
    _isNotificationsEnabled.value =
        prefs.getBool('isNotificationsEnabled') ?? true;
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode.value = !_isDarkMode.value;
    await _saveSettings();
    Get.changeThemeMode(_isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> toggleSound() async {
    _isSoundEnabled.value = !_isSoundEnabled.value;
    await _saveSettings();
  }

  Future<void> toggleVibration() async {
    _isVibrationEnabled.value = !_isVibrationEnabled.value;
    await _saveSettings();
  }

  Future<void> toggleNotifications() async {
    _isNotificationsEnabled.value = !_isNotificationsEnabled.value;
    await _saveSettings();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode.value);
    await prefs.setBool('isSoundEnabled', _isSoundEnabled.value);
    await prefs.setBool('isVibrationEnabled', _isVibrationEnabled.value);
    await prefs.setBool(
        'isNotificationsEnabled', _isNotificationsEnabled.value);
  }
}
