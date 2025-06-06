import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/realtime_chat_service.dart';
import 'chat_screen.dart';
import 'auth_screen.dart';
import 'create_group_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final RealtimeChatService _chatService = RealtimeChatService();

  String _getParticipantEmails(Map<String, dynamic> participants) {
    final emails = <String>[];
    for (var participant in participants.values) {
      if (participant is Map && participant['email'] != null) {
        emails.add(participant['email']);
      }
    }
    return emails.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: () async {
              final result = await Get.to(() => const CreateGroupScreen());
              if (result != null) {
                setState(() {});
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _chatService.logout();
              Get.offAll(() => const AuthScreen());
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _chatService.getGroupChatsData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final chats = snapshot.data ?? [];
          if (chats.isEmpty) {
            return const Center(
              child: Text('No group chats yet. Create a new group!'),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final participants = chat['participants'] as Map<String, dynamic>;
              final metadata = chat['metadata'] as Map<String, dynamic>?;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Icon(Icons.group, color: Colors.white),
                ),
                title: Text(chat['name']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat['lastMessage'] ?? 'No messages yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Participants: ${participants.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Get.to(() => ChatScreen(
                        chatId: chat['chatId'],
                        chatName: chat['name'],
                        chatType: 'group',
                      ));
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    if (timestamp == 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
