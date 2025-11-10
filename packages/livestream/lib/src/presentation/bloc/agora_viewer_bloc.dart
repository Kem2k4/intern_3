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

// ==================== VIEWER-SPECIFIC EVENTS ====================

/// Join a livestream as viewer
class JoinAsViewer extends AgoraEvent {
  final String channelName;

  const JoinAsViewer(this.channelName);

  @override
  List<Object> get props => [channelName];
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

// ==================== VIEWER-SPECIFIC STATES ====================

/// Watching a livestream (viewer mode)
class AgoraWatching extends AgoraState {
  final String channelName;
  final int? broadcasterUid;
  final Set<int> remoteUids;

  const AgoraWatching({required this.channelName, this.broadcasterUid, this.remoteUids = const {}});

  @override
  List<Object> get props => [channelName, broadcasterUid ?? 0, remoteUids];

  AgoraWatching copyWith({String? channelName, int? broadcasterUid, Set<int>? remoteUids}) {
    return AgoraWatching(
      channelName: channelName ?? this.channelName,
      broadcasterUid: broadcasterUid ?? this.broadcasterUid,
      remoteUids: remoteUids ?? this.remoteUids,
    );
  }
}

// ==================== VIEWER BLOC ====================

/// BLoC for managing Agora livestream operations (Viewer mode)
class AgoraViewerBloc extends Bloc<AgoraEvent, AgoraState> {
  final AgoraRepository _repository;

  // Internal state tracking
  final Set<int> _remoteUids = {};
  StreamSubscription<int>? _userJoinedSub;
  StreamSubscription<int>? _userLeftSub;
  StreamSubscription<String>? _errorSub;

  AgoraViewerBloc(this._repository) : super(const AgoraInitial()) {
    // Register event handlers
    on<InitializeAgora>(_onInitializeAgora);
    on<JoinAsViewer>(_onJoinAsViewer);
    on<LeaveChannel>(_onLeaveChannel);
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

  /// Join livestream as viewer
  Future<void> _onJoinAsViewer(JoinAsViewer event, Emitter<AgoraState> emit) async {
    // Initialize Agora if not already done
    if (state is! AgoraInitialized) {
      emit(const AgoraLoading(message: 'Initializing Agora...'));

      final initResult = await _repository.initialize();
      initResult.fold(
        (error) => emit(AgoraError(error)),
        (_) {}, // Continue to join
      );
    }

    emit(const AgoraLoading(message: 'Joining livestream...'));

    final result = await _repository.joinAsViewer(
      event.channelName,
      AgoraConfigExtension.getTokenForChannel(event.channelName),
    );

    result.fold(
      (error) => emit(AgoraError(error)),
      (_) => emit(AgoraWatching(channelName: event.channelName, remoteUids: _remoteUids)),
    );
  }

  /// Leave channel
  Future<void> _onLeaveChannel(LeaveChannel event, Emitter<AgoraState> emit) async {
    emit(const AgoraLoading(message: 'Leaving channel...'));

    // Viewer: Actually leave channel but don't affect host's stream
    final result = await _repository.leaveChannel();
    result.fold((error) => emit(AgoraError(error)), (_) {
      // Reset internal state after successfully leaving
      _remoteUids.clear();
      emit(const AgoraInitialized());
    });
  }

  /// Handle user joined event
  void _onUserJoined(UserJoined event, Emitter<AgoraState> emit) {
    _remoteUids.add(event.uid);

    if (state is AgoraWatching) {
      final currentState = state as AgoraWatching;
      // Set broadcaster UID if not set yet (first user joined is likely the broadcaster)
      final newBroadcasterUid = currentState.broadcasterUid ?? event.uid;
      emit(
        currentState.copyWith(remoteUids: Set.from(_remoteUids), broadcasterUid: newBroadcasterUid),
      );
    }
  }

  /// Handle user left event
  void _onUserLeft(UserLeft event, Emitter<AgoraState> emit) {
    _remoteUids.remove(event.uid);

    if (state is AgoraWatching) {
      final currentState = state as AgoraWatching;
      emit(currentState.copyWith(remoteUids: Set.from(_remoteUids)));
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
