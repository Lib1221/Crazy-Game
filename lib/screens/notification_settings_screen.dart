import 'package:flutter/material.dart';
import '../theme/game_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _gameInvites = true;
  bool _friendRequests = true;
  bool _gameResults = true;
  bool _achievements = true;
  bool _leaderboardUpdates = true;
  bool _chatMessages = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Notification Settings',
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
            _buildSection(
              title: 'Game Notifications',
              children: [
                _buildSwitchTile(
                  title: 'Game Invites',
                  subtitle: 'Get notified when someone invites you to play',
                  value: _gameInvites,
                  onChanged: (value) {
                    setState(() {
                      _gameInvites = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  title: 'Game Results',
                  subtitle: 'Get notified about your game results',
                  value: _gameResults,
                  onChanged: (value) {
                    setState(() {
                      _gameResults = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  title: 'Achievements',
                  subtitle: 'Get notified when you earn achievements',
                  value: _achievements,
                  onChanged: (value) {
                    setState(() {
                      _achievements = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  title: 'Leaderboard Updates',
                  subtitle:
                      'Get notified about your leaderboard position changes',
                  value: _leaderboardUpdates,
                  onChanged: (value) {
                    setState(() {
                      _leaderboardUpdates = value;
                    });
                  },
                ),
              ],
            ),
            _buildSection(
              title: 'Social Notifications',
              children: [
                _buildSwitchTile(
                  title: 'Friend Requests',
                  subtitle:
                      'Get notified when someone sends you a friend request',
                  value: _friendRequests,
                  onChanged: (value) {
                    setState(() {
                      _friendRequests = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  title: 'Chat Messages',
                  subtitle: 'Get notified when you receive new messages',
                  value: _chatMessages,
                  onChanged: (value) {
                    setState(() {
                      _chatMessages = value;
                    });
                  },
                ),
              ],
            ),
            _buildSection(
              title: 'Notification Preferences',
              children: [
                _buildSwitchTile(
                  title: 'Sound',
                  subtitle: 'Play sound for notifications',
                  value: _soundEnabled,
                  onChanged: (value) {
                    setState(() {
                      _soundEnabled = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  title: 'Vibration',
                  subtitle: 'Vibrate for notifications',
                  value: _vibrationEnabled,
                  onChanged: (value) {
                    setState(() {
                      _vibrationEnabled = value;
                    });
                  },
                ),
              ],
            ),
            _buildSection(
              title: 'Quiet Hours',
              children: [
                _buildButtonTile(
                  title: 'Set Quiet Hours',
                  subtitle: 'Configure when you don\'t want to be disturbed',
                  icon: Icons.access_time,
                  onTap: () {
                    // TODO: Implement quiet hours settings
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GameTheme.spacingM,
            vertical: GameTheme.spacingS,
          ),
          child: Text(
            title,
            style: const TextStyle(
              color: GameTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: GameTheme.surfaceColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(GameTheme.borderRadiusLarge),
          ),
          child: Column(
            children: children,
          ),
        ),
        const SizedBox(height: GameTheme.spacingL),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: GameTheme.textColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            color: GameTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: GameTheme.textColor.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: GameTheme.accentColor,
      ),
    );
  }

  Widget _buildButtonTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: GameTheme.textColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: GameTheme.accentColor,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: GameTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: GameTheme.textColor.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: GameTheme.textColor,
        ),
        onTap: onTap,
      ),
    );
  }
}
