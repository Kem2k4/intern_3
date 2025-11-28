import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../presentation/bloc/video_call_bloc.dart';
import '../../presentation/bloc/video_call_state.dart';
import '../../presentation/bloc/video_call_event.dart';
import 'dart:async';

class CallingScreen extends StatefulWidget {
  final String callerName;
  final String callerAvatar;
  final bool isMuted;
  final bool isCameraOff;
  final bool isFrontCamera;
  final bool isRinging;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleCamera;
  final VoidCallback onSwitchCamera;
  final VoidCallback onHangUp;

  const CallingScreen({
    super.key,
    required this.callerName,
    required this.callerAvatar,
    required this.isMuted,
    required this.isCameraOff,
    required this.isFrontCamera,
    this.isRinging = false,
    required this.onToggleMute,
    required this.onToggleCamera,
    required this.onSwitchCamera,
    required this.onHangUp,
  });

  @override
  State<CallingScreen> createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen> {
  int? _remoteUid;
  StreamSubscription? _remoteSub;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<VideoCallBloc>();
    _remoteSub = bloc.videoCallService.agoraService.remoteUserStream.listen((participant) {
      setState(() {
        _remoteUid = int.tryParse(participant.userId);
        _timeoutTimer?.cancel(); // Cancel timeout when remote user joins
      });
    });

    if (widget.isRinging) {
      _timeoutTimer = Timer(const Duration(seconds: 30), () {
        if (mounted && _remoteUid == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No answer from receiver')),
          );
          context.read<VideoCallBloc>().add(LeaveVideoCall());
        }
      });
    }
  }

  @override
  void dispose() {
    _remoteSub?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<VideoCallBloc>();
    final agora = bloc.videoCallService.agoraService;

    String channel = 'video_call';
    final state = context.watch<VideoCallBloc>().state;
    
    bool isMuted = widget.isMuted;
    bool isCameraOff = widget.isCameraOff;

    if (state is VideoCallJoined) {
      channel = state.channelName;
      isMuted = state.isMuted;
      isCameraOff = !state.isVideoOn;
    }

    return BlocListener<VideoCallBloc, VideoCallState>(
      listener: (context, state) {
        if (state is VideoCallEnded) {
          Navigator.of(context).pop();
        }
        if (state is VideoCallError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error)),
          );
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: _remoteUid != null
                  ? agora.remoteVideoView(_remoteUid!, channel)
                  : Container(color: Colors.black),
            ),
            Positioned(
              right: 16,
              top: 100,
              width: 120,
              height: 180,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: DecoratedBox(
                  // Use withValues instead of deprecated withOpacity
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2)),
                  child: agora.localVideoView(),
                ),
              ),
            ),
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(widget.callerAvatar),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.callerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.isRinging && _remoteUid == null)
                        const Text(
                          'Ringing...',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: widget.onToggleMute,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isMuted ? Colors.red : Colors.white24,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(15),
                    ),
                    child: Icon(
                      isMuted ? Icons.mic_off : Icons.mic,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                      widget.onHangUp();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(15),
                    ),
                    child: const Icon(
                      Icons.call_end,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: widget.onToggleCamera,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCameraOff ? Colors.red : Colors.white24,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(15),
                    ),
                    child: Icon(
                      isCameraOff ? Icons.videocam_off : Icons.videocam,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: widget.onSwitchCamera,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white24,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(15),
                    ),
                    child: const Icon(
                      Icons.flip_camera_ios,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}