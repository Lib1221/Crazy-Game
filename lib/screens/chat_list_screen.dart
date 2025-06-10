import 'package:crazygame/services/realtime/realtime_chat_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'chat_screen.dart';
import 'auth_screen.dart';
import 'create_group_screen.dart';
import '../theme/game_theme.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final RealtimeChatService _chatService = RealtimeChatService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: GameTheme.textColor),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
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
                setState(() {});
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: GameTheme.surfaceColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: GameTheme.primaryGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: GameTheme.accentColor,
                    child: Icon(Icons.person,
                        size: 30, color: GameTheme.textColor),
                  ),
                  const SizedBox(height: GameTheme.spacingM),
                  const Text(
                    'Player Name',
                    style: TextStyle(
                      color: GameTheme.textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Level 42',
                    style: TextStyle(
                      color: GameTheme.textColor.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: GameTheme.accentColor),
              title: const Text('Home',
                  style: TextStyle(color: GameTheme.textColor)),
              onTap: () => Get.back(),
            ),
            ListTile(
              leading:
                  const Icon(Icons.leaderboard, color: GameTheme.accentColor),
              title: const Text('Leaderboard',
                  style: TextStyle(color: GameTheme.textColor)),
              onTap: () {
                // TODO: Navigate to leaderboard
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: GameTheme.accentColor),
              title: const Text('Settings',
                  style: TextStyle(color: GameTheme.textColor)),
              onTap: () {
                // TODO: Navigate to settings
              },
            ),
            const Divider(color: GameTheme.accentColor),
            ListTile(
              leading: const Icon(Icons.logout, color: GameTheme.errorColor),
              title: const Text('Logout',
                  style: TextStyle(color: GameTheme.errorColor)),
              onTap: () async {
                await _chatService.logout();
                Get.offAll(() => const AuthScreen());
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _chatService.getGroupChatsData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(GameTheme.accentColor),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: GameTheme.errorColor),
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
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final participants = chat['participants'] as Map<String, dynamic>;
              final isActive = index % 2 == 0;

              return GestureDetector(
                onTap: () {
                  Get.to(() => ChatScreen(
                        chatId: chat['chatId'],
                        chatName: chat['name'],
                      ));
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isActive
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.all(GameTheme.spacingS),
                                  decoration: BoxDecoration(
                                    color:
                                        GameTheme.accentColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(
                                        GameTheme.borderRadiusMedium),
                                  ),
                                  child: Icon(
                                    isActive
                                        ? Icons.sports_esports
                                        : Icons.games,
                                    color: GameTheme.textColor,
                                    size: 32,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: GameTheme.spacingS,
                                    vertical: GameTheme.spacingXS,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? GameTheme.accentColor.withOpacity(0.2)
                                        : GameTheme.errorColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(
                                        GameTheme.borderRadiusSmall),
                                  ),
                                  child: Text(
                                    isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      color: isActive
                                          ? GameTheme.accentColor
                                          : GameTheme.errorColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              chat['name'],
                              style: const TextStyle(
                                color: GameTheme.textColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: GameTheme.spacingXS),
                            Text(
                              chat['lastMessage'] ?? 'No activity yet',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: GameTheme.textColor.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: GameTheme.spacingM),
                            Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 16,
                                  color: GameTheme.textColor.withOpacity(0.6),
                                ),
                                const SizedBox(width: GameTheme.spacingXS),
                                Text(
                                  '${participants.length} Players Online',
                                  style: TextStyle(
                                    color: GameTheme.textColor.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: GameTheme.spacingM),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: GameTheme.spacingS,
                              ),
                              decoration: BoxDecoration(
                                color: GameTheme.textColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                    GameTheme.borderRadiusMedium),
                              ),
                              child: const Center(
                                child: Text(
                                  'Join Room',
                                  style: TextStyle(
                                    color: GameTheme.textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
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
