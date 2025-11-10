import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../config/agora_config.dart';

/// Service for managing Agora RTC Engine operations
/// This service provides a clean interface for video call functionality
/// and can be easily mocked for testing
abstract class AgoraService {
  /// Initialize the Agora engine
  Future<void> initialize();

  /// Join a video call channel
  Future<void> joinChannel({
    required String channelName,
    required int uid,
    required String token,
  });

  /// Leave the current channel
  Future<void> leaveChannel();

  /// Enable/disable local video
  Future<void> enableLocalVideo(bool enabled);

  /// Enable/disable local audio
  Future<void> enableLocalAudio(bool enabled);

  /// Switch camera (front/back)
  Future<void> switchCamera();

  /// Dispose the engine
  Future<void> dispose();

  /// Get current connection state
  VideoCallConnectionState get connectionState;

  /// Stream of connection state changes
  Stream<VideoCallConnectionState> get connectionStateStream;

  /// Stream of remote user events (join/leave)
  Stream<VideoCallParticipant> get remoteUserStream;

  /// Stream of video/audio state changes
  Stream<Map<String, dynamic>> get mediaStateStream;
}

/// Implementation of AgoraService using Agora SDK
class AgoraServiceImpl implements AgoraService {
  RtcEngine? _engine;
  final StreamController<VideoCallConnectionState> _connectionController = StreamController.broadcast();
  final StreamController<VideoCallParticipant> _remoteUserController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _mediaStateController = StreamController.broadcast();
  
  VideoCallConnectionState _connectionState = VideoCallConnectionState.disconnected;
  final Map<int, VideoCallParticipant> _remoteUsers = {};

  @override
  Future<void> initialize() async {
    try {
      // Create engine
      _engine = createAgoraRtcEngine();
      
      // Initialize with config
      await _engine!.initialize(RtcEngineContext(
        appId: AgoraConfig.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // Enable video
      await _engine!.enableVideo();
      
      // Set up event handlers
      _setupEventHandlers();
      
      _updateConnectionState(VideoCallConnectionState.disconnected);
    } catch (e) {
      throw Exception('Failed to initialize Agora engine: $e');
    }
  }

  void _setupEventHandlers() {
    if (_engine == null) return;

    _engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        _updateConnectionState(VideoCallConnectionState.connected);
      },
      
      onLeaveChannel: (RtcConnection connection, RtcStats stats) {
        _updateConnectionState(VideoCallConnectionState.disconnected);
        _remoteUsers.clear();
      },
      
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        final participant = VideoCallParticipant(
          userId: remoteUid.toString(),
          name: 'Remote User', // TODO: Get from user data
          isVideoEnabled: true,
          isAudioEnabled: true,
        );
        _remoteUsers[remoteUid] = participant;
        _remoteUserController.add(participant);
      },
      
      onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
        final participant = _remoteUsers.remove(remoteUid);
        if (participant != null) {
          _remoteUserController.add(participant.copyWith(
            isVideoEnabled: false,
            isAudioEnabled: false,
          ));
        }
      },
      
      onConnectionStateChanged: (RtcConnection connection, ConnectionStateType state, ConnectionChangedReasonType reason) {
        switch (state) {
          case ConnectionStateType.connectionStateConnecting:
            _updateConnectionState(VideoCallConnectionState.connecting);
            break;
          case ConnectionStateType.connectionStateConnected:
            _updateConnectionState(VideoCallConnectionState.connected);
            break;
          case ConnectionStateType.connectionStateReconnecting:
            _updateConnectionState(VideoCallConnectionState.reconnecting);
            break;
          case ConnectionStateType.connectionStateFailed:
            _updateConnectionState(VideoCallConnectionState.failed);
            break;
          default:
            _updateConnectionState(VideoCallConnectionState.disconnected);
        }
      },
    ));
  }

  @override
  Future<void> joinChannel({
    required String channelName,
    required int uid,
    required String token,
  }) async {
    if (_engine == null) throw Exception('Engine not initialized');

    try {
      _updateConnectionState(VideoCallConnectionState.connecting);
      
      // Join channel with timeout to prevent hanging
      final joinFuture = _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: uid,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      final timeoutFuture = Future.delayed(const Duration(seconds: 10), () {
        throw Exception('Video call connection timed out. The token may be expired or invalid.');
      });

      await Future.any([joinFuture, timeoutFuture]);
    } catch (e) {
      _updateConnectionState(VideoCallConnectionState.failed);
      // Provide more specific error messages
      if (e.toString().contains('timeout')) {
        throw Exception('Video call connection timed out. Please check your internet connection and try again.');
      } else if (e.toString().contains('token') || e.toString().contains('Token')) {
        throw Exception('Video call token is invalid or expired. Please refresh the token.');
      } else {
        throw Exception('Failed to join video call channel: $e');
      }
    }
  }

  @override
  Future<void> leaveChannel() async {
    if (_engine == null) return;

    try {
      await _engine!.leaveChannel();
      _remoteUsers.clear();
    } catch (e) {
      throw Exception('Failed to leave channel: $e');
    }
  }

  @override
  Future<void> enableLocalVideo(bool enabled) async {
    if (_engine == null) return;

    try {
      if (enabled) {
        await _engine!.enableVideo();
        await _engine!.startPreview();
      } else {
        await _engine!.disableVideo();
        await _engine!.stopPreview();
      }
      
      _mediaStateController.add({
        'type': 'local_video',
        'enabled': enabled,
      });
    } catch (e) {
      throw Exception('Failed to toggle video: $e');
    }
  }

  @override
  Future<void> enableLocalAudio(bool enabled) async {
    if (_engine == null) return;

    try {
      await _engine!.muteLocalAudioStream(!enabled);
      
      _mediaStateController.add({
        'type': 'local_audio',
        'enabled': enabled,
      });
    } catch (e) {
      throw Exception('Failed to toggle audio: $e');
    }
  }

  @override
  Future<void> switchCamera() async {
    if (_engine == null) return;

    try {
      await _engine!.switchCamera();
      
      _mediaStateController.add({
        'type': 'camera_switch',
        'switched': true,
      });
    } catch (e) {
      throw Exception('Failed to switch camera: $e');
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await _engine?.leaveChannel();
      await _engine?.release();
      _engine = null;
      
      _connectionController.close();
      _remoteUserController.close();
      _mediaStateController.close();
    } catch (e) {
      // Ignore dispose errors
    }
  }

  @override
  VideoCallConnectionState get connectionState => _connectionState;

  @override
  Stream<VideoCallConnectionState> get connectionStateStream => _connectionController.stream;

  @override
  Stream<VideoCallParticipant> get remoteUserStream => _remoteUserController.stream;

  @override
  Stream<Map<String, dynamic>> get mediaStateStream => _mediaStateController.stream;

  void _updateConnectionState(VideoCallConnectionState state) {
    _connectionState = state;
    _connectionController.add(state);
  }
}

/// Mock implementation for testing and development
class MockAgoraService implements AgoraService {
  VideoCallConnectionState _connectionState = VideoCallConnectionState.disconnected;
  final StreamController<VideoCallConnectionState> _connectionController = StreamController.broadcast();
  final StreamController<VideoCallParticipant> _remoteUserController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _mediaStateController = StreamController.broadcast();

  @override
  Future<void> initialize() async {
    // Simulate initialization delay
    await Future.delayed(const Duration(seconds: 1));
    _updateConnectionState(VideoCallConnectionState.disconnected);
  }

  @override
  Future<void> joinChannel({
    required String channelName,
    required int uid,
    required String token,
  }) async {
    _updateConnectionState(VideoCallConnectionState.connecting);

    // Simulate connection delay
    await Future.delayed(const Duration(seconds: 2));

    _updateConnectionState(VideoCallConnectionState.connected);

    // Simulate remote user joining
    await Future.delayed(const Duration(seconds: 1));
    _remoteUserController.add(
      const VideoCallParticipant(
        userId: 'remote_user_123',
        name: 'Remote User',
        isVideoEnabled: true,
        isAudioEnabled: true,
      ),
    );
  }

  @override
  Future<void> leaveChannel() async {
    _updateConnectionState(VideoCallConnectionState.disconnected);
    _remoteUserController.add(
      const VideoCallParticipant(
        userId: 'remote_user_123',
        name: 'Remote User',
        isVideoEnabled: false,
        isAudioEnabled: false,
      ),
    );
  }

  @override
  Future<void> enableLocalVideo(bool enabled) async {
    _mediaStateController.add({
      'type': 'local_video',
      'enabled': enabled,
    });
  }

  @override
  Future<void> enableLocalAudio(bool enabled) async {
    _mediaStateController.add({
      'type': 'local_audio',
      'enabled': enabled,
    });
  }

  @override
  Future<void> switchCamera() async {
    _mediaStateController.add({
      'type': 'camera_switch',
      'switched': true,
    });
  }

  @override
  Future<void> dispose() async {
    _connectionController.close();
    _remoteUserController.close();
    _mediaStateController.close();
  }

  @override
  VideoCallConnectionState get connectionState => _connectionState;

  @override
  Stream<VideoCallConnectionState> get connectionStateStream => _connectionController.stream;

  @override
  Stream<VideoCallParticipant> get remoteUserStream => _remoteUserController.stream;

  @override
  Stream<Map<String, dynamic>> get mediaStateStream => _mediaStateController.stream;

  void _updateConnectionState(VideoCallConnectionState state) {
    _connectionState = state;
    _connectionController.add(state);
  }
}