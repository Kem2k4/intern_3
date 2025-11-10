import 'package:flutter/material.dart';

class CallingScreen extends StatelessWidget {
  final String callerName;
  final String callerAvatar;
  final bool isMuted;
  final bool isCameraOff;
  final bool isFrontCamera;
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
    required this.onToggleMute,
    required this.onToggleCamera,
    required this.onSwitchCamera,
    required this.onHangUp,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video placeholder
          Container(
            color: Colors.grey[800],
            child: const Center(
              child: Text(
                'Video Call Active',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ),
          // Overlay with caller info
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(callerAvatar),
                ),
                const SizedBox(width: 10),
                Text(
                  callerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Controls
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: onToggleMute,
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
                  onPressed: onHangUp,
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
                  onPressed: onToggleCamera,
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
                  onPressed: onSwitchCamera,
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
    );
  }
}