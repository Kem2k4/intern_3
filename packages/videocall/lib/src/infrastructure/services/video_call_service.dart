import 'package:flutter/foundation.dart';
import '../../data/repositories/video_call_repository.dart';
import '../config/agora_config.dart';
import 'agora_service.dart';
import 'fcm_service.dart';
import 'permission_service.dart';
import 'package:auth/auth.dart';

/// Service for orchestrating video call operations
class VideoCallService {
  final VideoCallRepository repository;
  final AgoraService agoraService;
  final AuthRepository authRepository;

  VideoCallService(this.repository, this.agoraService, this.authRepository);

  /// Check and request permissions for video calling
  Future<bool> checkAndRequestPermissions() async {
    final hasPermissions = await PermissionService.hasAllRequiredPermissions();
    if (!hasPermissions) {
      await PermissionService.requestVideoCallPermissions();
      // TODO: Check if permissions were granted
      return true; // Temporarily return true
    }
    return true;
  }

  /// Initiate a video call to another user
  Future<String> initiateCall({
    required String callerId,
    required String callerName,
    required String callerAvatar,
    required String receiverId,
    required String receiverName,
    required String receiverAvatar,
  }) async {
    // Use fixed channel name for testing
    final channelName = AgoraConfig.testChannelName; // "video_call"
    
    // Generate token (for now use temp token, in production call server API)
    final token = await _generateToken(channelName, callerId);

    // Create call in database
    final callId = await repository.createCall(
      callerId: callerId,
      callerName: callerName,
      callerAvatar: callerAvatar,
      receiverId: receiverId,
      receiverName: receiverName,
      receiverAvatar: receiverAvatar,
      channelName: channelName,
      token: token,
    );

    // Send FCM notification to receiver
    await _sendIncomingCallNotification(
      receiverId: receiverId,
      callerId: callerId,
      callerName: callerName,
      channelName: channelName,
      callId: callId,
    );

    return callId;
  }

  /// Send FCM notification for incoming call
  Future<void> _sendIncomingCallNotification({
    required String receiverId,
    required String callerId,
    required String callerName,
    required String channelName,
    required String callId,
  }) async {
    try {
      // Get receiver's FCM token
      final receiverResult = await authRepository.getUserById(receiverId);
      await receiverResult.fold(
        (failure) async {
          // Handle error - could not get receiver data
          debugPrint('Failed to get receiver data: $failure');
        },
        (receiver) async {
          final receiverToken = receiver.fcmToken;
          if (receiverToken != null && receiverToken.isNotEmpty) {
            // Send FCM notification
            await FCMService.instance.sendIncomingCallNotification(
              receiverToken: receiverToken,
              callerId: callerId,
              callerName: callerName,
              channelName: channelName,
              callId: callId,
            );
          } else {
            debugPrint('Receiver FCM token not available');
          }
        },
      );
    } catch (e) {
      debugPrint('Error sending FCM notification: $e');
    }
  }

  /// Generate token for channel (placeholder for server-side generation)
  Future<String> _generateToken(String channelName, String uid) async {
    // For temporary token usage, return the configured temp token
    // In production, this should generate a proper token for the specific channel
    return AgoraConfig.tempToken;
  }

  /// Accept incoming call
  Future<void> acceptCall(String callId) async {
    await repository.acceptCall(callId);
  }

  /// Reject incoming call
  Future<void> rejectCall(String callId) async {
    await repository.rejectCall(callId);
  }

  /// End call
  Future<void> endCall(String callId) async {
    await repository.endCall(callId);
    await agoraService.leaveChannel();
  }

  /// Join video call channel
  Future<void> joinCall(String channelName, String token, int uid) async {
    await agoraService.initialize();
    await agoraService.joinChannel(
      channelName: channelName,
      uid: uid,
      token: token,
    );
  }

  /// Leave video call
  Future<void> leaveCall() async {
    await agoraService.leaveChannel();
  }

  /// Toggle local video
  Future<void> toggleVideo(bool enabled) async {
    await agoraService.enableLocalVideo(enabled);
  }

  /// Toggle local audio
  Future<void> toggleAudio(bool enabled) async {
    await agoraService.enableLocalAudio(enabled);
  }

  /// Switch camera
  Future<void> switchCamera() async {
    await agoraService.switchCamera();
  }

  /// Dispose all resources
  Future<void> dispose() async {
    await agoraService.dispose();
  }
}