/// Agora Configuration
/// Centralized configuration for Agora livestream & video call
class AgoraConfig {
  // Agora App ID - Replace with your actual App ID from https://console.agora.io/
  static const String appId = '1ba9507a85a6458ab556245408db710a';

  // ============================================
  // CHANNEL CONFIGURATION
  // ============================================

  /// Default channel names - TÁCH RIÊNG BIỆT CHO 2 TÍNH NĂNG
  static const String livestreamChannel = 'livestream';
  static const String videoCallChannel = 'communication';

  /// Generate unique channel name for video call
  /// Format: "call_{userId1}_{userId2}_{timestamp}"
  static String generateVideoCallChannel(String user1Id, String user2Id) {
    final ids = [user1Id, user2Id]..sort(); // Sort to ensure consistency
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'call_${ids[0]}_${ids[1]}_$timestamp';
  }

  /// Generate channel name from call ID (from Firebase)
  static String getChannelFromCallId(String callId) {
    return 'call_$callId';
  }

  // ============================================
  // VIDEO CONFIGURATION - TÁCH RIÊNG CHO 2 LOẠI
  // ============================================

  // Livestream video settings (high quality)
  static const int livestreamVideoWidth = 1920;
  static const int livestreamVideoHeight = 1080;
  static const int livestreamVideoFrameRate = 30;
  static const int livestreamVideoBitrate = 2000;

  // Video call settings (balanced for mobile)
  static const int videoCallWidth = 640;
  static const int videoCallHeight = 480;
  static const int videoCallFrameRate = 15;
  static const int videoCallBitrate = 800;

  /// Get video dimensions based on channel type
  static VideoConfig getVideoConfigForLivestream() {
    return VideoConfig(
      width: livestreamVideoWidth,
      height: livestreamVideoHeight,
      frameRate: livestreamVideoFrameRate,
      bitrate: livestreamVideoBitrate,
    );
  }

  static VideoConfig getVideoConfigForVideoCall() {
    return VideoConfig(
      width: videoCallWidth,
      height: videoCallHeight,
      frameRate: videoCallFrameRate,
      bitrate: videoCallBitrate,
    );
  }

  /// Token mode: 'none', 'static', or 'server'
  /// - 'none': No token (testing only, not secure)
  /// - 'static': Use hardcoded token below (expires after 24h or configured time)
  /// - 'server': Fetch token from your backend server (production recommended)
  static const String tokenMode = 'static'; // Change to 'server' for production

  static const String livestreamToken =
      '007eJxTYNj7OmVCIsPxywsclbNMGnlPfJjZseuzZeHqzds/ZCuYvLqnwGCYlGhpamCeaGGaaGZiapGYZGpqZmRiamJgkZJkbmiQWHeIKbMhkJHh9DVWFkYGCATxuRhyMstSi0uKUhNzGRgAkgAjLw==';

  static const String videoCallToken =
      '007eJxTYPBwWdcQmOu4u/XWLx3WvftzD2meO2mk1bYz9ibL/BLRdaUKDIZJiZamBuaJFqaJZiamFolJpqZmRiamJgYWKUnmhgaJO5/+y2gIZGTgUDrGyMgAgSA+L0Nyfm5uaV5mcmJJZn4eAwMAcrcjEg==';

  /// Token server endpoint (for production)
  /// GET /api/agora/token?channelName=xxx&uid=xxx&role=xxx
  /// Response: { "token": "xxx", "expiresAt": 1234567890 }
  static const String tokenServerUrl = ''; // Your backend URL

  /// Get token for LIVESTREAM
  static String? getLivestreamToken() {
    switch (tokenMode) {
      case 'static':
        return livestreamToken.isNotEmpty ? livestreamToken : null;
      case 'server':
        // Call server to get token
        return null;
      case 'none':
      default:
        return null;
    }
  }

  /// Get token for VIDEO CALL
  static String? getVideoCallToken() {
    switch (tokenMode) {
      case 'static':
        return videoCallToken.isNotEmpty ? videoCallToken : null;
      case 'server':
        // Call server to get token
        return null;
      case 'none':
      default:
        return null;
    }
  }

  /// Get token based on channel name (legacy support)
  static String? getToken(String channelName, int uid) {
    // Determine which token to use based on channel name
    if (channelName == livestreamChannel || channelName.startsWith('livestream')) {
      return getLivestreamToken();
    } else {
      return getVideoCallToken();
    }
  }

  /// Check if token is required
  static bool get requiresToken => tokenMode != 'none';

  /// Check if using server-side token
  static bool get usesServerToken => tokenMode == 'server';

  /// Check if static token is configured
  static bool get hasLivestreamToken => livestreamToken.isNotEmpty;
  static bool get hasVideoCallToken => videoCallToken.isNotEmpty;

  static const int audioSampleRate = 48000;
  static const int audioChannels = 1; // Mono
  static const int audioBitrate = 128;

  // Private constructor to prevent instantiation
  AgoraConfig._();
}

/// Video configuration class
class VideoConfig {
  final int width;
  final int height;
  final int frameRate;
  final int bitrate;

  const VideoConfig({
    required this.width,
    required this.height,
    required this.frameRate,
    required this.bitrate,
  });
}
