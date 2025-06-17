import 'package:flutter/material.dart';
import '../theme/game_theme.dart';

class AppearanceSettingsScreen extends StatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  State<AppearanceSettingsScreen> createState() =>
      _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen> {
  String _selectedTheme = 'Dark';
  String _selectedFontSize = 'Medium';
  bool _reduceMotion = false;
  bool _highContrast = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Appearance',
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
              title: 'Theme',
              children: [
                _buildThemeSelector(),
              ],
            ),
            _buildSection(
              title: 'Text Size',
              children: [
                _buildFontSizeSelector(),
              ],
            ),
            _buildSection(
              title: 'Accessibility',
              children: [
                _buildSwitchTile(
                  title: 'Reduce Motion',
                  subtitle: 'Minimize animations throughout the app',
                  value: _reduceMotion,
                  onChanged: (value) {
                    setState(() {
                      _reduceMotion = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  title: 'High Contrast',
                  subtitle: 'Increase contrast for better visibility',
                  value: _highContrast,
                  onChanged: (value) {
                    setState(() {
                      _highContrast = value;
                    });
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

  Widget _buildThemeSelector() {
    return Padding(
      padding: const EdgeInsets.all(GameTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Theme',
            style: TextStyle(
              color: GameTheme.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: GameTheme.spacingS),
          Wrap(
            spacing: GameTheme.spacingS,
            runSpacing: GameTheme.spacingS,
            children: [
              _buildThemeOption('Dark', Icons.dark_mode),
              _buildThemeOption('Light', Icons.light_mode),
              _buildThemeOption('System', Icons.settings_suggest),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String theme, IconData icon) {
    final isSelected = _selectedTheme == theme;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTheme = theme;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: GameTheme.spacingM,
          vertical: GameTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? GameTheme.accentColor
              : GameTheme.surfaceColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(GameTheme.borderRadiusMedium),
          border: Border.all(
            color: isSelected
                ? GameTheme.accentColor
                : GameTheme.textColor.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : GameTheme.textColor,
              size: 20,
            ),
            const SizedBox(width: GameTheme.spacingS),
            Text(
              theme,
              style: TextStyle(
                color: isSelected ? Colors.white : GameTheme.textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSizeSelector() {
    return Padding(
      padding: const EdgeInsets.all(GameTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Text Size',
            style: TextStyle(
              color: GameTheme.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: GameTheme.spacingS),
          Row(
            children: [
              Expanded(
                child: _buildFontSizeOption('Small', 14),
              ),
              const SizedBox(width: GameTheme.spacingS),
              Expanded(
                child: _buildFontSizeOption('Medium', 16),
              ),
              const SizedBox(width: GameTheme.spacingS),
              Expanded(
                child: _buildFontSizeOption('Large', 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFontSizeOption(String size, double fontSize) {
    final isSelected = _selectedFontSize == size;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFontSize = size;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: GameTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? GameTheme.accentColor
              : GameTheme.surfaceColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(GameTheme.borderRadiusMedium),
          border: Border.all(
            color: isSelected
                ? GameTheme.accentColor
                : GameTheme.textColor.withOpacity(0.1),
          ),
        ),
        child: Text(
          'Aa',
          style: TextStyle(
            color: isSelected ? Colors.white : GameTheme.textColor,
            fontSize: fontSize,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
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
}
