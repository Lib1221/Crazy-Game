import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'database_service.dart';
import 'user_service.dart';
import 'auth_service.dart';
import '../../logic/assigner.dart';

class ChatService {
  final DatabaseService _databaseService;
  final UserService _userService;
  final AuthService _authService;

  ChatService(this._databaseService, this._userService, this._authService);

  // Get chat messages stream with participant info
  Stream<List<Map<String, dynamic>>> getChatMessages(String chatId) {
    final user = _authService.currentUser;
    if (user == null) return Stream.value([]);

    return _databaseService.getRef('chats/$chatId').onValue.map((event) {
      try {
        if (event.snapshot.value == null) return [];

        final rawData = event.snapshot.value;
        if (rawData == null) return [];

        if (rawData is! Map) {
          return [];
        }

        final data = Map<String, dynamic>.from(rawData);
        final participants = data['participants'] as Map<String, dynamic>?;
        final messages = data['messages'] as Map<String, dynamic>?;

        if (participants == null) {
          return [];
        }

        // Get participant names
        final Map<String, String> participantNames = {};
        for (var entry in participants.entries) {
          final userId = entry.key;
          final userData = entry.value as Map<String, dynamic>?;
          if (userData != null) {
            participantNames[userId] =
                userData['name']?.toString() ?? 'Unknown';
          }
        }

        // Process messages
        final List<Map<String, dynamic>> messageList = [];
        if (messages != null) {
          for (var entry in messages.entries) {
            try {
              final messageId = entry.key;
              final messageData = entry.value as Map<String, dynamic>?;
              if (messageData == null) continue;

              final senderId = messageData['senderId']?.toString();
              if (senderId == null) continue;

              final timestamp = messageData['timestamp'];
              final timestampMillis = timestamp is num ? timestamp.toInt() : 0;

              messageList.add({
                'id': messageId,
                'senderId': senderId,
                'senderName': participantNames[senderId] ?? 'Unknown',
                'content': messageData['content']?.toString() ?? '',
                'timestamp': timestampMillis,
                'imageUrl': messageData['imageUrl']?.toString(),
                'isCurrentUser': senderId == user.uid,
              });
            } catch (e) {
              continue;
            }
          }
        }

        // Sort messages by timestamp (oldest first)
        messageList.sort(
            (a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));
        return messageList;
      } catch (e) {
        return [];
      }
    });
  }

  // Send a message to either direct or group chat
  Future<void> sendMessage({
    required String chatId,
    required String content,
    String? chatType,
  }) async {
    final user = _authService.currentUser;
    if (user == null) {
      return;
    }

    if (chatId.isEmpty) {
      return;
    }

    try {
      const timestamp = ServerValue.timestamp;
      final basePath = chatType == 'group' ? 'group_chats' : 'chats';
      final messageRef =
          _databaseService.getRef('$basePath/$chatId/messages').push();

      // Get user info for the message
      final userInfo = await _userService.getUserInfo(user.uid);
      final userName = userInfo?['name']?.toString() ?? 'Unknown';
      final userEmail = user.email?.toLowerCase() ?? '';

      // Create message object
      final message = {
        'senderId': user.uid,
        'senderName': userName,
        'senderEmail': userEmail,
        'content': content,
        'timestamp': timestamp,
        'type': 'text'
      };

      // Update both message and chat metadata
      final updates = {
        'messages/${messageRef.key}': message,
        'lastMessage': content,
        'lastMessageTime': timestamp,
        'lastMessageSender': user.uid,
      };

      if (chatType == 'group') {
        // For group chats, update in group_chats node
        updates['metadata/lastActivity'] = timestamp;
        updates['metadata/totalMessages'] = ServerValue.increment(1);
        updates['metadata/readBy/${user.uid}'] = timestamp;
        updates['participants/${user.uid}/lastActivity'] = timestamp;
        await _databaseService.getRef('group_chats/$chatId').update(updates);
      } else {
        // For direct chats, update in chats node with metadata structure
        updates['metadata/participants/${user.uid}/lastActivity'] = timestamp;
        await _databaseService.getRef('chats/$chatId').update(updates);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get messages stream for either direct or group chat
  Stream<List<Map<String, dynamic>>> getMessages(String chatId,
      {String? chatType}) {
    final user = _authService.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    if (chatId.isEmpty) {
      return Stream.value([]);
    }

    try {
      final basePath = chatType == 'group' ? 'group_chats' : 'chats';
      return _databaseService.getRef('$basePath/$chatId').onValue.map((event) {
        try {
          if (event.snapshot.value == null) return [];

          final rawData = event.snapshot.value;
          if (rawData == null) return [];

          if (rawData is! Map) {
            return [];
          }

          final data = Map<String, dynamic>.from(rawData);
          final messages = data['messages'];

          // Get participants based on chat type
          final participants = chatType == 'group'
              ? data['participants']
              : data['metadata']?['participants'];

          if (participants == null || participants is! Map) {
            return [];
          }

          // Process messages
          final List<Map<String, dynamic>> messageList = [];
          if (messages != null && messages is Map) {
            for (var entry in (messages).entries) {
              try {
                final messageId = entry.key.toString();
                final messageData = entry.value;
                if (messageData == null || messageData is! Map) continue;

                final data = Map<String, dynamic>.from(messageData);
                final senderId = data['senderId']?.toString();
                if (senderId == null) continue;

                final timestamp = data['timestamp'];
                final timestampMillis =
                    timestamp is num ? timestamp.toInt() : 0;

                messageList.add({
                  'id': messageId,
                  'senderId': senderId,
                  'senderName': data['senderName']?.toString() ?? 'Unknown',
                  'senderEmail': data['senderEmail']?.toString() ?? '',
                  'text': data['content']?.toString() ?? '',
                  'type': data['type']?.toString() ?? 'text',
                  'timestamp': timestampMillis,
                  'isCurrentUser': senderId == user.uid,
                });
              } catch (e) {}
            }
          }

          // Sort messages by timestamp (oldest first)
          messageList.sort((a, b) =>
              (a['timestamp'] as int).compareTo(b['timestamp'] as int));
          return messageList;
        } catch (e) {
          return [];
        }
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  // Get user's chats
  Stream<List<Map<String, dynamic>>> getUserChats() {
    final user = _authService.currentUser;
    if (user == null) return Stream.value([]);

    final userEmail = user.email?.toLowerCase();
    if (userEmail == null) return Stream.value([]);

    try {
      return _databaseService.getRef('group_chats').onValue.map((event) {
        try {
          if (event.snapshot.value == null) return [];

          final rawData = event.snapshot.value;
          if (rawData == null) return [];

          if (rawData is! Map) {
            return [];
          }

          final data = Map<String, dynamic>.from(rawData);
          final chats = <Map<String, dynamic>>[];

          // First process group chats
          final groupChats = data['group_chats'] as Map<String, dynamic>? ?? {};
          for (var entry in groupChats.entries) {
            try {
              final chatId = entry.key;
              final chatData = entry.value;
              if (chatData == null || chatData is! Map) continue;

              // Get participants data
              final participants =
                  chatData['participants'] as Map<String, dynamic>?;
              if (participants == null) continue;

              // Check if user's email matches any participant's email
              bool isUserInGroup = false;
              List<String> participantEmails = [];

              for (var participant in participants.values) {
                if (participant is Map) {
                  final participantEmail =
                      participant['email']?.toString().toLowerCase();
                  if (participantEmail != null) {
                    participantEmails.add(participantEmail);
                    if (participantEmail == userEmail) {
                      isUserInGroup = true;
                    }
                  }
                }
              }

              // Only add to chat list if user is a participant
              if (isUserInGroup) {
                final metadata = chatData['metadata'] as Map<String, dynamic>?;
                chats.add({
                  'chatId': chatId,
                  'name': metadata?['name']?.toString() ?? 'Unknown Group',
                  'type': 'group',
                  'lastMessage': chatData['lastMessage']?.toString() ?? '',
                  'lastMessageTime': chatData['lastMessageTime'],
                  'participants': participants,
                  'participantEmails': participantEmails,
                });
              }
            } catch (e) {
              continue;
            }
          }

          // Then process direct chats
          final directChats = data['chats'] as Map<String, dynamic>? ?? {};
          for (var entry in directChats.entries) {
            try {
              final chatId = entry.key;
              final chatData = entry.value;
              if (chatData == null || chatData is! Map) continue;

              final participants =
                  chatData['participants'] as Map<String, dynamic>?;
              if (participants == null || !participants.containsKey(user.uid)) {
                continue;
              }

              // Get other participant's info
              final otherParticipant = participants.entries.firstWhere(
                (p) => p.key != user.uid,
                orElse: () => participants.entries.first,
              );

              final otherUserData =
                  otherParticipant.value as Map<String, dynamic>?;
              if (otherUserData == null) continue;

              chats.add({
                'chatId': chatId,
                'name': otherUserData['name']?.toString() ?? 'Unknown',
                'type': 'direct',
                'lastMessage': chatData['lastMessage']?.toString() ?? '',
                'lastMessageTime': chatData['lastMessageTime'],
                'participants': participants,
                'participantEmails': [
                  otherUserData['email']?.toString().toLowerCase() ?? ''
                ],
              });
            } catch (e) {}
          }

          // Sort chats by last message time (newest first)
          chats.sort((a, b) {
            final timeA = a['lastMessageTime'] as int? ?? 0;
            final timeB = b['lastMessageTime'] as int? ?? 0;
            return timeB.compareTo(timeA);
          });

          return chats;
        } catch (e) {
          return [];
        }
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId, {String? chatType}) async {
    final user = _authService.currentUser;
    if (user == null) return;

    final basePath = chatType == 'group' ? 'group_chats' : 'chats';
    final readPath = chatType == 'group'
        ? '$basePath/$chatId/metadata/readBy/${user.uid}'
        : '$basePath/$chatId/metadata/participants/${user.uid}/lastRead';

    await _databaseService.getRef(readPath).set(ServerValue.timestamp);
  }

  // Get unread message count
  Stream<int> getUnreadMessageCount(String chatId, {String? chatType}) {
    final user = _authService.currentUser;
    if (user == null) return Stream.value(0);

    final basePath = chatType == 'group' ? 'group_chats' : 'chats';
    final metadataPath = chatType == 'group'
        ? '$basePath/$chatId/metadata'
        : '$basePath/$chatId/metadata/participants/${user.uid}';

    return _databaseService.getRef(metadataPath).onValue.map((event) {
      if (event.snapshot.value == null) return 0;

      final rawData = event.snapshot.value;
      if (rawData == null) return 0;

      final data = Map<String, dynamic>.from(rawData as Map);
      final lastMessageTime = data['lastMessageTime'] as int? ?? 0;
      final lastRead = chatType == 'group'
          ? (data['readBy']?[user.uid] as int? ?? 0)
          : (data['lastRead'] as int? ?? 0);

      return lastMessageTime > lastRead ? 1 : 0;
    });
  }

  // Create or get direct chat
  Future<String> getOrCreateDirectChat(
      String otherUserId, String otherUserName, String otherUserEmail) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    // Create a unique chat ID for the two users
    final chatId = [currentUser.uid, otherUserId]..sort();
    final chatRef =
        _databaseService.getRef().child('chats/${chatId.join('_')}');

    // Check if chat already exists
    final chatSnapshot = await chatRef.get();
    if (!chatSnapshot.exists) {
      // Get current user's email
      final currentUserEmail = currentUser.email ?? '';

      // Create new chat
      await chatRef.set({
        'participants': {
          currentUser.uid: {
            'name': currentUser.displayName ?? 'Unknown',
            'email': currentUserEmail,
          },
          otherUserId: {
            'name': otherUserName,
            'email': otherUserEmail,
          },
        },
        'createdAt': ServerValue.timestamp,
        'lastMessage': null,
        'lastMessageTime': null,
        'lastMessageSender': null,
      });
    }

    return chatId.join('_');
  }

  // Create a new group chat
  Future<String> createGroupChat({
    required String groupName,
    required List<String> participantEmails,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    // Get current user's email
    final currentUserEmail = currentUser.email?.toLowerCase();
    if (currentUserEmail == null) throw Exception('User email not found');

    // Create group chat document in group_chats node
    final groupChatRef = _databaseService.getRef('group_chats').push();
    final groupChatId = groupChatRef.key!;

    // Add current user as admin
    final participants = {
      currentUser.uid: {
        'name': currentUser.displayName ?? 'Unknown',
        'email': currentUserEmail,
        'role': 'admin',
        'joinedAt': ServerValue.timestamp,
        'lastActivity': ServerValue.timestamp,
        'lastRead': ServerValue.timestamp,
        'isReady': false,
      }
    };

    // Add other participants
    for (final email in participantEmails) {
      final userData = await _userService.searchUserByEmail(email);
      if (userData != null) {
        participants[userData['uid']] = {
          'name': userData['name'],
          'email': email.toLowerCase(),
          'role': 'member',
          'joinedAt': ServerValue.timestamp,
          'lastActivity': ServerValue.timestamp,
          'lastRead': ServerValue.timestamp,
          'isReady': false,
        };
      }
    }

    // Create turn order with all participants
    final turnOrder = participants.keys.toList();
    const currentTurnIndex = 0;
    final currentTurnUserId = turnOrder[currentTurnIndex];

    // Create the group chat with all necessary data
    await groupChatRef.set({
      'createdAt': ServerValue.timestamp,
      'createdBy': currentUser.uid,
      'type': 'group',
      'participants': participants,
      'metadata': {
        'name': groupName,
        'isActive': true,
        'totalMessages': 0,
        'lastActivity': ServerValue.timestamp,
        'readBy': {
          currentUser.uid: ServerValue.timestamp,
        }
      },
      'messages': {},
      'turn': {
        'currentTurnUserId': currentTurnUserId,
        'currentTurnIndex': currentTurnIndex,
        'turnOrder': turnOrder,
        'lastUpdated': ServerValue.timestamp,
      },
      'game': {
        'selectedNumbers': [],
        'numberSelectors': [],
        'userNumbers': {},
        'lastUpdated': ServerValue.timestamp,
      },
      'gameStart': {
        'isStarted': false,
        'readyUsers': {},
        'startTime': null,
      },
      'turnTimer': {
        'startTime': null,
        'currentTurnUserId': null,
      }
    });

    // Assign numbers to participants
    final numberAssigner = NumberAssigner(chatId: groupChatId);
    await numberAssigner.assignNumbersToParticipants(turnOrder);

    // Also create a reference in the user's chats
    for (final participant in participants.entries) {
      final userId = participant.key;
      await _databaseService.getRef('users/$userId/chats/$groupChatId').set({
        'type': 'group',
        'name': groupName,
        'joinedAt': ServerValue.timestamp,
        'role': participant.value['role'],
        'lastActivity': ServerValue.timestamp,
        'lastRead': ServerValue.timestamp,
      });
    }

    return groupChatId;
  }

  // Get group chat info
  Future<Map<String, dynamic>> getGroupChatInfo(String groupChatId) async {
    try {
      final snapshot =
          await _databaseService.getRef('group_chats/$groupChatId').get();
      if (!snapshot.exists || snapshot.value == null) {
        throw Exception('Group chat not found');
      }

      final rawData = snapshot.value;
      if (rawData == null || rawData is! Map) {
        throw Exception('Invalid group chat data');
      }

      final data = Map<String, dynamic>.from(rawData);
      final metadata = data['metadata'] as Map<String, dynamic>?;
      final participants = data['participants'] as Map<String, dynamic>?;

      if (metadata == null || participants == null) {
        throw Exception('Invalid group chat structure');
      }

      return {
        'chatId': groupChatId,
        'name': metadata['name']?.toString() ??
            'Unknown Group', // Read name from metadata
        'type': data['type']?.toString() ?? 'group',
        'createdAt': data['createdAt'],
        'createdBy': data['createdBy']?.toString(),
        'participants': participants,
        'isActive': metadata['isActive'] ?? true,
        'totalMessages': metadata['totalMessages'] ?? 0,
        'lastActivity': metadata['lastActivity'],
        'lastMessage': data['lastMessage']?.toString(),
        'lastMessageTime': data['lastMessageTime'],
        'lastMessageSender': data['lastMessageSender']?.toString(),
        'readBy': metadata['readBy']
      };
    } catch (e) {
      rethrow;
    }
  }

  // Get user's group chats
  Stream<List<Map<String, dynamic>>> getUserGroupChats() {
    final user = _authService.currentUser;
    if (user == null) return Stream.value([]);

    return _databaseService
        .getRef('users/${user.uid}/chats')
        .onValue
        .map((event) {
      try {
        if (event.snapshot.value == null) return [];

        final rawData = event.snapshot.value;
        if (rawData == null) return [];

        if (rawData is! Map) {
          return [];
        }

        final chatsMap = Map<String, dynamic>.from(rawData);
        final groupChats = <Map<String, dynamic>>[];

        for (var entry in chatsMap.entries) {
          try {
            final chatId = entry.key;
            final chatData = entry.value;
            if (chatData == null || chatData is! Map) continue;

            final data = Map<String, dynamic>.from(chatData);
            if (data['type'] != 'group') continue;

            groupChats.add({
              'chatId': chatId,
              'name': data['name'] ?? 'Unknown Group',
              'type': 'group',
              'role': data['role'] ?? 'member',
              'joinedAt': data['joinedAt'],
            });
          } catch (e) {
            continue;
          }
        }

        // Sort by joinedAt (newest first)
        groupChats.sort((a, b) {
          final timeA = a['joinedAt'] as int? ?? 0;
          final timeB = b['joinedAt'] as int? ?? 0;
          return timeB.compareTo(timeA);
        });

        return groupChats;
      } catch (e) {
        return [];
      }
    });
  }

  // Add participant to group chat
  Future<void> addParticipantToGroup({
    required String groupChatId,
    required String email,
  }) async {
    final userData = await _userService.searchUserByEmail(email);
    if (userData == null) throw Exception('User not found');

    await _databaseService
        .getRef('chats/$groupChatId/participants/${userData['id']}')
        .set({
      'name': userData['name'],
      'email': email,
      'role': 'member',
      'joinedAt': ServerValue.timestamp,
    });
  }

  // Remove participant from group chat
  Future<void> removeParticipantFromGroup({
    required String groupChatId,
    required String userId,
  }) async {
    await _databaseService
        .getRef('chats/$groupChatId/participants/$userId')
        .remove();
  }

  // Get group chat participants
  Future<Map<String, dynamic>> getGroupParticipants(String groupChatId) async {
    try {
      // Read participants from the root level as shown in the image
      final snapshot = await _databaseService
          .getRef('group_chats/$groupChatId/participants')
          .get();
      if (!snapshot.exists || snapshot.value == null) {
        // Throw a more specific exception for group chats
        throw Exception(
            'Group chat participants not found or invalid data for chat ID: $groupChatId');
      }

      final rawData = snapshot.value;
      if (rawData == null || rawData is! Map) {
        throw Exception(
            'Invalid group chat participants data for chat ID: $groupChatId');
      }

      return Map<String, dynamic>.from(rawData);
    } catch (e) {
      rethrow;
    }
  }

  // Update group chat name
  Future<void> updateGroupName({
    required String groupChatId,
    required String newName,
  }) async {
    await _databaseService.getRef('chats/$groupChatId').update({
      'name': newName,
    });
  }

  // Get chat info
  Future<Map<String, dynamic>> getChatInfo(String chatId) async {
    try {
      final snapshot = await _databaseService.getRef('chats/$chatId').get();
      if (!snapshot.exists || snapshot.value == null) {
        throw Exception('Chat not found');
      }

      final rawData = snapshot.value;
      if (rawData == null || rawData is! Map) {
        throw Exception('Invalid chat data');
      }

      return Map<String, dynamic>.from(rawData);
    } catch (e) {
      rethrow;
    }
  }

  // Get only group chats data
  Stream<List<Map<String, dynamic>>> getGroupChatsData() {
    final user = _authService.currentUser;
    if (user == null) return Stream.value([]);

    final userEmail = user.email?.toLowerCase();
    if (userEmail == null) return Stream.value([]);

    try {
      return _databaseService.getRef('group_chats').onValue.map((event) {
        try {
          if (event.snapshot.value == null) return [];

          final rawData = event.snapshot.value;
          if (rawData == null) return [];

          if (rawData is! Map) {
            return [];
          }

          final data = Map<String, dynamic>.from(rawData);
          final groupChats = <Map<String, dynamic>>[];

          // Process each group chat
          for (var entry in data.entries) {
            try {
              final chatId = entry.key;
              final chatData = entry.value;
              if (chatData == null || chatData is! Map) continue;

              // Get participants data
              final participants =
                  chatData['participants'] as Map<String, dynamic>?;
              if (participants == null) continue;

              // Check if user's email matches any participant's email
              bool isUserInGroup = false;
              List<String> participantEmails = [];
              Map<String, dynamic> participantDetails = {};

              for (var participant in participants.entries) {
                final participantData = participant.value;
                if (participantData is Map) {
                  final participantEmail =
                      participantData['email']?.toString().toLowerCase();
                  if (participantEmail != null) {
                    participantEmails.add(participantEmail);
                    participantDetails[participant.key] = {
                      'name': participantData['name'],
                      'email': participantEmail,
                      'role': participantData['role'],
                      'joinedAt': participantData['joinedAt'],
                      'lastActivity': participantData['lastActivity'],
                      'lastRead': participantData['lastRead'],
                    };
                    if (participantEmail == userEmail) {
                      isUserInGroup = true;
                    }
                  }
                }
              }

              // Only add to chat list if user is a participant
              if (isUserInGroup) {
                final metadata = chatData['metadata'] as Map<String, dynamic>?;
                final messages = chatData['messages'] as Map<String, dynamic>?;

                groupChats.add({
                  'chatId': chatId,
                  'name': metadata?['name']?.toString() ?? 'Unknown Group',
                  'type': 'group',
                  'createdAt': chatData['createdAt'],
                  'createdBy': chatData['createdBy'],
                  'lastMessage': chatData['lastMessage']?.toString() ?? '',
                  'lastMessageTime': chatData['lastMessageTime'],
                  'lastMessageSender': chatData['lastMessageSender'],
                  'metadata': metadata,
                  'participants': participantDetails,
                  'participantEmails': participantEmails,
                  'messages': messages,
                });
              }
            } catch (e) {
              continue;
            }
          }

          // Sort chats by last message time (newest first)
          groupChats.sort((a, b) {
            final timeA = a['lastMessageTime'] as int? ?? 0;
            final timeB = b['lastMessageTime'] as int? ?? 0;
            return timeB.compareTo(timeA);
          });

          return groupChats;
        } catch (e) {
          return [];
        }
      });
    } catch (e) {
      return Stream.value([]);
    }
  }
}
