import 'package:flutter/material.dart';
import '../theme/game_theme.dart';
import 'edit_profile_screen.dart';
import 'appearance_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Settings',
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
              title: 'Account',
              children: [
                _buildButtonTile(
                  title: 'Edit Profile',
                  subtitle: 'Update your profile information',
                  icon: Icons.person,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            _buildSection(
              title: 'Preferences',
              children: [
                _buildButtonTile(
                  title: 'Appearance',
                  subtitle: 'Customize the app\'s look and feel',
                  icon: Icons.palette,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AppearanceSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            _buildSection(
              title: 'Account Actions',
              children: [
                _buildButtonTile(
                  title: 'Logout',
                  subtitle: 'Sign out of your account',
                  icon: Icons.logout,
                  isDestructive: true,
                  onTap: () {
                    _showLogoutDialog(context);
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GameTheme.surfaceColor,
        title: const Text(
          'Logout',
          style: TextStyle(
            color: GameTheme.errorColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to logout?',
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
              Navigator.pop(context);
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: GameTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
