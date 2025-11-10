import 'package:dartz/dartz.dart';
import '../../infrastructure/services/agora_service.dart';

/// Repository interface for Agora operations
/// Provides a clean abstraction layer over AgoraService
abstract class AgoraRepository {
  /// Initialize Agora RTC Engine
  Future<Either<String, void>> initialize();

  /// Start camera preview (before going live)
  Future<Either<String, void>> startPreview();

  /// Stop camera preview
  Future<Either<String, void>> stopPreview();

  /// End stream - Completely disable camera and microphone access
  Future<Either<String, void>> endStream();

  /// Join channel as broadcaster (host)
  Future<Either<String, void>> joinAsBroadcaster(String channelName, [String? token]);

  /// Join channel as viewer (audience)
  Future<Either<String, void>> joinAsViewer(String channelName, [String? token]);

  /// Leave current channel
  Future<Either<String, void>> leaveChannel();

  /// Mute/unmute local audio
  Future<Either<String, void>> muteAudio(bool mute);

  /// Mute/unmute local video
  Future<Either<String, void>> muteVideo(bool mute);

  /// Switch between front/back camera
  Future<Either<String, void>> switchCamera();

  /// Dispose and release all resources
  Future<void> dispose();

  /// Get direct access to Agora service (for advanced use cases)
  AgoraService get service;
}

/// Implementation of AgoraRepository
class AgoraRepositoryImpl implements AgoraRepository {
  final AgoraService _agoraService;

  AgoraRepositoryImpl(this._agoraService);

  @override
  AgoraService get service => _agoraService;

  @override
  Future<Either<String, void>> initialize() async {
    try {
      await _agoraService.initialize();
      return const Right(null);
    } catch (e) {
      return Left('Failed to initialize: $e');
    }
  }

  @override
  Future<Either<String, void>> startPreview() async {
    try {
      await _agoraService.startPreview();
      return const Right(null);
    } catch (e) {
      return Left('Failed to start preview: $e');
    }
  }

  @override
  Future<Either<String, void>> stopPreview() async {
    try {
      await _agoraService.stopPreview();
      return const Right(null);
    } catch (e) {
      return Left('Failed to stop preview: $e');
    }
  }

  @override
  Future<Either<String, void>> endStream() async {
    try {
      await _agoraService.endStream();
      return const Right(null);
    } catch (e) {
      return Left('Failed to end stream: $e');
    }
  }

  @override
  Future<Either<String, void>> joinAsBroadcaster(String channelName, [String? token]) async {
    try {
      await _agoraService.joinChannelAsBroadcaster(channelName, token: token);
      return const Right(null);
    } catch (e) {
      return Left('Failed to join as broadcaster: $e');
    }
  }

  @override
  Future<Either<String, void>> joinAsViewer(String channelName, [String? token]) async {
    try {
      await _agoraService.joinChannelAsAudience(channelName, token: token);
      return const Right(null);
    } catch (e) {
      return Left('Failed to join as viewer: $e');
    }
  }

  @override
  Future<Either<String, void>> leaveChannel() async {
    try {
      await _agoraService.leaveChannel();
      return const Right(null);
    } catch (e) {
      return Left('Failed to leave channel: $e');
    }
  }

  @override
  Future<Either<String, void>> muteAudio(bool mute) async {
    try {
      await _agoraService.muteLocalAudio(mute);
      return const Right(null);
    } catch (e) {
      return Left('Failed to ${mute ? 'mute' : 'unmute'} audio: $e');
    }
  }

  @override
  Future<Either<String, void>> muteVideo(bool mute) async {
    try {
      await _agoraService.muteLocalVideo(mute);
      return const Right(null);
    } catch (e) {
      return Left('Failed to ${mute ? 'mute' : 'unmute'} video: $e');
    }
  }

  @override
  Future<Either<String, void>> switchCamera() async {
    try {
      await _agoraService.switchCamera();
      return const Right(null);
    } catch (e) {
      return Left('Failed to switch camera: $e');
    }
  }

  /// Dispose and release all resources
  @override
  Future<void> dispose() async {
    await _agoraService.dispose();
  }
}
