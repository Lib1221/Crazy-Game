import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crazygame/controllers/game_controller.dart';
import 'package:crazygame/screens/game/components/player_list.dart';
import 'package:crazygame/screens/game/components/discard_pile.dart';
import 'package:crazygame/screens/game/components/player_hand.dart';
import 'package:crazygame/screens/game/components/chat_area.dart';

class GameRoomScreen extends GetView<GameController> {
  const GameRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Room'),
        actions: [
          IconButton(
            icon: Obx(() => Icon(
                  controller.isVoiceChatEnabled ? Icons.mic : Icons.mic_off,
                )),
            onPressed: controller.toggleVoiceChat,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error != null) {
          return Center(
            child: Text(
              'Error: ${controller.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final gameState = controller.gameState;
        if (gameState == null) {
          return const Center(child: Text('No game state available'));
        }

        return Column(
          children: [
            PlayerList(gameState: gameState),
            Expanded(
              child: Column(
                children: [
                  DiscardPile(gameState: gameState),
                  Expanded(
                    child: PlayerHand(gameState: gameState),
                  ),
                ],
              ),
            ),
            const ChatArea(),
          ],
        );
      }),
    );
  }
}
