// ignore_for_file: use_build_context_synchronously

import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:videocall/videocall.dart';

/// Home page displayed after user login (login functionality to be implemented later)
/// Displays the main bottom navigation bar with dynamic top bar title
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Tab titles corresponding to bottom navigation items
  static const List<String> _tabTitles = <String>['Chats', 'Inbox', 'Maps', 'Live', 'Uploads'];

  @override
  void initState() {
    super.initState();
    // FCM listener is already set up in main.dart
    // No need for additional DB listener since we use FCM for incoming calls
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handleLogout() async {
    // Logout from Firebase
    final authRepo = FirebaseAuthRepository();
    await authRepo.signOut();

    // Clear local database
    final appDatabase = AppDatabase();
    await appDatabase.setAllUsersLoggedOut();

    // Navigate to login
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VideoCallBloc, VideoCallState>(
      listener: (context, state) {
        if (state is IncomingCall) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => IncomingCallScreen(
                callerName: state.callerName,
                callerAvatar: state.callerAvatar,
                onAccept: () {
                  context.read<VideoCallBloc>().add(AcceptCall(state.callId));
                  context.read<VideoCallBloc>().add(MonitorCallStatus(state.callId));
                  context.read<VideoCallBloc>().add(InitializeVideoCall(
                    channelName: state.channelName,
                    token: AgoraConfig.tempToken,
                    uid: '',
                  ));
                  context.read<VideoCallBloc>().add(JoinVideoCall());
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => CallingScreen(
                        callerName: state.callerName,
                        callerAvatar: state.callerAvatar,
                        isMuted: false,
                        isCameraOff: false,
                        isFrontCamera: true,
                        onToggleMute: () => context.read<VideoCallBloc>().add(ToggleMute()),
                        onToggleCamera: () => context.read<VideoCallBloc>().add(ToggleVideo()),
                        onSwitchCamera: () => context.read<VideoCallBloc>().add(SwitchCamera()),
                        onHangUp: () {
                          context.read<VideoCallBloc>().add(LeaveVideoCall());
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  );
                },
                onDecline: () {
                  context.read<VideoCallBloc>().add(RejectCall(state.callId));
                  Navigator.of(context).pop();
                },
              ),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: TopNavBar(title: _tabTitles[_selectedIndex], onLogout: _handleLogout),
        body: MainBottomNavBar(selectedIndex: _selectedIndex, onTabChanged: _onTabChanged),
      ),
    );
  }
}
// incoming call overlay removed — feature disabled
