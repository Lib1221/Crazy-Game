import 'package:crazygame/services/realtime/realtime_chat_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'chat_screen.dart';
import 'auth_screen.dart';
import 'create_group_screen.dart';
import 'my_games_screen.dart';
import 'leaderboard_screen.dart';
import 'achievements_screen.dart';
import 'friends_screen.dart';
import 'settings_screen.dart';
import '../theme/game_theme.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final RealtimeChatService _chatService = RealtimeChatService();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChats();
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: GameTheme.textColor),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const Text(
          'Game Rooms',
          style: TextStyle(
            color: GameTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: GameTheme.textColor),
            onPressed: _loadChats,
          ),
          IconButton(
            icon: const Icon(Icons.search, color: GameTheme.textColor),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: GameTheme.accentColor),
            onPressed: () async {
              final result = await Get.to(() => const CreateGroupScreen());
              if (result != null) {
                _loadChats();
              }
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
                decoration: BoxDecoration(
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
                          child: const CircleAvatar(
                            radius: 30,
                            backgroundColor: GameTheme.accentColor,
                            child: Icon(Icons.person,
                                size: 30, color: GameTheme.textColor),
                          ),
                        ),
                        const SizedBox(width: GameTheme.spacingM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Player Name',
                                style: TextStyle(
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
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: GameTheme.accentColor,
                                      size: 16,
                                    ),
                                    SizedBox(width: GameTheme.spacingS),
                                    Text(
                                      'Level 42',
                                      style: TextStyle(
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
                      icon: Icons.people,
                      title: 'Friends',
                      onTap: () {
                        Get.to(() => const FriendsScreen());
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
                    await _chatService.logout();
                    Get.offAll(() => const AuthScreen());
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
                      style: TextStyle(
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
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: GameTheme.errorColor,
                    ),
                    const SizedBox(height: GameTheme.spacingM),
                    Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(
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
                      Icons.sports_esports,
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

            // Print metadata from group_chats/$groupChatId/metadata
            print('=== Group Chats Metadata ===');

            for (var chat in chats) {
              print(chat);
              print('-------------------');
            }
            print('========================');

            return GridView.builder(
              padding: const EdgeInsets.all(GameTheme.spacingM),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: GameTheme.spacingM,
                mainAxisSpacing: GameTheme.spacingM,
              ),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                final groupChatId = chat['chatId'] as String;
                final metadata = chat['metadata'] as Map<String, dynamic>?;

                return GestureDetector(
                  onTap: () {
                    Get.to(() => ChatScreen(
                          chatId: groupChatId,
                          chatName: metadata?['name'] ?? 'Unnamed Chat',
                        ));
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: chat['isActive'] == true
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
                                            chat['metadata']?['name'] ??
                                                'Unnamed Chat',
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
                                      chat['isActive'] == true
                                          ? 'Active'
                                          : 'Inactive',
                                      style: TextStyle(
                                        color: chat['isActive'] == true
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
                                child: Text(
                                  metadata?['description'] ??
                                      'No description available',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: GameTheme.textColor.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
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
                                        '${(chat['participants'] as Map<String, dynamic>).length} Players',
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
