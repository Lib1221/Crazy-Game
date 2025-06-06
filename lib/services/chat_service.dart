import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  // Get chat messages stream
  Stream<List<Message>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
    });
  }

  // Send a message
  Future<void> sendMessage({
    required String chatId,
    required String content,
    String? imageUrl,
  }) async {
    final user = auth.currentUser;
    if (user == null) return;

    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: user.uid,
      senderName: user.displayName ?? 'Anonymous',
      content: content,
      timestamp: DateTime.now(),
      imageUrl: imageUrl,
    );

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());
  }

  // Create a new chat
  Future<String> createChat(String chatName) async {
    final chatRef = await _firestore.collection('chats').add({
      'name': chatName,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': auth.currentUser?.uid,
    });
    return chatRef.id;
  }

  // Get all chats
  Stream<QuerySnapshot> getChats() {
    return _firestore
        .collection('chats')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Search user by email
  Future<Map<String, dynamic>?> searchUserByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final userData = querySnapshot.docs.first.data();
      return {
        'uid': querySnapshot.docs.first.id,
        'email': userData['email'],
        'name': userData['name'] ?? email.split('@')[0],
      };
    } catch (e) {
      print('Error searching user: $e');
      return null;
    }
  }

  // Create or get direct chat with user
  Future<String> getOrCreateDirectChat(
      String otherUserId, String otherUserName) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    // Check if direct chat already exists
    final existingChats = await _firestore
        .collection('chats')
        .where('type', isEqualTo: 'direct')
        .where('participants', arrayContains: currentUser.uid)
        .get();

    for (var doc in existingChats.docs) {
      final data = doc.data();
      if (data['participants']?.contains(otherUserId) ?? false) {
        return doc.id;
      }
    }

    // Create new direct chat
    final chatRef = await _firestore.collection('chats').add({
      'type': 'direct',
      'name': otherUserName,
      'participants': [currentUser.uid, otherUserId],
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': currentUser.uid,
    });

    return chatRef.id;
  }
}
