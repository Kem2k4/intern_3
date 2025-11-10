import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

/// Firebase-based messaging service using Realtime Database for instant messaging
/// Uses Realtime Database for real-time messages and Firestore for user data
class FirebaseMessagingService {
  final FirebaseFirestore _firestore;
  final FirebaseDatabase _realtimeDb;
  String? _currentUserId;

  final StreamController<RTMMessage> _messageController = StreamController<RTMMessage>.broadcast();
  final Map<String, StreamSubscription> _conversationSubscriptions = {};

  Stream<RTMMessage> get messageStream => _messageController.stream;
  bool get isLoggedIn => _currentUserId != null;

  FirebaseMessagingService(this._firestore, this._realtimeDb);

  /// Initialize with current user ID
  Future<void> initialize() async {
    // print('✅ Firebase Messaging Service initialized');
  }

  /// Login with user ID
  Future<void> login(String userId) async {
    _currentUserId = userId;
    // print('✅ Firebase Messaging Login successful: $userId');
  }

  /// Logout
  Future<void> logout() async {
    // Cancel all subscriptions
    for (var subscription in _conversationSubscriptions.values) {
      await subscription.cancel();
    }
    _conversationSubscriptions.clear();
    _currentUserId = null;
    // print('✅ Firebase Messaging Logout successful');
  }

  /// Send message to peer using Realtime Database (instant!)
  Future<void> sendMessageToPeer(String peerId, String text) async {
    if (_currentUserId == null) {
      throw Exception('Not logged in');
    }

    final conversationId = _getConversationId(_currentUserId!, peerId);
    final messageRef = _realtimeDb.ref('conversations/$conversationId/messages').push();

    // Save to Realtime Database for instant delivery
    await messageRef.set({
      'senderId': _currentUserId,
      'text': text,
      'timestamp': ServerValue.timestamp,
    });

    // print('📤 Message sent to $peerId via Realtime Database');
  }

  /// Get chat history from Realtime Database
  Future<List<RTMMessage>> getChatHistory(String peerId, {int limit = 100}) async {
    if (_currentUserId == null) return [];

    final conversationId = _getConversationId(_currentUserId!, peerId);
    final messagesRef = _realtimeDb.ref('conversations/$conversationId/messages');

    try {
      // Get all messages without ordering (to avoid index requirement)
      final snapshot = await messagesRef.get();

      if (!snapshot.exists) {
        return [];
      }

      final messages = <RTMMessage>[];
      final data = snapshot.value as Map?;

      if (data != null) {
        data.forEach((key, value) {
          if (value is Map) {
            messages.add(
              RTMMessage(
                text: value['text'] ?? '',
                senderId: value['senderId'] ?? '',
                timestamp: value['timestamp'] != null
                    ? DateTime.fromMillisecondsSinceEpoch(value['timestamp'] as int)
                    : DateTime.now(),
              ),
            );
          }
        });
      }

      // Sort by timestamp in code
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Limit to last N messages
      if (messages.length > limit) {
        messages.removeRange(0, messages.length - limit);
      }

      // print('📥 Loaded ${messages.length} messages from history');
      return messages;
    } catch (e) {
      // print('❌ Error loading chat history: $e');
      return [];
    }
  }

  /// Listen to messages from a specific peer (REAL-TIME!)
  void listenToConversation(String peerId) {
    if (_currentUserId == null) return;

    final conversationId = _getConversationId(_currentUserId!, peerId);

    // Don't create duplicate listeners
    if (_conversationSubscriptions.containsKey(conversationId)) {
      return;
    }

    // Mark the time we start listening - only process messages after this
    final startListeningTime = DateTime.now().millisecondsSinceEpoch;

    // Listen to new messages in REAL-TIME using Realtime Database
    final messagesRef = _realtimeDb.ref('conversations/$conversationId/messages');

    final subscription = messagesRef.onChildAdded.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return;

      // Get message timestamp
      final messageTimestamp = data['timestamp'] as int? ?? 0;

      // Only process messages that came AFTER we started listening
      // This prevents old messages from being emitted
      if (messageTimestamp <= startListeningTime) {
        return;
      }

      // Only emit messages from other users (not from ourselves)
      if (data['senderId'] != _currentUserId) {
        _messageController.add(
          RTMMessage(
            text: data['text'] ?? '',
            senderId: data['senderId'] ?? '',
            timestamp: DateTime.fromMillisecondsSinceEpoch(messageTimestamp),
          ),
        );
        // print('📨 Received NEW message from ${data['senderId']} via Realtime Database (INSTANT!)');
      }
    });

    _conversationSubscriptions[conversationId] = subscription;
    // print('👂 Listening to conversation: $conversationId (Realtime Database) from ${DateTime.fromMillisecondsSinceEpoch(startListeningTime)}');
  }

  /// Stop listening to a conversation
  Future<void> stopListeningToConversation(String peerId) async {
    if (_currentUserId == null) return;

    final conversationId = _getConversationId(_currentUserId!, peerId);
    final subscription = _conversationSubscriptions[conversationId];

    if (subscription != null) {
      await subscription.cancel();
      _conversationSubscriptions.remove(conversationId);
      // print('🔇 Stopped listening to conversation: $conversationId');
    }
  }

  /// Check if user is online (mock implementation - can use Firestore presence)
  Future<Map<String, bool>> queryPeerOnlineStatus(List<String> peerIds) async {
    // Simple implementation: check if user document exists and has recent activity
    final result = <String, bool>{};

    for (var peerId in peerIds) {
      try {
        final userDoc = await _firestore.collection('users').doc(peerId).get();
        result[peerId] = userDoc.exists;
      } catch (e) {
        result[peerId] = false;
      }
    }

    return result;
  }

  /// Get conversation ID (consistent ordering)
  String _getConversationId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Dispose resources
  Future<void> dispose() async {
    await logout();
    await _messageController.close();
  }

  // Channel methods (not needed for P2P messaging, but kept for compatibility)
  Future<void> joinChannel(String channelName) async {
    // print('⚠️  Channel support not implemented in Firebase version');
  }

  Future<void> leaveChannel(String channelName) async {
    // print('⚠️  Channel support not implemented in Firebase version');
  }

  Future<void> sendChannelMessage(String channelName, String text) async {
    // print('⚠️  Channel support not implemented in Firebase version');
  }
}

/// RTM Message model
class RTMMessage {
  final String text;
  final String senderId;
  final DateTime timestamp;

  RTMMessage({required this.text, required this.senderId, required this.timestamp});
}
