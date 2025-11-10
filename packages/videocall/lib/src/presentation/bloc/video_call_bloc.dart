import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../infrastructure/services/video_call_service.dart';
import '../../infrastructure/config/agora_config.dart';
import 'video_call_event.dart';
import 'video_call_state.dart';

class VideoCallBloc extends Bloc<VideoCallEvent, VideoCallState> {
  final VideoCallService videoCallService;
  StreamSubscription? _callSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _remoteUserSubscription;
  StreamSubscription? _mediaStateSubscription;

  // Store initialization parameters
  String? _channelName;
  String? _token;
  int? _uid;

  // Static reference to current bloc instance for FCM callbacks
  static VideoCallBloc? _currentInstance;

  VideoCallBloc(this.videoCallService) : super(VideoCallInitial()) {
    _currentInstance = this;

    on<InitializeVideoCall>(_onInitializeVideoCall);
    on<JoinVideoCall>(_onJoinVideoCall);
    on<LeaveVideoCall>(_onLeaveVideoCall);
    on<ToggleMute>(_onToggleMute);
    on<ToggleVideo>(_onToggleVideo);
    on<SwitchCamera>(_onSwitchCamera);
    on<VideoCallErrorOccurred>(_onVideoCallErrorOccurred);
    on<AcceptCall>(_onAcceptCall);
    on<RejectCall>(_onRejectCall);
    on<IncomingCallReceived>(_onIncomingCallReceived);
  }

  Future<void> _onInitializeVideoCall(
    InitializeVideoCall event,
    Emitter<VideoCallState> emit,
  ) async {
    try {
      emit(VideoCallLoading());

      // Store initialization parameters
      _channelName = event.channelName;
      _token = event.token;
      _uid = int.tryParse(event.uid) ?? event.uid.hashCode;

      // Check permissions
      final hasPermissions = await videoCallService.checkAndRequestPermissions();
      if (!hasPermissions) {
        emit(VideoCallError('Camera and microphone permissions are required'));
        return;
      }

      // TODO: Initialize Agora service is handled in joinCall
      // Set up stream subscriptions if needed

      emit(VideoCallJoined(channelName: event.channelName));
    } catch (e) {
      emit(VideoCallError(e.toString()));
    }
  }

  Future<void> _onJoinVideoCall(
    JoinVideoCall event,
    Emitter<VideoCallState> emit,
  ) async {
    if (state is VideoCallJoined) {
      // Already joined, do nothing
      return;
    }

    try {
      emit(VideoCallLoading());

      // Use stored parameters from initialization
      final channelName = _channelName ?? 'video_call';
      final token = _token ?? AgoraConfig.tempToken;
      final uid = _uid ?? 12345;

      await videoCallService.joinCall(channelName, token, uid);

      emit(VideoCallJoined(channelName: channelName));
    } catch (e) {
      emit(VideoCallError(e.toString()));
    }
  }

  Future<void> _onLeaveVideoCall(
    LeaveVideoCall event,
    Emitter<VideoCallState> emit,
  ) async {
    if (state is VideoCallJoined) {
      try {
        await videoCallService.leaveCall();
        emit(VideoCallEnded());
      } catch (e) {
        emit(VideoCallError(e.toString()));
      }
    }
  }

  Future<void> _onToggleMute(
    ToggleMute event,
    Emitter<VideoCallState> emit,
  ) async {
    if (state is VideoCallJoined) {
      final currentState = state as VideoCallJoined;
      try {
        await videoCallService.toggleAudio(!currentState.isMuted);
        emit(currentState.copyWith(isMuted: !currentState.isMuted));
      } catch (e) {
        emit(VideoCallError(e.toString()));
      }
    }
  }

  Future<void> _onToggleVideo(
    ToggleVideo event,
    Emitter<VideoCallState> emit,
  ) async {
    if (state is VideoCallJoined) {
      final currentState = state as VideoCallJoined;
      try {
        await videoCallService.toggleVideo(!currentState.isVideoOn);
        emit(currentState.copyWith(isVideoOn: !currentState.isVideoOn));
      } catch (e) {
        emit(VideoCallError(e.toString()));
      }
    }
  }

  Future<void> _onSwitchCamera(
    SwitchCamera event,
    Emitter<VideoCallState> emit,
  ) async {
    if (state is VideoCallJoined) {
      final currentState = state as VideoCallJoined;
      try {
        await videoCallService.switchCamera();
        emit(currentState.copyWith(isFrontCamera: !currentState.isFrontCamera));
      } catch (e) {
        emit(VideoCallError(e.toString()));
      }
    }
  }

  Future<void> _onAcceptCall(
    AcceptCall event,
    Emitter<VideoCallState> emit,
  ) async {
    try {
      await videoCallService.acceptCall(event.callId);
      // TODO: Navigate to calling screen or update state
    } catch (e) {
      emit(VideoCallError(e.toString()));
    }
  }

  Future<void> _onRejectCall(
    RejectCall event,
    Emitter<VideoCallState> emit,
  ) async {
    try {
      await videoCallService.rejectCall(event.callId);
      // Call rejected, stay in current state or emit ended
    } catch (e) {
      emit(VideoCallError(e.toString()));
    }
  }

  Future<void> _onIncomingCallReceived(
    IncomingCallReceived event,
    Emitter<VideoCallState> emit,
  ) async {
    // Emit incoming call state to show the dialog
    emit(IncomingCall(
      callId: event.callId,
      callerId: event.callerId,
      callerName: event.callerName,
      callerAvatar: event.callerAvatar,
      channelName: event.channelName,
    ));
  }

  Future<void> _onVideoCallErrorOccurred(
    VideoCallErrorOccurred event,
    Emitter<VideoCallState> emit,
  ) async {
    emit(VideoCallError(event.error));
  }

  /// Static method to handle incoming call from FCM
  static void handleIncomingCall(Map<String, dynamic> data) {
    final callerId = data['callerId'] as String?;
    final callerName = data['callerName'] as String?;
    final callerAvatar = data['callerAvatar'] as String?;
    final channelName = data['channelName'] as String?;
    final callId = data['callId'] as String?;

    if (callerId != null &&
        callerName != null &&
        callerAvatar != null &&
        channelName != null &&
        callId != null &&
        _currentInstance != null) {
      _currentInstance!.add(IncomingCallReceived(
        callId: callId,
        callerId: callerId,
        callerName: callerName,
        callerAvatar: callerAvatar,
        channelName: channelName,
      ));
    }
  }

  @override
  Future<void> close() {
    _callSubscription?.cancel();
    _connectionSubscription?.cancel();
    _remoteUserSubscription?.cancel();
    _mediaStateSubscription?.cancel();
    videoCallService.dispose();
    return super.close();
  }
}