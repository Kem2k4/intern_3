import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class MediaViewPage extends StatefulWidget {
  final List<XFile> files;
  final int initialIndex;

  const MediaViewPage({
    super.key,
    required this.files,
    required this.initialIndex,
  });

  @override
  State<MediaViewPage> createState() => _MediaViewPageState();
}

class _MediaViewPageState extends State<MediaViewPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: Text(
          '${_currentIndex + 1}/${widget.files.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.files.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final file = widget.files[index];
          final isVideo = file.path.toLowerCase().endsWith('.mp4') || 
                          file.path.toLowerCase().endsWith('.mov');

          if (isVideo) {
            return _VideoPlayerItem(file: file);
          } else {
            return InteractiveViewer(
              child: Image.file(
                File(file.path),
                fit: BoxFit.contain,
              ),
            );
          }
        },
      ),
    );
  }
}

class _VideoPlayerItem extends StatefulWidget {
  final XFile file;

  const _VideoPlayerItem({required this.file});

  @override
  State<_VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<_VideoPlayerItem> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.file(File(widget.file.path));
    await _videoPlayerController.initialize();
    
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: false,
      looping: false,
      aspectRatio: _videoPlayerController.value.aspectRatio,
    );
    
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController != null && _videoPlayerController.value.isInitialized) {
      return Chewie(controller: _chewieController!);
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }
}
