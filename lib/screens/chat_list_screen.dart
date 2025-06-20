import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/realtime/realtime_chat_service.dart';
import '../theme/game_theme.dart';
import '../controllers/auth_controller.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';
import 'create_group_screen.dart';
import 'my_games_screen.dart';
import 'leaderboard_screen.dart';
import 'achievements_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final RealtimeChatService _chatService = RealtimeChatService();
  bool _isLoading = true;
  String? _error;
  String? _playerName;
  int _playerRank = 0;

  @override
  void initState() {
    super.initState();
    _loadChats();
    _loadPlayerName();
    _loadPlayerRank();
  }

  Future<void> _loadPlayerName() async {
    final userId = _chatService.currentUserId;
    if (userId != null) {
      final userInfo = await _chatService.getUserInfo(userId);
      if (userInfo != null) {
        setState(() {
          _playerName = userInfo['name'] as String?;
        });
      }
    }
  }

  Future<void> _loadPlayerRank() async {
    final userId = _chatService.currentUserId;
    if (userId != null) {
      final userInfo = await _chatService.getUserInfo(userId);
      if (userInfo != null) {
        setState(() {
          _playerRank = userInfo['rank'] as int? ?? 0;
        });
      }
    }
  }

  int _calculateLevel(int rank) {
    return (rank ~/ 5) + 1;
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Force a refresh of the chat data
      await _chatService.getGroupChatsData().first;
    } catch (e) {
      setState(() {
        _error = 'Failed to load chats: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: GameTheme.surfaceColor,
        title: const Text(
          'Game Room',
          style: TextStyle(
            color: GameTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: GameTheme.textColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateGroupScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Get.to(() => const SettingsScreen());
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: GameTheme.surfaceColor,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(GameTheme.spacingL),
                decoration: const BoxDecoration(
                  gradient: GameTheme.primaryGradient,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: GameTheme.accentColor,
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
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: GameTheme.accentColor,
                            child: const Icon(Icons.person,
                                size: 30, color: GameTheme.textColor),
                          ),
                        ),
                        const SizedBox(width: GameTheme.spacingM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _playerName ?? 'Loading...',
                                style: const TextStyle(
                                  color: GameTheme.textColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: GameTheme.spacingS),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: GameTheme.spacingM,
                                  vertical: GameTheme.spacingS,
                                ),
                                decoration: BoxDecoration(
                                  color: GameTheme.accentColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(
                                      GameTheme.borderRadiusMedium),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: GameTheme.accentColor,
                                      size: 16,
                                    ),
                                    const SizedBox(width: GameTheme.spacingS),
                                    Text(
                                      'Level ${_calculateLevel(_playerRank)}',
                                      style: const TextStyle(
                                        color: GameTheme.textColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    vertical: GameTheme.spacingM,
                  ),
                  children: [
                    _buildDrawerItem(
                      icon: Icons.home,
                      title: 'Home',
                      onTap: () => Get.back(),
                    ),
                    _buildDrawerItem(
                      icon: Icons.sports_esports,
                      title: 'My Games',
                      onTap: () {
                        Get.to(() => const MyGamesScreen());
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.leaderboard,
                      title: 'Leaderboard',
                      onTap: () {
                        Get.to(() => const LeaderboardScreen());
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.emoji_events,
                      title: 'Achievements',
                      onTap: () {
                        Get.to(() => const AchievementsScreen());
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.settings,
                      title: 'Settings',
                      onTap: () {
                        Get.to(() => const SettingsScreen());
                      },
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(GameTheme.spacingM),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: GameTheme.accentColor.withOpacity(0.2),
                    ),
                  ),
                ),
                child: _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  isDestructive: true,
                  onTap: () async {
                    final authController = Get.find<AuthController>();
                    await authController.logout();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadChats,
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _chatService.getGroupChatsData(),
          builder: (context, snapshot) {
            if (_isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(GameTheme.accentColor),
                ),
              );
            }

            if (_error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: GameTheme.errorColor,
                    ),
                    const SizedBox(height: GameTheme.spacingM),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: GameTheme.errorColor,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: GameTheme.spacingM),
                    ElevatedButton(
                      onPressed: _loadChats,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GameTheme.accentColor,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: GameTheme.errorColor,
                    ),
                    const SizedBox(height: GameTheme.spacingM),
                    Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(
                        color: GameTheme.errorColor,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: GameTheme.spacingM),
                    ElevatedButton(
                      onPressed: _loadChats,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GameTheme.accentColor,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final chats = snapshot.data ?? [];
            if (chats.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.casino,
                      size: 64,
                      color: GameTheme.accentColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: GameTheme.spacingM),
                    const Text(
                      'No Game Rooms Yet',
                      style: TextStyle(
                        color: GameTheme.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: GameTheme.spacingS),
                    Text(
                      'Create a new room to start gaming!',
                      style: TextStyle(
                        color: GameTheme.textColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: GameTheme.spacingL),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result =
                            await Get.to(() => const CreateGroupScreen());
                        if (result != null) {
                          _loadChats();
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create Room'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GameTheme.accentColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: GameTheme.spacingL,
                          vertical: GameTheme.spacingM,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Filter out chats where user has no cards
            final validChats = chats.where((chat) {
              final currentUserId = _chatService.currentUserId;
              final participants =
                  _chatService.safeMapFrom(chat['participants']);
              final gameData = _chatService.safeMapFrom(chat['gameData']);
              final userNumbers =
                  _chatService.safeMapFrom(gameData['userNumbers']);
              final currentUserNumbers =
                  userNumbers[currentUserId]?['numbers'] as List<dynamic>?;

              return currentUserId != null &&
                  participants.isNotEmpty &&
                  participants.containsKey(currentUserId) &&
                  currentUserNumbers != null &&
                  currentUserNumbers.isNotEmpty;
            }).toList();

            if (validChats.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.casino,
                      size: 64,
                      color: GameTheme.accentColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: GameTheme.spacingM),
                    const Text(
                      'No Active Games',
                      style: TextStyle(
                        color: GameTheme.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: GameTheme.spacingS),
                    Text(
                      'Join a game or create a new one to start playing!',
                      style: TextStyle(
                        color: GameTheme.textColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: GameTheme.spacingL),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result =
                                await Get.to(() => const CreateGroupScreen());
                            if (result != null) {
                              _loadChats();
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Create Room'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GameTheme.accentColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: GameTheme.spacingL,
                              vertical: GameTheme.spacingM,
                            ),
                          ),
                        ),
                        const SizedBox(width: GameTheme.spacingM),
                        ElevatedButton.icon(
                          onPressed: _loadChats,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GameTheme.surfaceColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: GameTheme.spacingL,
                              vertical: GameTheme.spacingM,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(GameTheme.spacingM),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: GameTheme.spacingM,
                mainAxisSpacing: GameTheme.spacingM,
              ),
              itemCount: validChats.length,
              itemBuilder: (context, index) {
                final chat = validChats[index];
                final groupChatId = chat['chatId'] as String;
                final metadata = _chatService.safeMapFrom(chat['metadata']);
                final participants =
                    _chatService.safeMapFrom(chat['participants']);

                return GestureDetector(
                  onTap: () {
                    Get.to(() => ChatScreen(
                          chatId: groupChatId,
                          chatName: metadata['name'] ?? 'Unnamed Chat',
                        ));
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: _isGameOver(chat)
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                GameTheme.errorColor.withOpacity(0.8),
                                GameTheme.errorColor.withOpacity(0.6),
                              ],
                            )
                          : chat['isActive'] == true
                              ? GameTheme.primaryGradient
                              : GameTheme.secondaryGradient,
                      borderRadius:
                          BorderRadius.circular(GameTheme.borderRadiusLarge),
                      boxShadow: GameTheme.glowShadow,
                    ),
                    child: Stack(
                      children: [
                        // Background pattern
                        Positioned.fill(
                          child: CustomPaint(
                            painter: GameRoomBackgroundPainter(),
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(GameTheme.spacingM),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        if (chat['createdBy'] ==
                                            _chatService.currentUserId)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: GameTheme.spacingS),
                                            child: Icon(
                                              Icons.admin_panel_settings,
                                              color: GameTheme.accentColor,
                                              size: 20,
                                            ),
                                          ),
                                        Expanded(
                                          child: Text(
                                            metadata['name'] ?? 'Unnamed Chat',
                                            style: const TextStyle(
                                              color: GameTheme.textColor,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: GameTheme.spacingS,
                                      vertical: GameTheme.spacingXS,
                                    ),
                                    decoration: BoxDecoration(
                                      color: chat['isActive'] == true
                                          ? GameTheme.accentColor
                                              .withOpacity(0.2)
                                          : GameTheme.errorColor
                                              .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(
                                          GameTheme.borderRadiusSmall),
                                    ),
                                    child: Text(
                                      _isGameOver(chat)
                                          ? 'Game Over'
                                          : chat['isActive'] == true
                                              ? 'Active'
                                              : 'Inactive',
                                      style: TextStyle(
                                        color: _isGameOver(chat)
                                            ? GameTheme.errorColor
                                            : chat['isActive'] == true
                                                ? GameTheme.accentColor
                                                : GameTheme.errorColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: GameTheme.spacingS),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_isGameOver(chat)) ...[
                                      const Text(
                                        'Game Over',
                                        style: TextStyle(
                                          color: GameTheme.errorColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(
                                          height: GameTheme.spacingS),
                                      Text(
                                        'Winner: ${_getWinnerName(chat)}',
                                        style: TextStyle(
                                          color: GameTheme.accentColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(
                                          height: GameTheme.spacingS),
                                    ],
                                    Text(
                                      _isGameOver(chat)
                                          ? ''
                                          : metadata['description'] ??
                                              'No description available',
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: _isGameOver(chat)
                                            ? GameTheme.textColor
                                                .withOpacity(0.9)
                                            : GameTheme.textColor
                                                .withOpacity(0.8),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: GameTheme.spacingM),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.people,
                                        size: 16,
                                        color: GameTheme.textColor
                                            .withOpacity(0.6),
                                      ),
                                      const SizedBox(
                                          width: GameTheme.spacingXS),
                                      Text(
                                        '${participants.length} Players',
                                        style: TextStyle(
                                          color: GameTheme.textColor
                                              .withOpacity(0.6),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? GameTheme.errorColor : GameTheme.accentColor;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: GameTheme.spacingM,
        vertical: GameTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(GameTheme.borderRadiusMedium),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GameTheme.borderRadiusMedium),
        ),
      ),
    );
  }

  bool _isGameOver(Map<String, dynamic> chat) {
    try {
      final gameData = _chatService.safeMapFrom(chat['gameData']);
      if (gameData.isEmpty) return false;

      final userNumbers = _chatService.safeMapFrom(gameData['userNumbers']);
      if (userNumbers.isEmpty) return false;

      // Check if any participant has an empty number array
      for (var participant in userNumbers.values) {
        if (participant is Map) {
          final numbers = participant['numbers'] as List<dynamic>?;
          if (numbers == null || numbers.isEmpty) {
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  String _getWinnerName(Map<String, dynamic> chat) {
    try {
      final gameData = _chatService.safeMapFrom(chat['gameData']);
      if (gameData.isEmpty) return 'Unknown';

      final userNumbers = _chatService.safeMapFrom(gameData['userNumbers']);
      if (userNumbers.isEmpty) return 'Unknown';

      // Find the participant with empty numbers array
      for (var entry in userNumbers.entries) {
        final participant =
            entry.value is Map ? _chatService.safeMapFrom(entry.value) : null;
        if (participant != null) {
          final numbers = participant['numbers'] as List<dynamic>?;
          if (numbers == null || numbers.isEmpty) {
            // Get the participant's name from metadata
            final participants = _chatService.safeMapFrom(chat['participants']);
            if (participants.isNotEmpty) {
              final participantData = participants[entry.key] is Map
                  ? _chatService.safeMapFrom(participants[entry.key])
                  : null;
              return participantData?['name'] ?? 'Unknown Player';
            }
          }
        }
      }
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }
}

class GameRoomBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = GameTheme.textColor.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Draw grid pattern
    for (int i = 0; i < size.width; i += 20) {
      for (int j = 0; j < size.height; j += 20) {
        canvas.drawCircle(Offset(i.toDouble(), j.toDouble()), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
