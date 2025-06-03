import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crazygame/controllers/game_controller.dart';

class GameSettings extends StatefulWidget {
  const GameSettings({Key? key}) : super(key: key);

  @override
  State<GameSettings> createState() => _GameSettingsState();
}

class _GameSettingsState extends State<GameSettings>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  final GameController _gameController = Get.find<GameController>();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Game Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Settings content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _SettingItem(
                    title: 'Sound Effects',
                    icon: Icons.volume_up,
                    child: Obx(() => Switch(
                          value: _gameController.isSoundEnabled,
                          onChanged: _gameController.toggleSound,
                        )),
                  ),
                  _SettingItem(
                    title: 'Music',
                    icon: Icons.music_note,
                    child: Obx(() => Switch(
                          value: _gameController.isMusicEnabled,
                          onChanged: _gameController.toggleMusic,
                        )),
                  ),
                  _SettingItem(
                    title: 'Vibration',
                    icon: Icons.vibration,
                    child: Obx(() => Switch(
                          value: _gameController.isVibrationEnabled,
                          onChanged: _gameController.toggleVibration,
                        )),
                  ),
                  _SettingItem(
                    title: 'Auto-Play',
                    icon: Icons.play_circle_outline,
                    child: Obx(() => Switch(
                          value: _gameController.isAutoPlayEnabled,
                          onChanged: _gameController.toggleAutoPlay,
                        )),
                  ),
                  const Divider(),
                  _SettingItem(
                    title: 'Turn Time Limit',
                    icon: Icons.timer,
                    child: Obx(() => DropdownButton<int>(
                          value: _gameController.turnTimeLimit,
                          items: [30, 60, 90, 120]
                              .map((time) => DropdownMenuItem(
                                    value: time,
                                    child: Text('$time seconds'),
                                  ))
                              .toList(),
                          onChanged: _gameController.setTurnTimeLimit,
                        )),
                  ),
                  _SettingItem(
                    title: 'Game Speed',
                    icon: Icons.speed,
                    child: Obx(() => Slider(
                          value: _gameController.gameSpeed,
                          min: 0.5,
                          max: 2.0,
                          divisions: 3,
                          label: '${_gameController.gameSpeed}x',
                          onChanged: _gameController.setGameSpeed,
                        )),
                  ),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      _gameController.resetSettings();
                      Get.snackbar(
                        'Settings Reset',
                        'All settings have been reset to default values',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                    icon: const Icon(Icons.restore),
                    label: const Text('Reset'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _gameController.saveSettings();
                      Navigator.of(context).pop();
                      Get.snackbar(
                        'Settings Saved',
                        'Your game settings have been saved',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SettingItem({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
