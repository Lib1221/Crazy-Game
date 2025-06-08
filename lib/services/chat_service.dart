// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/message.dart';

// class ChatService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   String get currentUserId => _auth.currentUser?.uid ?? '';

//   // Send a message to a chat
//   Future<void> sendMessage({
//     required String chatId,
//     required String content,
//   }) async {
//     final user = _auth.currentUser;
//     if (user == null) return;

//     final message = Message(
//       id: DateTime.now().millisecondsSinceEpoch.toString(),
//       senderId: user.uid,
//       senderName: user.displayName ?? 'Anonymous',
//       content: content,
//       timestamp: DateTime.now(),
//     );

//     await _firestore
//         .collection('chats')
//         .doc(chatId)
//         .collection('messages')
//         .doc(message.id)
//         .set(message.toMap());
//   }

//   // Get messages stream for a chat
//   Stream<List<Message>> getMessages(String chatId) {
//     return _firestore
//         .collection('chats')
//         .doc(chatId)
//         .collection('messages')
//         .orderBy('timestamp', descending: true)
//         .snapshots()
//         .map((snapshot) {
//       return snapshot.docs.map((doc) => Message.fromMap(doc.data())).toList();
//     });
//   }

//   // Create a new group chat
//   Future<String> createGroupChat(
//       String name, List<String> participantIds) async {
//     final chatRef = await _firestore.collection('chats').add({
//       'name': name,
//       'type': 'group',
//       'createdAt': FieldValue.serverTimestamp(),
//       'participants': {for (var id in participantIds) id: true},
//     });
//     return chatRef.id;
//   }

//   // Get user's chats
//   Stream<List<Map<String, dynamic>>> getUserChats() {
//     return _firestore
//         .collection('chats')
//         .where('participants.$currentUserId', isEqualTo: true)
//         .snapshots()
//         .map((snapshot) {
//       return snapshot.docs.map((doc) {
//         final data = doc.data();
//         return {
//           'id': doc.id,
//           'name': data['name'] ?? 'Unnamed Chat',
//           'type': data['type'] ?? 'direct',
//         };
//       }).toList();
//     });
//   }
// }
