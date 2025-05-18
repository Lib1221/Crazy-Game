import 'package:flutter/material.dart';
import 'package:crazygame/models/game_state.dart';

class DiscardPile extends StatelessWidget {
  final GameState gameState;

  const DiscardPile({
    super.key,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context) {
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
} 