import 'package:crazygame/services/realtime/realtime_chat_service.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'package:get/get.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({super.key});

  @override
  State<SearchUserScreen> createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final RealtimeChatService _chatService = RealtimeChatService();
  final TextEditingController _emailController = TextEditingController();
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;
  Map<String, dynamic>? _searchResult;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _searchUser() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _errorMessage.value = 'Please enter an email address';
      return;
    }

    try {
      _isLoading.value = true;
      _errorMessage.value = '';
      _searchResult = null;

      final user = await _chatService.searchUserByEmail(email);
      if (user != null) {
        setState(() {
          _searchResult = user;
        });
      } else {
        _errorMessage.value = 'No user found with this email';
      }
    } catch (e) {
      _errorMessage.value = 'Error searching for user: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _startChat() async {
    if (_searchResult == null) return;

    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final chatId = await _chatService.getOrCreateDirectChat(
        _searchResult!['uid'],
        _searchResult!['name'],
        _searchResult!['email'],
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatId,
              chatName: _searchResult!['name'],
            ),
          ),
        );
      }
    } catch (e) {
      _errorMessage.value = 'Error starting chat: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search User'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter user email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              onSubmitted: (_) => _searchUser(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _searchUser,
              child: const Text('Search'),
            ),
            const SizedBox(height: 24),
            Obx(() {
              if (_isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_errorMessage.value.isNotEmpty) {
                return Text(
                  _errorMessage.value,
                  style: const TextStyle(color: Colors.red),
                );
              }

              if (_searchResult != null) {
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(_searchResult!['name'][0].toUpperCase()),
                    ),
                    title: Text(_searchResult!['name']),
                    subtitle: Text(_searchResult!['email']),
                    trailing: IconButton(
                      icon: const Icon(Icons.chat),
                      onPressed: _startChat,
                      tooltip: 'Start Chat',
                    ),
                  ),
                );
              }

              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }
}
