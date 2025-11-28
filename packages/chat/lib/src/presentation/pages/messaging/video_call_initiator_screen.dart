// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:videocall/videocall.dart';


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

  @override
  void initState() {
    super.initState();

    // Navigate to CallingScreen immediately and start the call process
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final videoCallBloc = context.read<VideoCallBloc>();
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CallingScreen(
              callerName: widget.receiverName,
              callerAvatar: widget.receiverAvatar,
              isMuted: false,
              isCameraOff: false,
              isFrontCamera: true,
              isRinging: true, // Start in ringing state
              onToggleMute: () => videoCallBloc.add(ToggleMute()),
              onToggleCamera: () => videoCallBloc.add(ToggleVideo()),
              onSwitchCamera: () => videoCallBloc.add(SwitchCamera()),
              onHangUp: () {
                if (!videoCallBloc.isClosed) {
                  videoCallBloc.add(LeaveVideoCall());
                }
              },
            ),
          ),
        );
        _initiateCall(videoCallBloc);
      }
    });
  }

  Future<void> _initiateCall(VideoCallBloc videoCallBloc) async {
    try {
      // Check if Agora is properly configured
      if (!AgoraConfig.isConfigured) {
        _showErrorAndPop('Video call is not configured. Please set up Agora credentials first.');
        return;
      }

      // Check if temporary token might be expired
      if (AgoraConfig.isTempTokenExpired) {
        _showErrorAndPop('Video call token has expired. Please generate a new token.');
        return;
      }

      final hasPermissions = await videoCallBloc.videoCallService.checkAndRequestPermissions();
      if (!hasPermissions) {
        _showErrorAndPop('Camera and microphone permissions are required.');
        return;
      }

      // Initiate call (create DB record and trigger FCM)
      final callId = await videoCallBloc.videoCallService.initiateCall(
        callerId: widget.currentUserId,
        callerName: widget.currentUserName,
        callerAvatar: widget.currentUserAvatar,
        receiverId: widget.receiverId,
        receiverName: widget.receiverName,
        receiverAvatar: widget.receiverAvatar,
      );
      debugPrint('Call initiated with ID: $callId');

      // Monitor call status
      videoCallBloc.add(MonitorCallStatus(callId));

      // Initialize video call
      videoCallBloc.add(InitializeVideoCall(
        channelName: AgoraConfig.testChannelName,
        token: AgoraConfig.tempToken,
        uid: widget.currentUserId,
      ));

      // Join the call
      videoCallBloc.add(JoinVideoCall());
    } catch (e) {
      debugPrint('Error initiating call: $e');
      _showErrorAndPop('Failed to start call: $e');
    }
  }

  void _showErrorAndPop(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This screen will be replaced immediately, so we can just show a loader.
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}