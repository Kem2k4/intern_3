import 'package:flutter/material.dart';

class WaitingScreen extends StatelessWidget {
  final String callerName;
  final String callerAvatar;
  final VoidCallback onHangUp;

  const WaitingScreen({
    super.key,
    required this.callerName,
    required this.callerAvatar,
    required this.onHangUp,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 80,
              backgroundImage: NetworkImage(callerAvatar),
            ),
            const SizedBox(height: 20),
            Text(
              'Calling $callerName...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: onHangUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(20),
              ),
              child: const Icon(
                Icons.call_end,
                color: Colors.white,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}