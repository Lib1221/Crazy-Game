import 'package:flutter/material.dart' hide Card;
import 'package:get/get.dart';
import 'package:crazygame/controllers/game_controller.dart';
import 'package:crazygame/screens/game/components/player_list.dart';
import 'package:crazygame/screens/game/components/discard_pile.dart';
import 'package:crazygame/screens/game/components/player_hand.dart';
import 'package:crazygame/screens/game/components/chat_area.dart';
import 'package:crazygame/widgets/connection_status.dart';
import 'package:crazygame/widgets/game_notifications.dart';
import 'package:crazygame/models/game_state.dart';

class GameRoomScreen extends StatelessWidget {
  final GameController controller = Get.find<GameController>();

  GameRoomScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Room'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.toNamed('/settings'),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main game content
          Column(
            children: [
              // Connection status at the top
              Padding(
                padding: const EdgeInsets.all(16),
                child: ConnectionStatus(),
              ),

              // Game content
              Expanded(
                child: Obx(() {
                  if (controller.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final gameState = controller.gameState;
                  if (gameState == null) {
                    return const Center(
                      child: Text('Waiting for game to start...'),
                    );
                  }

                  return _buildGameContent(gameState);
                }),
              ),
            ],
          ),

          // Notifications overlay
          GameNotifications(),
        ],
      ),
    );
  }

  Widget _buildGameContent(GameState gameState) {
    return Column(
      children: [
        // Game status and timer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(Get.context!).primaryColor.withOpacity(0.1),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Game Status: ${gameState.gameStatus}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (gameState.turnTimeRemaining > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${gameState.turnTimeRemaining}s',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Players
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: gameState.players.length,
            itemBuilder: (context, index) {
              final player = gameState.players[index];
              final isCurrentPlayer = player.id == gameState.currentPlayerId;

              return Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(8),
                child: ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(player.avatarUrl),
                        radius: 24,
                      ),
                      if (isCurrentPlayer)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          player.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Score: ${player.score}',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    'Cards: ${player.hand.length}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Game controls
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _GameButton(
                icon: Icons.add_circle_outline,
                label: 'Draw Card',
                onPressed: controller.drawCard,
                color: Colors.blue,
              ),
              _GameButton(
                icon: Icons.undo,
                label: 'Undo',
                onPressed: controller.undoPlayCard,
                color: Colors.orange,
              ),
              _GameButton(
                icon: controller.isVoiceChatEnabled ? Icons.mic : Icons.mic_off,
                label: controller.isVoiceChatEnabled ? 'Voice On' : 'Voice Off',
                onPressed: controller.toggleVoiceChat,
                color:
                    controller.isVoiceChatEnabled ? Colors.green : Colors.grey,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GameButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const _GameButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withOpacity(0.1),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
