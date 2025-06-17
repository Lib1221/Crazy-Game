import 'package:flutter/material.dart';
import '../theme/game_theme.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Leaderboard',
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
            _buildTopPlayers(),
            const SizedBox(height: GameTheme.spacingL),
            _buildLeaderboardList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPlayers() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildTopPlayerCard(
          rank: 2,
          name: 'Player 2',
          score: 850,
          isCurrentUser: false,
        ),
        _buildTopPlayerCard(
          rank: 1,
          name: 'Player 1',
          score: 1000,
          isCurrentUser: true,
          isFirst: true,
        ),
        _buildTopPlayerCard(
          rank: 3,
          name: 'Player 3',
          score: 750,
          isCurrentUser: false,
        ),
      ],
    );
  }

  Widget _buildTopPlayerCard({
    required int rank,
    required String name,
    required int score,
    required bool isCurrentUser,
    bool isFirst = false,
  }) {
    return Column(
      children: [
        Container(
          width: isFirst ? 100 : 80,
          height: isFirst ? 100 : 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: GameTheme.primaryGradient,
            border: Border.all(
              color:
                  isCurrentUser ? GameTheme.accentColor : GameTheme.textColor,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: GameTheme.accentColor.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              rank.toString(),
              style: const TextStyle(
                color: GameTheme.textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: GameTheme.spacingS),
        Text(
          name,
          style: TextStyle(
            color: isCurrentUser ? GameTheme.accentColor : GameTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          score.toString(),
          style: const TextStyle(
            color: GameTheme.textColor,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardList() {
    return Column(
      children: List.generate(
        10,
        (index) => _buildLeaderboardItem(
          rank: index + 4,
          name: 'Player ${index + 4}',
          score: 700 - (index * 50),
          isCurrentUser: false,
        ),
      ),
    );
  }

  Widget _buildLeaderboardItem({
    required int rank,
    required String name,
    required int score,
    required bool isCurrentUser,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: GameTheme.spacingS),
      decoration: BoxDecoration(
        color: GameTheme.surfaceColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(GameTheme.borderRadiusMedium),
        border: Border.all(
          color: isCurrentUser
              ? GameTheme.accentColor
              : GameTheme.textColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: GameTheme.accentColor.withOpacity(0.2),
          ),
          child: Center(
            child: Text(
              rank.toString(),
              style: const TextStyle(
                color: GameTheme.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            color: isCurrentUser ? GameTheme.accentColor : GameTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Text(
          score.toString(),
          style: const TextStyle(
            color: GameTheme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
