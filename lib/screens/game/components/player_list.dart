import 'package:flutter/material.dart';
import 'package:crazygame/models/game_state.dart';

class PlayerList extends StatelessWidget {
  final GameState gameState;

  const PlayerList({
    super.key,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: gameState.players.length,
        itemBuilder: (context, index) {
          final player = gameState.players[index];
          return Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(8),
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
}
