import 'package:equatable/equatable.dart';

abstract class VideoCallEvent extends Equatable {
  const VideoCallEvent();

  @override
  List<Object?> get props => [];
}

class InitializeVideoCall extends VideoCallEvent {
  final String channelName;
  final String token;
  final String uid;

  const InitializeVideoCall({
    required this.channelName,
    required this.token,
    required this.uid,
  });

  @override
  List<Object?> get props => [channelName, token, uid];
}

class JoinVideoCall extends VideoCallEvent {}

class LeaveVideoCall extends VideoCallEvent {}

class ToggleMute extends VideoCallEvent {}

class ToggleVideo extends VideoCallEvent {}

class SwitchCamera extends VideoCallEvent {}

class AcceptCall extends VideoCallEvent {
  final String callId;

  const AcceptCall(this.callId);

  @override
  List<Object?> get props => [callId];
}

class RejectCall extends VideoCallEvent {
  final String callId;

  const RejectCall(this.callId);

  @override
  List<Object?> get props => [callId];
}

class IncomingCallReceived extends VideoCallEvent {
  final String callId;
  final String callerId;
  final String callerName;
  final String callerAvatar;
  final String channelName;

  const IncomingCallReceived({
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.callerAvatar,
    required this.channelName,
  });

  @override
  List<Object?> get props => [callId, callerId, callerName, callerAvatar, channelName];
}

class VideoCallErrorOccurred extends VideoCallEvent {
  final String error;

  const VideoCallErrorOccurred(this.error);

  @override
  List<Object?> get props => [error];
}