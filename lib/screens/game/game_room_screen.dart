import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crazygame/controllers/game_controller.dart';
import 'package:crazygame/models/game_state.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

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
            _buildPlayerList(gameState),
            Expanded(
              child: _buildGameArea(gameState),
            ),
            _buildChatArea(),
          ],
        );
      }),
    );
  }

  Widget _buildPlayerList(GameState gameState) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: gameState.players.length,
        itemBuilder: (context, index) {
          final player = gameState.players[index];
          return Card(
            child: Container(
              width: 80,
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(player.avatarUrl),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    player.name,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Cards: ${player.hand.length}',
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameArea(GameState gameState) {
    return Column(
      children: [
        _buildDiscardPile(gameState),
        Expanded(
          child: _buildPlayerHand(gameState),
        ),
      ],
    );
  }

  Widget _buildDiscardPile(GameState gameState) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          if (gameState.discardPile.isNotEmpty)
            Center(
              child: Image.network(
                gameState.discardPile.last.imageUrl,
                height: 120,
              ),
            ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${gameState.turnTimeRemaining}s',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerHand(GameState gameState) {
    final currentPlayer = gameState.players.firstWhere(
      (p) => p.id == gameState.currentPlayerId,
      orElse: () => gameState.players.first,
    );

    return CardSwiper(
      cards: currentPlayer.hand.map((card) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: NetworkImage(card.imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        );
      }).toList(),
      onSwipe: (previousIndex, currentIndex, direction) {
        if (direction == CardSwiperDirection.right) {
          controller.playCard(currentPlayer.hand[previousIndex]);
        }
        return true;
      },
      onUndo: (previousIndex, currentIndex, direction) {
        return true;
      },
      numberOfCardsDisplayed: 3,
      backCardOffset: const Offset(40, 40),
      padding: const EdgeInsets.all(24.0),
    );
  }

  Widget _buildChatArea() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: controller.chatMessages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(controller.chatMessages[index]),
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (message) {
                    if (message.isNotEmpty) {
                      controller.sendChatMessage(message);
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  // Handle send message
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
