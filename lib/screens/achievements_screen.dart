import 'package:flutter/material.dart';
import '../theme/game_theme.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Achievements',
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
        child: GridView.builder(
          padding: const EdgeInsets.all(GameTheme.spacingM),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: GameTheme.spacingM,
            mainAxisSpacing: GameTheme.spacingM,
          ),
          itemCount: 6,
          itemBuilder: (context, index) {
            return _buildAchievementCard(
              title: _getAchievementTitle(index),
              description: _getAchievementDescription(index),
              icon: _getAchievementIcon(index),
              isUnlocked: index < 3,
              progress: index < 3 ? 1.0 : (index - 2) * 0.2,
            );
          },
        ),
      ),
    );
  }

  String _getAchievementTitle(int index) {
    final titles = [
      'First Victory',
      'Master Player',
      'Social Butterfly',
      'Game Collector',
      'Speed Runner',
      'Perfect Score',
    ];
    return titles[index];
  }

  String _getAchievementDescription(int index) {
    final descriptions = [
      'Win your first game',
      'Win 10 games',
      'Play with 5 different players',
      'Create 3 game rooms',
      'Win a game in under 5 minutes',
      'Score 1000 points in a single game',
    ];
    return descriptions[index];
  }

  IconData _getAchievementIcon(int index) {
    final icons = [
      Icons.emoji_events,
      Icons.star,
      Icons.people,
      Icons.games,
      Icons.timer,
      Icons.score,
    ];
    return icons[index];
  }

  Widget _buildAchievementCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isUnlocked,
    required double progress,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: GameTheme.surfaceColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(GameTheme.borderRadiusLarge),
        border: Border.all(
          color: isUnlocked
              ? GameTheme.accentColor
              : GameTheme.textColor.withOpacity(0.1),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(GameTheme.spacingM),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked
                  ? GameTheme.accentColor.withOpacity(0.2)
                  : GameTheme.textColor.withOpacity(0.1),
            ),
            child: Icon(
              icon,
              size: 40,
              color: isUnlocked
                  ? GameTheme.accentColor
                  : GameTheme.textColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: GameTheme.spacingM),
          Text(
            title,
            style: TextStyle(
              color: isUnlocked
                  ? GameTheme.textColor
                  : GameTheme.textColor.withOpacity(0.5),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: GameTheme.spacingS),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: GameTheme.spacingM),
            child: Text(
              description,
              style: TextStyle(
                color: isUnlocked
                    ? GameTheme.textColor.withOpacity(0.7)
                    : GameTheme.textColor.withOpacity(0.3),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: GameTheme.spacingM),
          if (!isUnlocked) ...[
            LinearProgressIndicator(
              value: progress,
              backgroundColor: GameTheme.textColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(GameTheme.accentColor),
            ),
            const SizedBox(height: GameTheme.spacingS),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                color: GameTheme.textColor.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
