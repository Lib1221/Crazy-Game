import 'package:flutter/material.dart';
import '../services/realtime_chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String chatName;
  final String? chatType;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    this.chatType,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final RealtimeChatService _chatService = RealtimeChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Map<String, dynamic>? _participantInfo;
  Map<String, dynamic>? _groupInfo;
  bool _isGroupChat = false;

  @override
  void initState() {
    super.initState();
    _loadChatInfo();
    _markMessagesAsRead();
  }

  Future<void> _loadChatInfo() async {
    try {
      final chatData = await _chatService.getChatInfo(widget.chatId);
      _isGroupChat = chatData['type'] == 'group';

      // Print all group chat data in a structured format
      print('\n========== GROUP CHAT DETAILS ==========');
      print('Chat ID: ${widget.chatId}');
      print('Chat Type: ${chatData['type']}');
      print('\n--- Basic Information ---');
      print('Name: ${chatData['name']}');
      print('Created At: ${chatData['createdAt']}');
      print('Created By: ${chatData['createdBy']}');
      print('Last Message: ${chatData['lastMessage']}');
      print('Last Message Time: ${chatData['lastMessageTime']}');
      print('Last Message Sender: ${chatData['lastMessageSender']}');

      if (_isGroupChat) {
        final participants =
            await _chatService.getGroupParticipants(widget.chatId);

        print('\n--- Metadata Information ---');
        final metadata = chatData['metadata'] as Map<String, dynamic>?;
        if (metadata != null) {
          print('Group Name: ${metadata['name']}');
          print('Is Active: ${metadata['isActive']}');
          print('Total Messages: ${metadata['totalMessages']}');
          print('Last Activity: ${metadata['lastActivity']}');
          print('Read By: ${metadata['readBy']}');
        }

        print('\n--- Participants Information ---');
        print('Total Participants: ${participants.length}');

        participants.forEach((userId, participantData) {
          print('\nParticipant Details:');
          print('  ID: $userId');
          print('  Name: ${participantData['name']}');
          print('  Email: ${participantData['email']}');
          print('  Role: ${participantData['role']}');
          print('  Joined At: ${participantData['joinedAt']}');
          print('  Last Activity: ${participantData['lastActivity']}');
          print('  Last Read: ${participantData['lastRead']}');
        });

        // Print messages if available
        final messages = chatData['messages'] as Map<String, dynamic>?;
        if (messages != null && messages.isNotEmpty) {
          print('\n--- Recent Messages ---');
          messages.forEach((messageId, messageData) {
            print('\nMessage ID: $messageId');
            print('  Sender ID: ${messageData['senderId']}');
            print('  Sender Name: ${messageData['senderName']}');
            print('  Sender Email: ${messageData['senderEmail']}');
            print('  Content: ${messageData['content']}');
            print('  Timestamp: ${messageData['timestamp']}');
            print('  Type: ${messageData['type']}');
          });
        }

        if (mounted) {
          setState(() {
            _groupInfo = {
              'name': chatData['name'],
              'participants': participants,
            };
          });
        }
      } else {
        final info = await _chatService.getChatParticipantInfo(widget.chatId);
        print('\n--- Direct Chat Information ---');
        print('Participant ID: ${info['id']}');
        print('Name: ${info['name']}');
        print('Online Status: ${info['isOnline']}');
        print('Last Login: ${info['lastLogin']}');

        if (mounted) {
          setState(() {
            _participantInfo = info;
          });
        }
      }
      print('\n========== END OF CHAT DETAILS ==========\n');
    } catch (e) {
      print('Error loading chat info: $e');
    }
  }

  Future<void> _markMessagesAsRead() async {
    await _chatService.markMessagesAsRead(
      widget.chatId,
      chatType: _isGroupChat ? 'group' : null,
    );
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _chatService.sendMessage(
      chatId: widget.chatId,
      content: message,
      chatType: _isGroupChat ? 'group' : null,
    );

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _showAddParticipantDialog() async {
    final TextEditingController emailController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Participant'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'Enter participant\'s email',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isNotEmpty) {
                try {
                  await _chatService.addParticipantToGroup(
                    groupChatId: widget.chatId,
                    email: email,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Participant added successfully')),
                    );
                    _loadChatInfo(); // Refresh participants list
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding participant: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showParticipantsList() {
    if (!_isGroupChat || _groupInfo == null) return;

    final participants = _groupInfo!['participants'] as Map<String, dynamic>;
    final participantList = participants.entries.toList();

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Participants',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: _showAddParticipantDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: participantList.length,
                itemBuilder: (context, index) {
                  final participant = participantList[index];
                  final isAdmin = participant.value['role'] == 'admin';

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(participant.value['name'][0].toUpperCase()),
                    ),
                    title: Text(participant.value['name']),
                    subtitle: Text(participant.value['email']),
                    trailing: isAdmin
                        ? const Chip(
                            label: Text('Admin'),
                            backgroundColor: Colors.blue,
                            labelStyle: TextStyle(color: Colors.white),
                          )
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String displayName = _isGroupChat
        ? (_groupInfo?['name'] as String? ?? widget.chatName)
        : (_participantInfo?['name'] as String? ?? widget.chatName);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(displayName),
            if (!_isGroupChat && _participantInfo?['isOnline'] == true)
              const Text(
                'Online',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                ),
              ),
          ],
        ),
        actions: [
          if (_isGroupChat)
            IconButton(
              icon: const Icon(Icons.people),
              onPressed: _showParticipantsList,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getMessages(
                widget.chatId,
                chatType: _isGroupChat ? 'group' : null,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Start the conversation!'),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isCurrentUser = message['isCurrentUser'] ?? false;

                    return Align(
                      alignment: isCurrentUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrentUser
                              ? Colors.blue[100]
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: isCurrentUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (!isCurrentUser)
                              Text(
                                message['senderName'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            Text(message['text'] ?? ''),
                            Text(
                              _formatTimestamp(message['timestamp']),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
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
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
