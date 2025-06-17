import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/game_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  String _selectedAvatar = 'default';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: GameTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text(
              'Save',
              style: TextStyle(
                color: GameTheme.accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: GameTheme.primaryGradient,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(GameTheme.spacingM),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildAvatarSection(),
                const SizedBox(height: GameTheme.spacingL),
                _buildFormSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: GameTheme.primaryGradient,
                border: Border.all(
                  color: GameTheme.accentColor,
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  _getAvatarIcon(_selectedAvatar),
                  size: 60,
                  color: GameTheme.textColor,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GameTheme.accentColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: GameTheme.textColor,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: GameTheme.spacingM),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (context, index) {
              final avatar = 'avatar_${index + 1}';
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAvatar = avatar;
                  });
                },
                child: Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.symmetric(
                      horizontal: GameTheme.spacingS),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: GameTheme.primaryGradient,
                    border: Border.all(
                      color: _selectedAvatar == avatar
                          ? GameTheme.accentColor
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _getAvatarIcon(avatar),
                      color: GameTheme.textColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getAvatarIcon(String avatar) {
    final icons = {
      'default': Icons.person,
      'avatar_1': Icons.face,
      'avatar_2': Icons.emoji_emotions,
      'avatar_3': Icons.sentiment_satisfied,
      'avatar_4': Icons.sentiment_very_satisfied,
      'avatar_5': Icons.sentiment_neutral,
    };
    return icons[avatar] ?? Icons.person;
  }

  Widget _buildFormSection() {
    return Column(
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Display Name',
          icon: Icons.person,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
        const SizedBox(height: GameTheme.spacingM),
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!value.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: GameTheme.spacingM),
        _buildTextField(
          controller: _bioController,
          label: 'Bio',
          icon: Icons.description,
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your bio';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: GameTheme.surfaceColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(GameTheme.borderRadiusMedium),
        border: Border.all(
          color: GameTheme.textColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: GameTheme.textColor),
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: GameTheme.textColor.withOpacity(0.7)),
          prefixIcon: Icon(icon, color: GameTheme.accentColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(GameTheme.spacingM),
        ),
        validator: validator,
      ),
    );
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      Get.back();
    }
  }
}
