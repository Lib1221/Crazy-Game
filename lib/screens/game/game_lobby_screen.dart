import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crazygame/routes/app_pages.dart';

class GameLobbyScreen extends StatelessWidget {
  const GameLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Lobby'),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Room info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Room #123', // TODO: Get from game data
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Waiting for players...', // TODO: Get from game state
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Players list
                Text(
                  'Players',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: 4, // TODO: Get from game data
                    itemBuilder: (context, index) {
                      final isHost = index == 0;
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            child: Text('P${index + 1}'),
                          ),
                          title: Text('Player ${index + 1}'),
                          subtitle: Text(isHost ? 'Host' : 'Player'),
                          trailing: isHost
                              ? const Icon(Icons.star, color: Colors.amber)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Start game button (only visible to host)
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement start game logic
                    Get.offAllNamed(Routes.GAME_ROOM);
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Start Game'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
