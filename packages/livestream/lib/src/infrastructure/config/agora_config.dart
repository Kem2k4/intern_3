/// Agora configuration constants
class AgoraConfig {
  // App ID from Agora Console
  static const String appId = '1ba9507a85a6458ab556245408db710a';

  // Temporary token for authentication (leave empty for testing, use actual token in production)
  static const String tempToken = '';

  // Token riêng cho channel "livestream" (tạm thời không expire cho testing - 24h)
  static const String livestreamChannelToken =
      '007eJxTYJA2n1665X3N8xnlk/eeY1ohW9VkNbEsdVkr7//kLClpnw8KDIZJiZamBuaJFqaJZiamFolJpqZmRiamJgYWKUnmhgaJS/I5MxsCGRlO1OUxMzJAIIjPxZCTWZZaXFKUmpjLwAAA6cghAg==';

  // Token server URL (if using token authentication)
  static const String tokenServerUrl = '';

  // Default channel profile
  static const int channelProfile = 1; // 0: Communication, 1: Live Broadcasting

  // Default client role
  static const int clientRole = 1; // 1: Broadcaster, 2: Audience

  // Video dimensions
  static const int videoWidth = 640;
  static const int videoHeight = 360;
  static const int frameRate = 15;

  // Audio settings
  static const int audioSampleRate = 44100;
  static const int audioChannels = 1;

  // Permissions
  static const List<String> requiredPermissions = [
    'android.permission.CAMERA',
    'android.permission.RECORD_AUDIO',
    'android.permission.INTERNET',
    'android.permission.ACCESS_NETWORK_STATE',
  ];
}

/// Video configuration for livestream
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

/// Extension methods for AgoraConfig
extension AgoraConfigExtension on AgoraConfig {
  /// Get token cho channel cụ thể (ưu tiên token riêng nếu có)
  static String? getTokenForChannel(String channelName) {
    // Token riêng cho channel "livestream"
    if (channelName == 'livestream' && AgoraConfig.livestreamChannelToken.isNotEmpty) {
      return AgoraConfig.livestreamChannelToken;
    }

    // Token chung nếu không rỗng
    if (AgoraConfig.tempToken.isNotEmpty) {
      return AgoraConfig.tempToken;
    }

    // For testing: return null to use App ID only (may not work in production)
    // print('⚠️ No token available for channel: $channelName, using null token for testing');
    return null;
  }

  /// Get video configuration optimized for livestream
  static VideoConfig getVideoConfigForLivestream() {
    return const VideoConfig(
      width: 640,
      height: 360,
      frameRate: 15,
      bitrate: 400, // 400 kbps for good quality
    );
  }

  /// Get video configuration for high quality livestream
  static VideoConfig getVideoConfigForHighQuality() {
    return const VideoConfig(
      width: 1280,
      height: 720,
      frameRate: 30,
      bitrate: 1130, // 1130 kbps for HD
    );
  }
}
