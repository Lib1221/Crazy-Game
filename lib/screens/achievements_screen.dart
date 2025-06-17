import 'package:flutter/material.dart';
import '../theme/game_theme.dart';
import '../services/realtime/realtime_chat_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final RealtimeChatService _chatService = RealtimeChatService();
  int _playerRank = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlayerRank();
  }

  Future<void> _loadPlayerRank() async {
    setState(() => _isLoading = true);
    final userId = _chatService.currentUserId;
    if (userId != null) {
      final userInfo = await _chatService.getUserInfo(userId);
      if (userInfo != null) {
        setState(() {
          _playerRank = userInfo['rank'] as int? ?? 0;
          _isLoading = false;
        });
      }
    }
  }

  List<Achievement> _getAchievements() {
    return [
      Achievement(
        id: 'rank_1',
        title: 'Novice Player',
        description: 'Reach Rank 5',
        icon: Icons.star,
        requiredRank: 5,
        reward: 'Level 2',
      ),
      Achievement(
        id: 'rank_2',
        title: 'Rising Star',
        description: 'Reach Rank 10',
        icon: Icons.star,
        requiredRank: 10,
        reward: 'Level 3',
      ),
      Achievement(
        id: 'rank_3',
        title: 'Skilled Player',
        description: 'Reach Rank 20',
        icon: Icons.star,
        requiredRank: 20,
        reward: 'Level 5',
      ),
      Achievement(
        id: 'rank_4',
        title: 'Master Player',
        description: 'Reach Rank 50',
        icon: Icons.star,
        requiredRank: 50,
        reward: 'Level 11',
      ),
      Achievement(
        id: 'rank_5',
        title: 'Grand Master',
        description: 'Reach Rank 100',
        icon: Icons.star,
        requiredRank: 100,
        reward: 'Level 21',
      ),
      Achievement(
        id: 'rank_6',
        title: 'Legend',
        description: 'Reach Rank 200',
        icon: Icons.star,
        requiredRank: 200,
        reward: 'Level 41',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final achievements = _getAchievements();

    return Scaffold(
      backgroundColor: GameTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: GameTheme.surfaceColor,
        title: const Text(
          'Achievements',
          style: TextStyle(
            color: GameTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: GameTheme.textColor),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(GameTheme.accentColor),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadPlayerRank,
              child: ListView.builder(
                padding: const EdgeInsets.all(GameTheme.spacingM),
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  final achievement = achievements[index];
                  final isUnlocked = _playerRank >= achievement.requiredRank;
                  final progress =
                      (_playerRank / achievement.requiredRank * 100)
                          .clamp(0.0, 100.0);

                  return Container(
                    margin: const EdgeInsets.only(bottom: GameTheme.spacingM),
                    decoration: BoxDecoration(
                      gradient: isUnlocked
                          ? GameTheme.primaryGradient
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                GameTheme.surfaceColor,
                                GameTheme.surfaceColor.withOpacity(0.8),
                              ],
                            ),
                      borderRadius:
                          BorderRadius.circular(GameTheme.borderRadiusLarge),
                      boxShadow: isUnlocked
                          ? [
                              BoxShadow(
                                color: GameTheme.accentColor.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(GameTheme.spacingS),
                            decoration: BoxDecoration(
                              color: isUnlocked
                                  ? GameTheme.accentColor
                                  : GameTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(
                                  GameTheme.borderRadiusMedium),
                            ),
                            child: Icon(
                              achievement.icon,
                              color: isUnlocked
                                  ? GameTheme.textColor
                                  : GameTheme.textColor.withOpacity(0.5),
                            ),
                          ),
                          title: Text(
                            achievement.title,
                            style: TextStyle(
                              color: isUnlocked
                                  ? GameTheme.textColor
                                  : GameTheme.textColor.withOpacity(0.7),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                achievement.description,
                                style: TextStyle(
                                  color: isUnlocked
                                      ? GameTheme.textColor.withOpacity(0.8)
                                      : GameTheme.textColor.withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(height: GameTheme.spacingS),
                              Text(
                                'Reward: ${achievement.reward}',
                                style: TextStyle(
                                  color: GameTheme.accentColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          trailing: isUnlocked
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: GameTheme.spacingS,
                                    vertical: GameTheme.spacingXS,
                                  ),
                                  decoration: BoxDecoration(
                                    color: GameTheme.accentColor,
                                    borderRadius: BorderRadius.circular(
                                        GameTheme.borderRadiusSmall),
                                  ),
                                  child: const Text(
                                    'Unlocked!',
                                    style: TextStyle(
                                      color: GameTheme.textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Rank ${achievement.requiredRank}',
                                  style: TextStyle(
                                    color: GameTheme.textColor.withOpacity(0.5),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        if (!isUnlocked)
                          Padding(
                            padding: const EdgeInsets.all(GameTheme.spacingM),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Progress: ${progress.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: GameTheme.textColor.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: GameTheme.spacingS),
                                LinearProgressIndicator(
                                  value: progress / 100,
                                  backgroundColor:
                                      GameTheme.surfaceColor.withOpacity(0.3),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      GameTheme.accentColor),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int requiredRank;
  final String reward;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.requiredRank,
    required this.reward,
  });
}
