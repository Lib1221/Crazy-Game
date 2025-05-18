import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crazygame/controllers/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.put(SettingsController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.2),
              Theme.of(context).colorScheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Theme Settings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Obx(() => SwitchListTile(
                            title: const Text('Dark Mode'),
                            subtitle: const Text('Enable dark theme'),
                            value: settings.isDarkMode,
                            onChanged: (value) => settings.toggleDarkMode(),
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Sound Settings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sound & Haptics',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Obx(() => SwitchListTile(
                            title: const Text('Sound Effects'),
                            subtitle: const Text('Enable game sound effects'),
                            value: settings.isSoundEnabled,
                            onChanged: (value) => settings.toggleSound(),
                          )),
                      Obx(() => SwitchListTile(
                            title: const Text('Vibration'),
                            subtitle: const Text('Enable haptic feedback'),
                            value: settings.isVibrationEnabled,
                            onChanged: (value) => settings.toggleVibration(),
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Notification Settings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifications',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Obx(() => SwitchListTile(
                            title: const Text('Game Notifications'),
                            subtitle: const Text('Enable game notifications'),
                            value: settings.isNotificationsEnabled,
                            onChanged: (value) =>
                                settings.toggleNotifications(),
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // About Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.info),
                        title: const Text('Version'),
                        subtitle: const Text('1.0.0'),
                        onTap: () {
                          // TODO: Show version info dialog
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.description),
                        title: const Text('Terms of Service'),
                        onTap: () {
                          // TODO: Show terms of service
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.privacy_tip),
                        title: const Text('Privacy Policy'),
                        onTap: () {
                          // TODO: Show privacy policy
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
