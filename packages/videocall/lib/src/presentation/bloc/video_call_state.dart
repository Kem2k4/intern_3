import 'package:equatable/equatable.dart';

abstract class VideoCallState extends Equatable {
  const VideoCallState();

  @override
  List<Object?> get props => [];
}

class VideoCallInitial extends VideoCallState {}

class VideoCallLoading extends VideoCallState {}

class IncomingCall extends VideoCallState {
  final String callId;
  final String callerId;
  final String callerName;
  final String callerAvatar;
  final String channelName;

  const IncomingCall({
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.callerAvatar,
    required this.channelName,
  });

  @override
  List<Object?> get props => [callId, callerId, callerName, callerAvatar, channelName];
}

class VideoCallJoined extends VideoCallState {
  final String channelName;
  final bool isMuted;
  final bool isVideoOn;
  final bool isFrontCamera;
  final String? remoteUserName;
  final String? remoteUserAvatar;

  const VideoCallJoined({
    required this.channelName,
    this.isMuted = false,
    this.isVideoOn = true,
    this.isFrontCamera = true,
    this.remoteUserName,
    this.remoteUserAvatar,
  });

  @override
  List<Object?> get props => [channelName, isMuted, isVideoOn, isFrontCamera, remoteUserName, remoteUserAvatar];

  VideoCallJoined copyWith({
    String? channelName,
    bool? isMuted,
    bool? isVideoOn,
    bool? isFrontCamera,
    String? remoteUserName,
    String? remoteUserAvatar,
  }) {
    return VideoCallJoined(
      channelName: channelName ?? this.channelName,
      isMuted: isMuted ?? this.isMuted,
      isVideoOn: isVideoOn ?? this.isVideoOn,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      remoteUserName: remoteUserName ?? this.remoteUserName,
      remoteUserAvatar: remoteUserAvatar ?? this.remoteUserAvatar,
    );
  }
}

class VideoCallEnded extends VideoCallState {}

class VideoCallError extends VideoCallState {
  final String error;

  const VideoCallError(this.error);

  @override
  List<Object?> get props => [error];
}