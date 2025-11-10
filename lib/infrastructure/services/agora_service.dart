// ignore: depend_on_referenced_packages
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../config/agora_config.dart';

/// Service class for Agora RTC Engine operations
class AgoraService {
  RtcEngine? _engine;
  bool _isInitialized = false;
  String? _currentChannelName;

  // Event controllers for real-time updates
  final StreamController<int> _userJoinedController = StreamController<int>.broadcast();
  final StreamController<int> _userLeftController = StreamController<int>.broadcast();
  final StreamController<String> _errorController = StreamController<String>.broadcast();

  // Public getters
  RtcEngine? get engine => _engine;
  bool get isInitialized => _isInitialized;
  String? get currentChannelName => _currentChannelName;

  // Event streams
  Stream<int> get onUserJoined => _userJoinedController.stream;
  Stream<int> get onUserLeft => _userLeftController.stream;
  Stream<String> get onError => _errorController.stream;

  /// Initialize Agora RTC Engine
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      // Validate App ID
      _validateAppId();

      // Request permissions
      await _requestPermissions();

      // Create RTC engine instance
      _engine = createAgoraRtcEngine();

      // Initialize with App ID and configuration
      await _engine!.initialize(
        RtcEngineContext(
          appId: AgoraConfig.appId,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );

      // Register event handlers
      _registerEventHandlers();

      // Enable video module
      await _engine!.enableVideo();

      // Enable audio module
      await _engine!.enableAudio();

      // Set video encoder configuration for LIVESTREAM (high quality)
      final videoConfig = AgoraConfig.getVideoConfigForLivestream();
      await _engine!.setVideoEncoderConfiguration(
        VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: videoConfig.width, height: videoConfig.height),
          frameRate: videoConfig.frameRate,
          bitrate: videoConfig.bitrate,
          orientationMode: OrientationMode.orientationModeAdaptive,
        ),
      );

      // Set audio profile for high quality
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileDefault,
        scenario: AudioScenarioType.audioScenarioGameStreaming,
      );

      _isInitialized = true;
    } catch (e) {
      // debugPrint removed for production
      _errorController.add('Failed to initialize: $e');
      rethrow;
    }
  }

  /// Validate Agora App ID
  void _validateAppId() {
    if (AgoraConfig.appId.isEmpty || AgoraConfig.appId == 'YOUR_AGORA_APP_ID') {
      throw Exception(
        '⚠️ Invalid Agora App ID!\n\n'
        'Please follow these steps:\n'
        '1. Visit https://console.agora.io/\n'
        '2. Create a new project or select an existing one\n'
        '3. Copy the App ID from project settings\n'
        '4. Replace the appId constant in agora_config.dart\n',
      );
    }
  }

  /// Request camera and microphone permissions
  Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final microphoneStatus = await Permission.microphone.request();

    if (cameraStatus.isDenied || microphoneStatus.isDenied) {
      throw Exception(
        'Camera and microphone permissions are required.\n'
        'Please grant permissions in app settings.',
      );
    }

    if (cameraStatus.isPermanentlyDenied || microphoneStatus.isPermanentlyDenied) {
      throw Exception(
        'Permissions permanently denied.\n'
        'Please enable camera and microphone in device settings.',
      );
    }
  }

  /// Register Agora event handlers
  void _registerEventHandlers() {
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          // Successfully joined channel
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          _userJoinedController.add(remoteUid);
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          _userLeftController.add(remoteUid);
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          // Left channel
        },
        onError: (ErrorCodeType err, String msg) {
          // debugPrint removed for production
          _errorController.add('Error: $msg');
        },
        onConnectionLost: (RtcConnection connection) {
          _errorController.add('Connection lost. Please check your internet connection.');
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          _errorController.add('Session will expire soon');
        },
      ),
    );
  }

  /// Join channel as broadcaster (host)
  Future<void> joinChannelAsBroadcaster(String channelName, {String? token}) async {
    if (!_isInitialized || _engine == null) {
      throw Exception('Agora engine not initialized. Call initialize() first.');
    }

    try {
      // debugPrint removed for production

      // Set client role to broadcaster
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      // Join the channel
      await _engine!.joinChannel(
        token: token ?? '',
        channelId: channelName,
        uid: 0, // 0 means auto-assign by Agora
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
        ),
      );

      _currentChannelName = channelName;
      // debugPrint removed for production
    } catch (e) {
      // debugPrint removed for production
      _errorController.add('Failed to join channel: $e');
      rethrow;
    }
  }

  /// Join channel as audience (viewer)
  Future<void> joinChannelAsAudience(String channelName, {String? token}) async {
    if (!_isInitialized || _engine == null) {
      throw Exception('Agora engine not initialized. Call initialize() first.');
    }

    try {
      // debugPrint removed for production

      // Set client role to audience
      await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);

      // Join the channel
      await _engine!.joinChannel(
        token: token ?? '',
        channelId: channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleAudience,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );

      _currentChannelName = channelName;
      // debugPrint removed for production
    } catch (e) {
      // debugPrint removed for production
      _errorController.add('Failed to join channel: $e');
      rethrow;
    }
  }

  /// Leave current channel
  Future<void> leaveChannel() async {
    if (_engine == null) return;

    try {
      // debugPrint removed for production
      await _engine!.leaveChannel();
      _currentChannelName = null;
      // debugPrint removed for production
    } catch (e) {
      // debugPrint removed for production
      _errorController.add('Failed to leave channel: $e');
      rethrow;
    }
  }

  /// Start camera preview (before joining channel)
  Future<void> startPreview() async {
    if (_engine == null) {
      throw Exception('Agora engine not initialized');
    }

    try {
      // Ensure audio and video are enabled
      await _engine!.enableAudio();
      await _engine!.enableVideo();

      // Unmute audio and video by default
      await _engine!.muteLocalAudioStream(false);
      await _engine!.muteLocalVideoStream(false);

      // Start preview
      await _engine!.startPreview();
      // debugPrint removed for production
    } catch (e) {
      // debugPrint removed for production
      rethrow;
    }
  }

  /// Stop camera preview
  Future<void> stopPreview() async {
    if (_engine == null) return;

    try {
      await _engine!.stopPreview();
      // debugPrint removed for production
    } catch (e) {
      // debugPrint removed for production
    }
  }

  /// End stream - Stop camera and microphone access but keep modules enabled
  /// This is called when host ends stream or cancels
  Future<void> endStream() async {
    if (_engine == null) return;

    try {
      // debugPrint removed for production

      // Stop preview first
      await _engine!.stopPreview();

      // Mute audio and video streams (but don't disable modules)
      await _engine!.muteLocalAudioStream(true);
      await _engine!.muteLocalVideoStream(true);

      // debugPrint removed for production
    } catch (e) {
      // debugPrint removed for production
      // Continue even if error to ensure resources are released
    }
  }

  /// Mute/unmute local audio stream
  Future<void> muteLocalAudio(bool mute) async {
    if (_engine == null) return;

    try {
      await _engine!.muteLocalAudioStream(mute);
      // debugPrint removed for production
    } catch (e) {
      // debugPrint removed for production
      rethrow;
    }
  }

  /// Mute/unmute local video stream
  Future<void> muteLocalVideo(bool mute) async {
    if (_engine == null) return;

    try {
      await _engine!.muteLocalVideoStream(mute);
      // debugPrint removed for production
    } catch (e) {
      // debugPrint removed for production
      rethrow;
    }
  }

  /// Switch between front and back camera
  Future<void> switchCamera() async {
    if (_engine == null) return;

    try {
      await _engine!.switchCamera();
      // debugPrint removed for production
    } catch (e) {
      // debugPrint removed for production
      rethrow;
    }
  }

  /// Get local video view widget
  Widget getLocalVideoView() {
    if (_engine == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text('Camera not available', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return AgoraVideoView(
      controller: VideoViewController(rtcEngine: _engine!, canvas: const VideoCanvas(uid: 0)),
    );
  }

  /// Get remote video view widget for a specific user
  Widget getRemoteVideoView(int uid, String channelId) {
    if (_engine == null) {
      return Container(
        color: Colors.black87,
        child: const Center(
          child: Text('Loading...', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine!,
        canvas: VideoCanvas(uid: uid),
        connection: RtcConnection(channelId: channelId),
      ),
    );
  }

  /// Dispose and release all resources
  Future<void> dispose() async {
    // debugPrint removed for production

    try {
      // Stop preview if running
      await stopPreview();

      // Leave channel if joined
      if (_currentChannelName != null) {
        await leaveChannel();
      }

      // Disable audio and video modules completely before releasing
      if (_engine != null) {
        try {
          await _engine!.disableAudio();
          await _engine!.disableVideo();
          // debugPrint removed for production
        } catch (e) {
          // debugPrint removed for production
        }
      }

      // Release engine
      if (_engine != null) {
        await _engine!.release();
        _engine = null;
      }

      // Close stream controllers
      await _userJoinedController.close();
      await _userLeftController.close();
      await _errorController.close();

      _isInitialized = false;
      // debugPrint removed for production
    } catch (e) {
      // debugPrint removed for production
    }
  }
}
