import 'package:crazygame/services/realtime/realtime_chat_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/game_theme.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _groupNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _chatService = RealtimeChatService();
  final List<Map<String, dynamic>> _participants = [];
  bool _isLoading = false;
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  String? _errorMessage;

  @override
  void dispose() {
    _groupNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String email) async {
    if (email.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final results = await _chatService.searchUsers(email);
      setState(() {
        _searchResults = results;
        _isSearching = false;
        if (results.isEmpty) {
          _errorMessage = 'No users found with this email';
        }
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _errorMessage = 'Failed to search users: $e';
      });
    }
  }

  void _addParticipant(Map<String, dynamic> user) {
    if (!_participants.any((p) => p['email'] == user['email'])) {
      setState(() {
        _participants.add(user);
        _emailController.clear();
        _searchResults = [];
        _errorMessage = null;
      });
    } else {
      setState(() {
        _errorMessage = 'User already added to the group';
      });
    }
  }

  void _removeParticipant(String email) {
    setState(() {
      _participants.removeWhere((p) => p['email'] == email);
    });
  }

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a group name';
      });
      return;
    }

    if (_participants.isEmpty) {
      setState(() {
        _errorMessage = 'Please add at least one participant';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final groupChatId = await _chatService.createGroupChat(
        groupName: groupName,
        participantEmails:
            _participants.map((p) => p['email'] as String).toList(),
      );
      Get.back(result: groupChatId);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create group: $e';
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
        title: const Text(
          'Create Game Room',
          style: TextStyle(
            color: GameTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GameTheme.textColor),
          onPressed: () => Get.back(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(GameTheme.accentColor),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: GameTheme.primaryGradient,
              ),
              child: Padding(
                padding: const EdgeInsets.all(GameTheme.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: GameTheme.surfaceColor.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(GameTheme.borderRadiusLarge),
                        border: Border.all(
                          color: GameTheme.accentColor.withOpacity(0.2),
                        ),
                      ),
                      padding: const EdgeInsets.all(GameTheme.spacingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Room Details',
                            style: TextStyle(
                              color: GameTheme.textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: GameTheme.spacingM),
                          TextFormField(
                            controller: _groupNameController,
                            style: const TextStyle(color: GameTheme.textColor),
                            decoration: InputDecoration(
                              labelText: 'Room Name',
                              labelStyle: TextStyle(
                                  color: GameTheme.textColor.withOpacity(0.7)),
                              prefixIcon: const Icon(Icons.sports_esports,
                                  color: GameTheme.accentColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    GameTheme.borderRadiusMedium),
                                borderSide: BorderSide(
                                    color:
                                        GameTheme.accentColor.withOpacity(0.2)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    GameTheme.borderRadiusMedium),
                                borderSide: BorderSide(
                                    color:
                                        GameTheme.accentColor.withOpacity(0.2)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    GameTheme.borderRadiusMedium),
                                borderSide: const BorderSide(
                                    color: GameTheme.accentColor),
                              ),
                              filled: true,
                              fillColor:
                                  GameTheme.surfaceColor.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: GameTheme.spacingL),
                    Container(
                      decoration: BoxDecoration(
                        color: GameTheme.surfaceColor.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(GameTheme.borderRadiusLarge),
                        border: Border.all(
                          color: GameTheme.accentColor.withOpacity(0.2),
                        ),
                      ),
                      padding: const EdgeInsets.all(GameTheme.spacingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add Players',
                            style: TextStyle(
                              color: GameTheme.textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: GameTheme.spacingM),
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(color: GameTheme.textColor),
                            decoration: InputDecoration(
                              labelText: 'Search by Email',
                              labelStyle: TextStyle(
                                  color: GameTheme.textColor.withOpacity(0.7)),
                              prefixIcon: const Icon(Icons.search,
                                  color: GameTheme.accentColor),
                              hintText: 'Enter email to search players',
                              hintStyle: TextStyle(
                                  color: GameTheme.textColor.withOpacity(0.5)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    GameTheme.borderRadiusMedium),
                                borderSide: BorderSide(
                                    color:
                                        GameTheme.accentColor.withOpacity(0.2)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    GameTheme.borderRadiusMedium),
                                borderSide: BorderSide(
                                    color:
                                        GameTheme.accentColor.withOpacity(0.2)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    GameTheme.borderRadiusMedium),
                                borderSide: const BorderSide(
                                    color: GameTheme.accentColor),
                              ),
                              filled: true,
                              fillColor:
                                  GameTheme.surfaceColor.withOpacity(0.1),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            onChanged: _searchUsers,
                          ),
                          if (_isSearching)
                            const Padding(
                              padding: EdgeInsets.all(GameTheme.spacingM),
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      GameTheme.accentColor),
                                ),
                              ),
                            ),
                          if (_errorMessage != null)
                            Container(
                              margin: const EdgeInsets.only(
                                  top: GameTheme.spacingM),
                              padding: const EdgeInsets.all(GameTheme.spacingM),
                              decoration: BoxDecoration(
                                color: GameTheme.errorColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                    GameTheme.borderRadiusMedium),
                                border: Border.all(
                                    color:
                                        GameTheme.errorColor.withOpacity(0.2)),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                    color: GameTheme.errorColor),
                              ),
                            ),
                          if (_searchResults.isNotEmpty) ...[
                            const SizedBox(height: GameTheme.spacingM),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 200),
                              decoration: BoxDecoration(
                                color: GameTheme.surfaceColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                    GameTheme.borderRadiusMedium),
                                border: Border.all(
                                    color:
                                        GameTheme.accentColor.withOpacity(0.2)),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _searchResults.length,
                                itemBuilder: (context, index) {
                                  final user = _searchResults[index];
                                  return ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(
                                          GameTheme.spacingS),
                                      decoration: BoxDecoration(
                                        color: GameTheme.accentColor
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(
                                            GameTheme.borderRadiusMedium),
                                      ),
                                      child: Text(
                                        user['name'][0].toUpperCase(),
                                        style: const TextStyle(
                                          color: GameTheme.textColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      user['name'],
                                      style: const TextStyle(
                                          color: GameTheme.textColor),
                                    ),
                                    subtitle: Text(
                                      user['email'],
                                      style: TextStyle(
                                          color: GameTheme.textColor
                                              .withOpacity(0.7)),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.add_circle,
                                          color: GameTheme.accentColor),
                                      onPressed: () => _addParticipant(user),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_participants.isNotEmpty) ...[
                      const SizedBox(height: GameTheme.spacingL),
                      Container(
                        decoration: BoxDecoration(
                          color: GameTheme.surfaceColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                              GameTheme.borderRadiusLarge),
                          border: Border.all(
                            color: GameTheme.accentColor.withOpacity(0.2),
                          ),
                        ),
                        padding: const EdgeInsets.all(GameTheme.spacingM),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected Players',
                              style: TextStyle(
                                color: GameTheme.textColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: GameTheme.spacingM),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _participants.length,
                                itemBuilder: (context, index) {
                                  final participant = _participants[index];
                                  return Container(
                                    margin: const EdgeInsets.only(
                                        bottom: GameTheme.spacingS),
                                    decoration: BoxDecoration(
                                      color: GameTheme.surfaceColor
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(
                                          GameTheme.borderRadiusMedium),
                                      border: Border.all(
                                        color: GameTheme.accentColor
                                            .withOpacity(0.2),
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: Container(
                                        padding: const EdgeInsets.all(
                                            GameTheme.spacingS),
                                        decoration: BoxDecoration(
                                          color: GameTheme.accentColor
                                              .withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                              GameTheme.borderRadiusMedium),
                                        ),
                                        child: Text(
                                          participant['name'][0].toUpperCase(),
                                          style: const TextStyle(
                                            color: GameTheme.textColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        participant['name'],
                                        style: const TextStyle(
                                            color: GameTheme.textColor),
                                      ),
                                      subtitle: Text(
                                        participant['email'],
                                        style: TextStyle(
                                            color: GameTheme.textColor
                                                .withOpacity(0.7)),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.remove_circle,
                                            color: GameTheme.errorColor),
                                        onPressed: () => _removeParticipant(
                                            participant['email']),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: GameTheme.spacingL),
                    ElevatedButton(
                      onPressed: _createGroup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GameTheme.accentColor,
                        padding: const EdgeInsets.symmetric(
                            vertical: GameTheme.spacingM),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              GameTheme.borderRadiusMedium),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Create Game Room',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: GameTheme.textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
