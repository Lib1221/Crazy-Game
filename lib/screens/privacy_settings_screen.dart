import 'package:flutter/material.dart';
import '../theme/game_theme.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _showOnlineStatus = true;
  bool _showGameActivity = true;
  bool _allowFriendRequests = true;
  bool _showInLeaderboard = true;
  String _profileVisibility = 'Everyone';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Privacy Settings',
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
              title: 'Profile Visibility',
              children: [
                _buildDropdownTile(
                  title: 'Who can see your profile',
                  subtitle: 'Control who can view your profile information',
                  value: _profileVisibility,
                  items: const ['Everyone', 'Friends Only', 'Private'],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _profileVisibility = value;
                      });
                    }
                  },
                ),
              ],
            ),
            _buildSection(
              title: 'Activity Status',
              children: [
                _buildSwitchTile(
                  title: 'Show Online Status',
                  subtitle: 'Let others see when you are online',
                  value: _showOnlineStatus,
                  onChanged: (value) {
                    setState(() {
                      _showOnlineStatus = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  title: 'Show Game Activity',
                  subtitle: 'Let others see what games you are playing',
                  value: _showGameActivity,
                  onChanged: (value) {
                    setState(() {
                      _showGameActivity = value;
                    });
                  },
                ),
              ],
            ),
            _buildSection(
              title: 'Social Settings',
              children: [
                _buildSwitchTile(
                  title: 'Allow Friend Requests',
                  subtitle: 'Let others send you friend requests',
                  value: _allowFriendRequests,
                  onChanged: (value) {
                    setState(() {
                      _allowFriendRequests = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  title: 'Show in Leaderboard',
                  subtitle: 'Display your scores in the leaderboard',
                  value: _showInLeaderboard,
                  onChanged: (value) {
                    setState(() {
                      _showInLeaderboard = value;
                    });
                  },
                ),
              ],
            ),
            _buildSection(
              title: 'Data & Privacy',
              children: [
                _buildButtonTile(
                  title: 'Download My Data',
                  subtitle: 'Get a copy of your data',
                  icon: Icons.download,
                  onTap: () {
                    // TODO: Implement data download
                  },
                ),
                _buildButtonTile(
                  title: 'Delete Account',
                  subtitle: 'Permanently delete your account and data',
                  icon: Icons.delete_forever,
                  isDestructive: true,
                  onTap: () {
                    _showDeleteAccountDialog();
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

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(GameTheme.spacingM),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: GameTheme.textColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: GameTheme.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: GameTheme.spacingXS),
          Text(
            subtitle,
            style: TextStyle(
              color: GameTheme.textColor.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: GameTheme.spacingS),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: GameTheme.spacingM,
            ),
            decoration: BoxDecoration(
              color: GameTheme.surfaceColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(GameTheme.borderRadiusMedium),
            ),
            child: DropdownButton<String>(
              value: value,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: GameTheme.textColor,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              dropdownColor: GameTheme.surfaceColor,
              underline: const SizedBox(),
              isExpanded: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
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
          color: isDestructive ? GameTheme.errorColor : GameTheme.accentColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? GameTheme.errorColor : GameTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDestructive
                ? GameTheme.errorColor.withOpacity(0.7)
                : GameTheme.textColor.withOpacity(0.7),
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

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GameTheme.surfaceColor,
        title: const Text(
          'Delete Account',
          style: TextStyle(
            color: GameTheme.errorColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
          style: TextStyle(color: GameTheme.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: GameTheme.textColor),
            ),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement account deletion
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: GameTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
