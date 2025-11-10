/// Agora RTC Configuration for Video Call
/// TODO: Implement with actual Agora SDK when package is properly configured
class AgoraConfig {
  // TODO: Replace with your actual Agora App ID from Agora Console
  static const String appId = '1ba9507a85a6458ab556245408db710a';

  // Temporary token for testing (expires after 24 hours)
  // Generated for channel: video_call
  static const String tempToken = '007eJxTYNi5ltee83JvyqW5ZdecUkwPHU6896Q+dPn6btNfJyse8QUoMBgmJVqaGpgnWpgmmpmYWiQmmZqaGZmYmhhYpCSZGxokWh4XyGwIZGS47nSDgREKQXwuhrLMlNT8+OTEnBwGBgBxPyK5';

  // Test channel name for development
  static const String testChannelName = 'video_call';

  // Default channel name prefix for 1-1 calls
  static String generateChannelName(String callerId, String receiverId) {
    // Create consistent channel name by sorting IDs
    final ids = [callerId, receiverId]..sort();
    return 'video_call_${ids[0]}_${ids[1]}';
  }

  // Default user ID generation (can be replaced with actual user ID)
  static int generateUserId(String userId) {
    return userId.hashCode.abs();
  }

  /// Get temporary token for testing
  /// In production, this should be generated server-side
  static String getTokenForChannel(String channelName, int uid) {
    // TODO: Call your server API to generate token
    // For now, return temp token
    return tempToken;
  }

  /// Video quality presets
  static const Map<String, Map<String, dynamic>> videoQualityPresets = {
    'low': {
      'width': 320,
      'height': 180,
      'frameRate': 15,
      'bitrate': 200,
    },
    'medium': {
      'width': 640,
      'height': 360,
      'frameRate': 15,
      'bitrate': 400,
    },
    'high': {
      'width': 1280,
      'height': 720,
      'frameRate': 15,
      'bitrate': 800,
    },
  };

  /// Audio quality presets
  static const Map<String, String> audioQualityPresets = {
    'low': 'speech_standard',
    'medium': 'music_standard',
    'high': 'music_high_quality',
  };

  /// Default video configuration
  static Map<String, dynamic> get defaultVideoConfig => videoQualityPresets['medium']!;

  /// Default audio configuration
  static String get defaultAudioConfig => audioQualityPresets['medium']!;

  /// Check if Agora is properly configured
  static bool get isConfigured {
    // Check if appId is not placeholder
    if (appId == 'YOUR_AGORA_APP_ID' || appId.isEmpty) return false;
    
    // Check if tempToken is not placeholder and has reasonable length
    if (tempToken == 'YOUR_TEMP_TOKEN_FOR_TESTING' || tempToken.length < 50) return false;
    
    return true;
  }

  /// Check if the temporary token might be expired
  /// Temporary tokens typically expire after 24 hours
  static bool get isTempTokenExpired {
    // Check if the token looks like an expired test token
    // This is a simple heuristic - in production you'd decode the JWT
    if (tempToken.startsWith('007eJxTYNiwQNW2/97vO/odP00Oxc24sULG7VV/y7/9P++Uh+kaRSYpMBgmJVqaGpgnWpgmmpmYWiQmmZqaGZmYmhhYpCSZGxoknlwrkNkQyMjgZPmUgREKQXwuhrLMlNT8+OTEnBwGBgDIhyNm')) {
      // This is the old test token that was generated and is likely expired
      return true;
    }
    return false;
  }

  /// Get configuration status message
  static String get configurationStatus {
    if (!isConfigured) {
      final issues = <String>[];
      if (appId == 'YOUR_AGORA_APP_ID') {
        issues.add('App ID not set');
      }
      if (tempToken == 'YOUR_TEMP_TOKEN_FOR_TESTING') {
        issues.add('Temporary token not set');
      }
      return 'Video call not configured: ${issues.join(', ')}';
    }
    if (isTempTokenExpired) {
      return 'Video call token has expired. Please generate a new token from Agora Console.';
    }
    return 'Video call configured';
  }
}

/// Video call connection states
enum VideoCallConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

/// Video call media states
enum VideoCallMediaState {
  disabled,
  enabled,
  muted,
}

/// Video call participant info
class VideoCallParticipant {
  final String userId;
  final String name;
  final String? avatar;
  final bool isVideoEnabled;
  final bool isAudioEnabled;
  final bool isHost;

  const VideoCallParticipant({
    required this.userId,
    required this.name,
    this.avatar,
    this.isVideoEnabled = true,
    this.isAudioEnabled = true,
    this.isHost = false,
  });

  VideoCallParticipant copyWith({
    String? userId,
    String? name,
    String? avatar,
    bool? isVideoEnabled,
    bool? isAudioEnabled,
    bool? isHost,
  }) {
    return VideoCallParticipant(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      isAudioEnabled: isAudioEnabled ?? this.isAudioEnabled,
      isHost: isHost ?? this.isHost,
    );
  }
}

/// Video call session info
class VideoCallSession {
  final String callId;
  final String channelName;
  final VideoCallParticipant localParticipant;
  final List<VideoCallParticipant> remoteParticipants;
  final VideoCallConnectionState connectionState;
  final Duration duration;

  const VideoCallSession({
    required this.callId,
    required this.channelName,
    required this.localParticipant,
    this.remoteParticipants = const [],
    this.connectionState = VideoCallConnectionState.disconnected,
    this.duration = Duration.zero,
  });

  VideoCallSession copyWith({
    String? callId,
    String? channelName,
    VideoCallParticipant? localParticipant,
    List<VideoCallParticipant>? remoteParticipants,
    VideoCallConnectionState? connectionState,
    Duration? duration,
  }) {
    return VideoCallSession(
      callId: callId ?? this.callId,
      channelName: channelName ?? this.channelName,
      localParticipant: localParticipant ?? this.localParticipant,
      remoteParticipants: remoteParticipants ?? this.remoteParticipants,
      connectionState: connectionState ?? this.connectionState,
      duration: duration ?? this.duration,
    );
  }
}