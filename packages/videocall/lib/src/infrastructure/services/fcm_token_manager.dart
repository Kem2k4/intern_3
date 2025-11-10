import 'package:auth/auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Service for managing FCM tokens and updating them in user profiles
class FCMTokenManager {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final AuthRepository _authRepository;

  FCMTokenManager(this._authRepository);

  /// Initialize FCM token management
  Future<void> initialize() async {
    // Request permission for iOS
    await _firebaseMessaging.requestPermission();

    // Get initial token and update user profile
    await _updateCurrentUserToken();

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((String token) {
      debugPrint('FCM Token refreshed: $token');
      _updateCurrentUserToken();
    });
  }

  /// Update FCM token for current user
  Future<void> _updateCurrentUserToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        final result = await _authRepository.updateFcmToken(token);
        result.fold(
          (failure) => debugPrint('Failed to update FCM token: $failure'),
          (_) => debugPrint('FCM token updated successfully'),
        );
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Manually refresh and update token
  Future<void> refreshToken() async {
    await _firebaseMessaging.deleteToken();
    await _updateCurrentUserToken();
  }
}