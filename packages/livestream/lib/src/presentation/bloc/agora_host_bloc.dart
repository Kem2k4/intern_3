import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';
import '../../domain/repositories/agora_repository.dart';
import '../../infrastructure/config/agora_config.dart';

// ==================== SHARED EVENTS ====================

/// Base event class for Agora BLoC
abstract class AgoraEvent extends Equatable {
  const AgoraEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize Agora engine
class InitializeAgora extends AgoraEvent {
  const InitializeAgora();
}

/// Leave current channel
class LeaveChannel extends AgoraEvent {
  const LeaveChannel();
}

/// Toggle audio mute/unmute
class ToggleMic extends AgoraEvent {
  const ToggleMic();
}

/// Toggle video mute/unmute
class ToggleCamera extends AgoraEvent {
  const ToggleCamera();
}

/// Switch between front/back camera
class SwitchCamera extends AgoraEvent {
  const SwitchCamera();
}

/// User joined channel event
class UserJoined extends AgoraEvent {
  final int uid;

  const UserJoined(this.uid);

  @override
  List<Object> get props => [uid];
}

/// User left channel event
class UserLeft extends AgoraEvent {
  final int uid;

  const UserLeft(this.uid);

  @override
  List<Object> get props => [uid];
}

/// Error occurred event
class AgoraErrorOccurred extends AgoraEvent {
  final String message;

  const AgoraErrorOccurred(this.message);

  @override
  List<Object> get props => [message];
}

// ==================== HOST-SPECIFIC EVENTS ====================

/// Start camera preview before going live
class StartPreview extends AgoraEvent {
  final String channelName;

  const StartPreview(this.channelName);

  @override
  List<Object> get props => [channelName];
}

/// Start broadcasting (go live) from preview
class StartBroadcasting extends AgoraEvent {
  const StartBroadcasting();
}

// ==================== SHARED STATES ====================

/// Base state class for Agora BLoC
abstract class AgoraState extends Equatable {
  const AgoraState();

  @override
  List<Object> get props => [];
}

/// Initial state - nothing initialized yet
class AgoraInitial extends AgoraState {
  const AgoraInitial();
}

/// Loading state - operation in progress
class AgoraLoading extends AgoraState {
  final String? message;

  const AgoraLoading({this.message});

  @override
  List<Object> get props => [message ?? ''];
}

/// Agora engine initialized and ready
class AgoraInitialized extends AgoraState {
  const AgoraInitialized();
}

/// Error state
class AgoraError extends AgoraState {
  final String message;
  final AgoraState? previousState;

  const AgoraError(this.message, {this.previousState});

  @override
  List<Object> get props => [message, previousState ?? AgoraInitial()];
}

// ==================== HOST-SPECIFIC STATES ====================

/// Camera preview active (before going live)
class AgoraPreview extends AgoraState {
  final String channelName;
  final bool isMicMuted;
  final bool isVideoMuted;

  const AgoraPreview({
    required this.channelName,
    this.isMicMuted = false,
    this.isVideoMuted = false,
  });

  @override
  List<Object> get props => [channelName, isMicMuted, isVideoMuted];

  AgoraPreview copyWith({String? channelName, bool? isMicMuted, bool? isVideoMuted}) {
    return AgoraPreview(
      channelName: channelName ?? this.channelName,
      isMicMuted: isMicMuted ?? this.isMicMuted,
      isVideoMuted: isVideoMuted ?? this.isVideoMuted,
    );
  }
}

/// Broadcasting live to channel (host mode)
class AgoraBroadcasting extends AgoraState {
  final String channelName;
  final bool isMicMuted;
  final bool isVideoMuted;
  final Set<int> viewerUids;
  final int viewerCount;

  const AgoraBroadcasting({
    required this.channelName,
    this.isMicMuted = false,
    this.isVideoMuted = false,
    this.viewerUids = const {},
    this.viewerCount = 0,
  });

  @override
  List<Object> get props => [channelName, isMicMuted, isVideoMuted, viewerUids, viewerCount];

  AgoraBroadcasting copyWith({
    String? channelName,
    bool? isMicMuted,
    bool? isVideoMuted,
    Set<int>? viewerUids,
    int? viewerCount,
  }) {
    return AgoraBroadcasting(
      channelName: channelName ?? this.channelName,
      isMicMuted: isMicMuted ?? this.isMicMuted,
      isVideoMuted: isVideoMuted ?? this.isVideoMuted,
      viewerUids: viewerUids ?? this.viewerUids,
      viewerCount: viewerCount ?? this.viewerCount,
    );
  }
}

// ==================== HOST BLOC ====================

/// BLoC for managing Agora livestream operations (Host mode)
class AgoraHostBloc extends Bloc<AgoraEvent, AgoraState> {
  final AgoraRepository _repository;

  // Internal state tracking
  bool _isMicMuted = false;
  bool _isVideoMuted = false;
  final Set<int> _remoteUids = {};
  StreamSubscription<int>? _userJoinedSub;
  StreamSubscription<int>? _userLeftSub;
  StreamSubscription<String>? _errorSub;

  AgoraHostBloc(this._repository) : super(const AgoraInitial()) {
    // Register event handlers
    on<InitializeAgora>(_onInitializeAgora);
    on<StartPreview>(_onStartPreview);
    on<StartBroadcasting>(_onStartBroadcasting);
    on<LeaveChannel>(_onLeaveChannel);
    on<ToggleMic>(_onToggleMic);
    on<ToggleCamera>(_onToggleCamera);
    on<SwitchCamera>(_onSwitchCamera);
    on<UserJoined>(_onUserJoined);
    on<UserLeft>(_onUserLeft);
    on<AgoraErrorOccurred>(_onAgoraError);

    // Subscribe to Agora service events
    _subscribeToServiceEvents();
  }

  /// Get the repository instance
  AgoraRepository get repository => _repository;

  /// Subscribe to Agora service event streams
  void _subscribeToServiceEvents() {
    _userJoinedSub = _repository.service.onUserJoined.listen((uid) {
      add(UserJoined(uid));
    });

    _userLeftSub = _repository.service.onUserLeft.listen((uid) {
      add(UserLeft(uid));
    });

    _errorSub = _repository.service.onError.listen((message) {
      add(AgoraErrorOccurred(message));
    });
  }

  /// Initialize Agora engine
  Future<void> _onInitializeAgora(InitializeAgora event, Emitter<AgoraState> emit) async {
    emit(const AgoraLoading(message: 'Initializing Agora...'));

    final result = await _repository.initialize();
    result.fold((error) => emit(AgoraError(error)), (_) => emit(const AgoraInitialized()));
  }

  /// Start camera preview
  Future<void> _onStartPreview(StartPreview event, Emitter<AgoraState> emit) async {
    emit(const AgoraLoading(message: 'Starting preview...'));

    // Initialize first if not already
    if (state is! AgoraInitialized && state is! AgoraPreview && state is! AgoraBroadcasting) {
      final initResult = await _repository.initialize();
      initResult.fold(
        (error) {
          emit(AgoraError(error));
          return;
        },
        (_) {}, // Success, continue
      );
    }

    final result = await _repository.startPreview();
    result.fold(
      (error) => emit(AgoraError(error)),
      (_) => emit(
        AgoraPreview(
          channelName: event.channelName,
          isMicMuted: _isMicMuted,
          isVideoMuted: _isVideoMuted,
        ),
      ),
    );
  }

  /// Start broadcasting from preview
  Future<void> _onStartBroadcasting(StartBroadcasting event, Emitter<AgoraState> emit) async {
    if (state is! AgoraPreview) {
      // print('❌ Cannot start broadcasting: Not in preview state, current state: $state');
      return;
    }

    final previewState = state as AgoraPreview;
    // print('📺 Starting broadcast for channel: ${previewState.channelName}');
    emit(const AgoraLoading(message: 'Going live...'));

    final token = AgoraConfigExtension.getTokenForChannel(previewState.channelName);
    // print('🔑 Using token for broadcast: ${token != null ? 'Token available' : 'No token'}');

    final result = await _repository.joinAsBroadcaster(previewState.channelName, token);

    result.fold(
      (error) {
        // print('❌ Failed to start broadcasting: $error');
        emit(AgoraError(error, previousState: previewState));
      },
      (_) {
        // print('✅ Successfully started broadcasting on channel: ${previewState.channelName}');
        emit(
          AgoraBroadcasting(
            channelName: previewState.channelName,
            isMicMuted: _isMicMuted,
            isVideoMuted: _isVideoMuted,
            viewerUids: _remoteUids,
            viewerCount: _remoteUids.length,
          ),
        );
      },
    );
  }

  /// Leave channel
  Future<void> _onLeaveChannel(LeaveChannel event, Emitter<AgoraState> emit) async {
    emit(const AgoraLoading(message: 'Leaving channel...'));

    // Host: Actually leave channel and cleanup stream
    final result = await _repository.leaveChannel();
    result.fold((error) => emit(AgoraError(error)), (_) {
      // Reset internal state
      _isMicMuted = false;
      _isVideoMuted = false;
      _remoteUids.clear();
      emit(const AgoraInitialized());
    });
  }

  /// Toggle mic mute/unmute
  Future<void> _onToggleMic(ToggleMic event, Emitter<AgoraState> emit) async {
    _isMicMuted = !_isMicMuted;

    final result = await _repository.muteAudio(_isMicMuted);
    result.fold(
      (error) {
        // Revert on error
        _isMicMuted = !_isMicMuted;
        emit(AgoraError(error, previousState: state));
      },
      (_) {
        // Update current state with new audio status
        if (state is AgoraPreview) {
          emit((state as AgoraPreview).copyWith(isMicMuted: _isMicMuted));
        } else if (state is AgoraBroadcasting) {
          emit((state as AgoraBroadcasting).copyWith(isMicMuted: _isMicMuted));
        }
      },
    );
  }

  /// Toggle camera mute/unmute
  Future<void> _onToggleCamera(ToggleCamera event, Emitter<AgoraState> emit) async {
    _isVideoMuted = !_isVideoMuted;

    final result = await _repository.muteVideo(_isVideoMuted);
    result.fold(
      (error) {
        // Revert on error
        _isVideoMuted = !_isVideoMuted;
        emit(AgoraError(error, previousState: state));
      },
      (_) {
        // Update current state with new video status
        if (state is AgoraPreview) {
          emit((state as AgoraPreview).copyWith(isVideoMuted: _isVideoMuted));
        } else if (state is AgoraBroadcasting) {
          emit((state as AgoraBroadcasting).copyWith(isVideoMuted: _isVideoMuted));
        }
      },
    );
  }

  /// Switch camera
  Future<void> _onSwitchCamera(SwitchCamera event, Emitter<AgoraState> emit) async {
    final result = await _repository.switchCamera();
    result.fold(
      (error) => emit(AgoraError(error, previousState: state)),
      (_) {}, // No state change needed
    );
  }

  /// Handle user joined event
  void _onUserJoined(UserJoined event, Emitter<AgoraState> emit) {
    _remoteUids.add(event.uid);

    if (state is AgoraBroadcasting) {
      final currentState = state as AgoraBroadcasting;
      emit(
        currentState.copyWith(viewerUids: Set.from(_remoteUids), viewerCount: _remoteUids.length),
      );
    }
  }

  /// Handle user left event
  void _onUserLeft(UserLeft event, Emitter<AgoraState> emit) {
    _remoteUids.remove(event.uid);

    if (state is AgoraBroadcasting) {
      final currentState = state as AgoraBroadcasting;
      emit(
        currentState.copyWith(viewerUids: Set.from(_remoteUids), viewerCount: _remoteUids.length),
      );
    }
  }

  /// Handle Agora errors
  void _onAgoraError(AgoraErrorOccurred event, Emitter<AgoraState> emit) {
    emit(AgoraError(event.message, previousState: state));
  }

  @override
  Future<void> close() {
    // Cancel all subscriptions (don't dispose repository as it's shared at app level)
    _userJoinedSub?.cancel();
    _userLeftSub?.cancel();
    _errorSub?.cancel();
    return super.close();
  }
}
