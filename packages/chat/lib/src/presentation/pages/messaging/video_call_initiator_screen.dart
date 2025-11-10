// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:videocall/src/presentation/bloc/video_call_bloc.dart';
import 'package:videocall/src/presentation/bloc/video_call_event.dart';
import 'package:videocall/src/presentation/bloc/video_call_state.dart';
import 'package:videocall/src/presentation/screens/calling_screen.dart';
import 'package:videocall/src/presentation/screens/waiting_screen.dart';
import 'package:videocall/src/infrastructure/services/video_call_service.dart';
import 'package:videocall/src/data/repositories/video_call_repository.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:videocall/src/data/datasources/video_call_firebase_data_source.dart';
import 'package:videocall/src/infrastructure/services/agora_service.dart' as agora_service;
import 'package:videocall/src/infrastructure/config/agora_config.dart';
import 'package:auth/auth.dart';

class VideoCallInitiatorScreen extends StatefulWidget {
  final String callId;
  final String currentUserId;
  final String currentUserName;
  final String currentUserAvatar;
  final String receiverId;
  final String receiverName;
  final String receiverAvatar;

  const VideoCallInitiatorScreen({
    super.key,
    required this.callId,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserAvatar,
    required this.receiverId,
    required this.receiverName,
    required this.receiverAvatar,
  });

  @override
  State<VideoCallInitiatorScreen> createState() => _VideoCallInitiatorScreenState();
}

class _VideoCallInitiatorScreenState extends State<VideoCallInitiatorScreen> {
  late VideoCallBloc _videoCallBloc;
  late VideoCallService _videoCallService;

  @override
  void initState() {
    super.initState();

    // Initialize services
    final database = FirebaseDatabase.instance;
    final dataSource = VideoCallFirebaseDataSource(database);
    final repository = VideoCallRepositoryImpl(dataSource);
    final agoraService = agora_service.AgoraServiceImpl();
    final authRepository = FirebaseAuthRepository();
    _videoCallService = VideoCallService(repository, agoraService, authRepository);

    // Initialize BLoC
    _videoCallBloc = VideoCallBloc(_videoCallService);

    // Start the call
    _initiateCall();
  }

  Future<void> _initiateCall() async {
    try {
      // Check if Agora is properly configured
      if (!AgoraConfig.isConfigured) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video call is not configured. Please set up Agora credentials first.'),
                duration: Duration(seconds: 5),
              ),
            );
            Navigator.of(context).pop();
          }
        });
        return;
      }

      // Check if temporary token might be expired
      if (AgoraConfig.isTempTokenExpired) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video call token has expired. Please generate a new token from Agora Console and update AgoraConfig.tempToken'),
                duration: Duration(seconds: 8),
              ),
            );
            Navigator.of(context).pop();
          }
        });
        return;
      }

      // Show loading state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Initializing video call...')),
          );
        }
      });

      final hasPermissions = await _videoCallService.checkAndRequestPermissions();
      if (!mounted) return;
      if (!hasPermissions) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Camera and microphone permissions are required')),
            );
            Navigator.of(context).pop();
          }
        });
        return;
      }

      // Initialize video call
      _videoCallBloc.add(InitializeVideoCall(
        channelName: AgoraConfig.testChannelName, // Use fixed channel name "video_call"
        token: AgoraConfig.tempToken, // Use temporary token for testing
        uid: widget.currentUserId,
      ));

      // Join the call
      _videoCallBloc.add(JoinVideoCall());
    } catch (e) {
      debugPrint('Error initiating call: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to start call: $e')),
          );
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  void dispose() {
    _videoCallBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _videoCallBloc,
      child: BlocBuilder<VideoCallBloc, VideoCallState>(
        builder: (context, state) {
          if (state is VideoCallInitial || state is VideoCallLoading) {
            return WaitingScreen(
              callerName: widget.receiverName,
              callerAvatar: widget.receiverAvatar,
              onHangUp: () => Navigator.of(context).pop(),
            );
          } else if (state is VideoCallJoined) {
            return CallingScreen(
              callerName: widget.receiverName,
              callerAvatar: widget.receiverAvatar,
              isMuted: state.isMuted,
              isCameraOff: !state.isVideoOn,
              isFrontCamera: state.isFrontCamera,
              onToggleMute: () => _videoCallBloc.add(ToggleMute()),
              onToggleCamera: () => _videoCallBloc.add(ToggleVideo()),
              onSwitchCamera: () => _videoCallBloc.add(SwitchCamera()),
              onHangUp: () {
                _videoCallBloc.add(LeaveVideoCall());
                Navigator.of(context).pop();
              },
            );
          } else if (state is VideoCallError) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Call Error: ${state.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Back'),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return WaitingScreen(
              callerName: widget.receiverName,
              callerAvatar: widget.receiverAvatar,
              onHangUp: () => Navigator.of(context).pop(),
            );
          }
        },
      ),
    );
  }
}