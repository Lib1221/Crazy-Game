import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crazygame/models/game_event.dart';
import 'package:crazygame/controllers/game_controller.dart';
import 'package:crazygame/theme/app_colors.dart';

class GameHistory extends StatelessWidget {
  final GameController gameController = Get.find<GameController>();

  GameHistory({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Game History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => gameController.clearHistory(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              final events = gameController.gameHistory;
              if (events.isEmpty) {
                return const Center(
                  child: Text(
                    'No events yet',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return _buildEventItem(event);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(GameEvent event) {
    IconData icon;
    Color color;

    switch (event.type) {
      case GameEventType.cardPlayed:
        icon = Icons.casino;
        color = AppColors.primary;
        break;
      case GameEventType.scoreChanged:
        icon = Icons.score;
        color = AppColors.secondary;
        break;
      case GameEventType.playerJoined:
        icon = Icons.person_add;
        color = Colors.green;
        break;
      case GameEventType.playerLeft:
        icon = Icons.person_remove;
        color = Colors.red;
        break;
      case GameEventType.gameStarted:
        icon = Icons.play_arrow;
        color = Colors.blue;
        break;
      case GameEventType.gameEnded:
        icon = Icons.flag;
        color = Colors.orange;
        break;
      case GameEventType.turnStarted:
        icon = Icons.timer;
        color = AppColors.accent;
        break;
      case GameEventType.turnEnded:
        icon = Icons.timer_off;
        color = Colors.grey;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(event.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}
