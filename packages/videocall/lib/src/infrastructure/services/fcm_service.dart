import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../presentation/bloc/video_call_bloc.dart';

/// Service for handling Firebase Cloud Messaging operations
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  static FCMService get instance => _instance;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// Initialize FCM service
  Future<void> initialize() async {
    // Request permission for iOS
    await _firebaseMessaging.requestPermission();

    // Get FCM token
    final token = await _firebaseMessaging.getToken();
    debugPrint('FCM Token: $token');

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.messageId}');
    debugPrint('Data: ${message.data}');

    // Handle incoming call notification
    if (message.data['type'] == 'incoming_call') {
      _handleIncomingCallNotification(message.data);
    }
  }

  /// Handle incoming call notification
  void _handleIncomingCallNotification(Map<String, dynamic> data) {
    final callerId = data['callerId'] as String?;
    final callerName = data['callerName'] as String?;
    final channelName = data['channelName'] as String?;
    final callId = data['callId'] as String?;

    if (callerId != null && callerName != null && channelName != null && callId != null) {
      debugPrint('Incoming call from: $callerName ($callerId)');

      // Add callerAvatar to data if not present
      final enrichedData = {
        ...data,
        'callerAvatar': data['callerAvatar'] ?? '', // Default empty if not provided
      };

      // Dispatch to VideoCallBloc
      VideoCallBloc.handleIncomingCall(enrichedData);
    }
  }

  /// Send push notification for incoming call
  Future<void> sendIncomingCallNotification({
    required String receiverToken,
    required String callerId,
    required String callerName,
    required String channelName,
    required String callId,
  }) async {
    // TODO: Implement server-side FCM sending
    // This should be done from your backend server
    // Example payload:
    /*
    final payload = {
      'to': receiverToken,
      'notification': {
        'title': 'Incoming Video Call',
        'body': '$callerName is calling...',
        'sound': 'default',
      },
      'data': {
        'type': 'incoming_call',
        'callerId': callerId,
        'callerName': callerName,
        'channelName': channelName,
        'callId': callId,
      },
    };
    */
    debugPrint('TODO: Send FCM notification to $receiverToken for call $callId');
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Handle token refresh
  void onTokenRefresh(Function(String) callback) {
    _firebaseMessaging.onTokenRefresh.listen(callback);
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.messageId}');
  debugPrint('Data: ${message.data}');

  // Handle incoming call in background
  if (message.data['type'] == 'incoming_call') {
    final callerId = message.data['callerId'] as String?;
    final callerName = message.data['callerName'] as String?;
    final channelName = message.data['channelName'] as String?;
    final callId = message.data['callId'] as String?;

    if (callerId != null && callerName != null && channelName != null && callId != null) {
      debugPrint('Background incoming call from: $callerName ($callerId)');

      // TODO: Show full-screen incoming call notification
      // This would typically show a high-priority notification that can wake the device
      // and allow the user to accept/reject the call even when the app is in background
    }
  }
}