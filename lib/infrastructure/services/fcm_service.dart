import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// FCM Service for handling push notifications
/// Used for incoming video calls when app is in background/terminated
class FCMService {
  static final FCMService instance = FCMService._();
  FCMService._();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  final StreamController<Map<String, dynamic>> _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get notificationStream => _notificationController.stream;

  /// Initialize FCM and get token
  Future<void> initialize() async {
    try {
      // Request permission for iOS
      await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
      });

      // Setup message handlers
      _setupMessageHandlers();
    } catch (e) {
      // debugPrint removed for production
    }
  }

  /// Save FCM token to Firestore for the current user
  Future<void> saveFCMTokenForUser(String userId) async {
    if (_fcmToken == null) {
      return;
    }

    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': _fcmToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // debugPrint removed for production
    }
  }

  /// Get FCM token for a specific user
  Future<String?> getFCMTokenForUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final token = doc.data()?['fcmToken'] as String?;
      return token;
    } catch (e) {
      // debugPrint removed for production
      return null;
    }
  }

  /// Setup message handlers for different app states
  void _setupMessageHandlers() {
    // Handle messages when app is in FOREGROUND
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleIncomingMessage(message);
    });

    // Handle notification tap when app is in BACKGROUND
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleIncomingMessage(message);
    });

    // Check for initial message when app was opened from TERMINATED state
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleIncomingMessage(message);
      }
    });
  }

  /// Handle incoming FCM message
  void _handleIncomingMessage(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;

    if (type == 'incoming_call') {
      // Emit to stream for UI to handle
      _notificationController.add({
        'type': 'incoming_call',
        'callId': data['callId'],
        'callerId': data['callerId'],
        'callerName': data['callerName'],
        'callerAvatar': data['callerAvatar'],
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _notificationController.close();
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background message handling logic
}
