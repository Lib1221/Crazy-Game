import 'package:flutter/material.dart'
import 'package:get/get.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:crazygame/models/game_state.dart' as game;
import 'package:crazygame/controllers/game_controller.dart';

class GameCard extends StatelessWidget {
  final String imageUrl;

  const GameCard({
    super.key,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class PlayerHand extends StatelessWidget {
  final game.GameState gameState;

  const PlayerHand({
    super.key,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context) {
    final currentPlayer = gameState.players.firstWhere(
      (p) => p.id == gameState.currentPlayerId,
      orElse: () => gameState.players.first,
    );
    final gameController = Get.find<GameController>();

    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CardSwiper(
        numberOfCardsDisplayed: 3,
        backCardOffset: const Offset(40, 40),
        padding: const EdgeInsets.all(24.0),
        cardsCount: currentPlayer.hand.length,
        onSwipe: (previousIndex, currentIndex, direction) {
          if (direction == CardSwiperDirection.right) {
            gameController.playCard(currentPlayer.hand[previousIndex]);
          }
          return true;
        },
        onUndo: (previousIndex, currentIndex, direction) {
          gameController.undoPlayCard();
          return true;
        },
        cardBuilder: (context, index) {
          if (index >= currentPlayer.hand.length) return null;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
              image: DecorationImage(
                image: NetworkImage(currentPlayer.hand[index].imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}
