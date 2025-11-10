import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:livestream/livestream.dart';
import 'package:chat/chat.dart';
import 'package:map_tiler/map_tiler.dart';

/// A stateful widget for the main bottom navigation bar.
class MainBottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const MainBottomNavBar({super.key, required this.selectedIndex, required this.onTabChanged});

  @override
  State<MainBottomNavBar> createState() => _MainBottomNavBarState();
}

class _MainBottomNavBarState extends State<MainBottomNavBar> {
  // Placeholder widgets for each tab. Replace with your actual screen widgets.
  List<Widget> _buildWidgetOptions(BuildContext context) => <Widget>[
    BlocProvider(
      create: (context) {
        final firestore = FirebaseFirestore.instance;
        final realtimeDb = FirebaseDatabase.instance;
        final auth = FirebaseAuth.instance;
        final messagingService = FirebaseMessagingService(firestore, realtimeDb);
        final chatRepository = ChatRepositoryImpl(firestore, auth, messagingService);
        return ChatBloc(chatRepository);
      },
      child: const MessageListPage(),
    ),
    const Center(child: Text('Index 1: In')),
    const MapPage(), // Maps tab - using map_tiler package
    const LivestreamMainPage(), // Live tab
    const Center(child: Text('Index 4: Uploads')),
  ];

  void _onItemTapped(int index) {
    widget.onTabChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _buildWidgetOptions(context).elementAt(widget.selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.inbox_outlined), label: 'In'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Maps'),
          BottomNavigationBarItem(icon: Icon(Icons.live_tv_outlined), label: 'Live'),
          BottomNavigationBarItem(icon: Icon(Icons.upload_outlined), label: 'Uploads'),
        ],
        currentIndex: widget.selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
