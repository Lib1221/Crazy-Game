import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crazygame/controllers/game_controller.dart';

class GameNotifications extends StatelessWidget {
  final GameController controller = Get.find<GameController>();

  GameNotifications({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.error == null) return const SizedBox.shrink();

      return Positioned(
        top: 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    controller.error!,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  color: Colors.red.shade700,
                  onPressed: () => controller.clearError(),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class GameToast extends StatelessWidget {
  final String message;
  final Color color;
  final Duration duration;

  const GameToast({
    Key? key,
    required this.message,
    this.color = Colors.green,
    this.duration = const Duration(seconds: 3),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  static void show(
    BuildContext context, {
    required String message,
    Color color = Colors.green,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: GameToast(
          message: message,
          color: color,
          duration: duration,
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(duration, () => overlayEntry.remove());
  }
}
