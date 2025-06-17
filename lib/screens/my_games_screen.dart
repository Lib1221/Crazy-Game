import 'package:flutter/material.dart';
import '../theme/game_theme.dart';

class MyGamesScreen extends StatelessWidget {
  const MyGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Games',
          style: TextStyle(
            color: GameTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: GameTheme.primaryGradient,
        ),
        child: ListView(
          padding: const EdgeInsets.all(GameTheme.spacingM),
          children: [
            _buildGameCard(
              title: 'Active Games',
              icon: Icons.sports_esports,
              count: 3,
              color: GameTheme.accentColor,
            ),
            _buildGameCard(
              title: 'Game History',
              icon: Icons.history,
              count: 12,
              color: GameTheme.secondaryColor,
            ),
            _buildGameCard(
              title: 'Achievements',
              icon: Icons.emoji_events,
              count: 5,
              color: GameTheme.accentColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard({
    required String title,
    required IconData icon,
    required int count,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: GameTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(GameTheme.borderRadiusLarge),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(GameTheme.spacingM),
        leading: Container(
          padding: const EdgeInsets.all(GameTheme.spacingS),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(GameTheme.borderRadiusMedium),
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: GameTheme.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: GameTheme.spacingM,
            vertical: GameTheme.spacingS,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(GameTheme.borderRadiusMedium),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
