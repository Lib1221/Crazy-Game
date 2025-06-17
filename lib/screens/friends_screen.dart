import 'package:flutter/material.dart';
import '../theme/game_theme.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Friends',
          style: TextStyle(
            color: GameTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: GameTheme.accentColor),
            onPressed: () {
              // TODO: Implement add friend
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: GameTheme.primaryGradient,
        ),
        child: ListView(
          padding: const EdgeInsets.all(GameTheme.spacingM),
          children: [
            _buildSearchBar(),
            const SizedBox(height: GameTheme.spacingM),
            _buildOnlineFriends(),
            const SizedBox(height: GameTheme.spacingL),
            _buildAllFriends(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: GameTheme.surfaceColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(GameTheme.borderRadiusMedium),
        border: Border.all(
          color: GameTheme.textColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: TextField(
        style: const TextStyle(color: GameTheme.textColor),
        decoration: InputDecoration(
          hintText: 'Search friends...',
          hintStyle: TextStyle(color: GameTheme.textColor.withOpacity(0.5)),
          prefixIcon:
              Icon(Icons.search, color: GameTheme.textColor.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: GameTheme.spacingM,
            vertical: GameTheme.spacingS,
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineFriends() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Online Friends',
          style: TextStyle(
            color: GameTheme.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: GameTheme.spacingM),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (context, index) {
              return _buildOnlineFriendCard(
                name: 'Friend ${index + 1}',
                isPlaying: index % 2 == 0,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOnlineFriendCard({
    required String name,
    required bool isPlaying,
  }) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: GameTheme.spacingM),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: GameTheme.primaryGradient,
                  border: Border.all(
                    color: GameTheme.accentColor,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    name[0],
                    style: const TextStyle(
                      color: GameTheme.textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isPlaying ? GameTheme.accentColor : Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: GameTheme.backgroundColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: GameTheme.spacingS),
          Text(
            name,
            style: const TextStyle(
              color: GameTheme.textColor,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            isPlaying ? 'Playing' : 'Online',
            style: TextStyle(
              color: isPlaying ? GameTheme.accentColor : Colors.green,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllFriends() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'All Friends',
          style: TextStyle(
            color: GameTheme.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: GameTheme.spacingM),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 10,
          itemBuilder: (context, index) {
            return _buildFriendListItem(
              name: 'Friend ${index + 1}',
              isOnline: index < 5,
              isPlaying: index % 2 == 0,
            );
          },
        ),
      ],
    );
  }

  Widget _buildFriendListItem({
    required String name,
    required bool isOnline,
    required bool isPlaying,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: GameTheme.spacingS),
      decoration: BoxDecoration(
        color: GameTheme.surfaceColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(GameTheme.borderRadiusMedium),
      ),
      child: ListTile(
        leading: Stack(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: GameTheme.primaryGradient,
              ),
              child: Center(
                child: Text(
                  name[0],
                  style: const TextStyle(
                    color: GameTheme.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isPlaying ? GameTheme.accentColor : Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: GameTheme.backgroundColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          name,
          style: const TextStyle(
            color: GameTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          isPlaying ? 'Playing' : (isOnline ? 'Online' : 'Offline'),
          style: TextStyle(
            color: isPlaying
                ? GameTheme.accentColor
                : (isOnline
                    ? Colors.green
                    : GameTheme.textColor.withOpacity(0.5)),
            fontSize: 12,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.message, color: GameTheme.accentColor),
          onPressed: () {
            // TODO: Navigate to chat
          },
        ),
      ),
    );
  }
}
