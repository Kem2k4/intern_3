import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/chat_user.dart';
import '../../data/models/message.dart';
import '../../infrastructure/services/firebase_messaging_service.dart';

abstract class ChatRepository {
  Future<void> initialize();
  Future<List<ChatUser>> getUsers();
  Future<List<Message>> getChatHistory(String otherUserId);
  Future<void> sendMessage(String receiverId, String text);
  Stream<Message> get messageStream;
  Future<bool> isUserOnline(String userId);
  Future<void> dispose();
}

class ChatRepositoryImpl implements ChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseMessagingService _messagingService;

  ChatRepositoryImpl(this._firestore, this._auth, this._messagingService);

  @override
  Future<void> initialize() async {
    await _messagingService.initialize();

    // Login to RTM with current user ID
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _messagingService.login(currentUser.uid);
    }
  }

  @override
  Future<List<ChatUser>> getUsers() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      // Get all users except current user
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, isNotEqualTo: currentUser.uid)
          .get();

      // Load all last messages in parallel for better performance
      final userDocs = snapshot.docs;
      final lastMessageFutures = userDocs
          .map((doc) => _getLastMessage(currentUser.uid, doc.id))
          .toList();

      final lastMessages = await Future.wait(lastMessageFutures);

      final List<ChatUser> users = [];

      for (int i = 0; i < userDocs.length; i++) {
        final doc = userDocs[i];
        final data = doc.data() as Map<String, dynamic>;
        final lastMessage = lastMessages[i];

        // Check online status
        final statusMap = await _messagingService.queryPeerOnlineStatus([doc.id]);
        final isOnline = statusMap[doc.id] ?? false;

        users.add(
          ChatUser(
            id: doc.id,
            name: data['fullName'] ?? data['name'] ?? data['email'] ?? 'Unknown',
            email: data['email'] ?? '',
            avatar: data['avatar'] ?? 'https://i.pravatar.cc/150?u=${doc.id}',
            lastMessage: lastMessage['text'] ?? '',
            time: lastMessage['time'] ?? '',
            unreadCount: lastMessage['unreadCount'] ?? 0,
            isOnline: isOnline,
          ),
        );
      }

      // Sort by last message time (most recent first)
      users.sort((a, b) {
        // Users with messages come before users without messages
        if (a.lastMessage.isNotEmpty && b.lastMessage.isEmpty) return -1;
        if (a.lastMessage.isEmpty && b.lastMessage.isNotEmpty) return 1;
        return 0;
      });

      return users;
    } catch (e) {
      // print('❌ Error getting users: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _getLastMessage(String currentUserId, String otherUserId) async {
    try {
      // Get last message from Realtime Database
      final messages = await _messagingService.getChatHistory(otherUserId, limit: 1);

      if (messages.isEmpty) {
        return {};
      }

      final lastMsg = messages.last;

      return {
        'text': lastMsg.text,
        'time': _formatTime(lastMsg.timestamp),
        'unreadCount': 0, // TODO: Implement unread count tracking
      };
    } catch (e) {
      // print('❌ Error getting last message: $e');
      return {};
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
      return days[time.weekday % 7];
    } else {
      return '${time.day}/${time.month}';
    }
  }

  @override
  Future<List<Message>> getChatHistory(String otherUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      // Start listening to real-time messages for this conversation
      _messagingService.listenToConversation(otherUserId);

      // Load chat history from Realtime Database
      final rtmMessages = await _messagingService.getChatHistory(otherUserId);

      // Convert to Message objects
      final messages = rtmMessages.map((rtmMsg) {
        return Message(
          id: rtmMsg.timestamp.millisecondsSinceEpoch.toString(),
          senderId: rtmMsg.senderId,
          senderName: '',
          text: rtmMsg.text,
          timestamp: rtmMsg.timestamp,
          isMe: rtmMsg.senderId == currentUser.uid,
        );
      }).toList();

      return messages;
    } catch (e) {
      // print('❌ Error getting chat history: $e');
      return [];
    }
  }

  @override
  Future<void> sendMessage(String receiverId, String text) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      // Send via Firebase Realtime Database (instant real-time delivery!)
      await _messagingService.sendMessageToPeer(receiverId, text);

      // print('✅ Message sent via Realtime Database');
    } catch (e) {
      // print('❌ Error sending message: $e');
      rethrow;
    }
  }

  @override
  Stream<Message> get messageStream {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Stream.empty();
    }

    return _messagingService.messageStream.map((rtmMessage) {
      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: rtmMessage.senderId,
        senderName: '', // Will be filled by UI
        text: rtmMessage.text,
        timestamp: rtmMessage.timestamp,
        isMe: false,
      );
    });
  }

  @override
  Future<bool> isUserOnline(String userId) async {
    final statusMap = await _messagingService.queryPeerOnlineStatus([userId]);
    return statusMap[userId] ?? false;
  }

  @override
  Future<void> dispose() async {
    await _messagingService.dispose();
  }
}
