import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:core_ui/core_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auth/auth.dart';
import '../bloc/agora_host_bloc.dart';
import '../../data/repositories/livestream_comment_repository.dart';
import '../../data/repositories/livestream_metadata_repository.dart';
import '../../domain/entities/livestream_metadata.dart';

/// Agora Host Page - For starting and managing livestreams as a broadcaster
class AgoraHostPage extends StatefulWidget {
  const AgoraHostPage({super.key});

  @override
  State<AgoraHostPage> createState() => _AgoraHostPageState();
}

class _AgoraHostPageState extends State<AgoraHostPage> {
  late final AgoraHostBloc _agoraBloc;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late final LivestreamCommentRepository _commentRepository;
  late final LivestreamMetadataRepository _metadataRepository;
  final String _channelName = 'livestream'; // Use consistent channel name
  String? _currentLivestreamId;
  final int _currentViewCount = 0;
  int _currentCommentCount = 0;

  @override
  void initState() {
    super.initState();
    // Get bloc from context
    _agoraBloc = context.read<AgoraHostBloc>();

    // Initialize repositories
    _commentRepository = LivestreamCommentRepository();
    _metadataRepository = LivestreamMetadataRepository();

    // Auto-initialize and start preview immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _agoraBloc.add(const InitializeAgora());
      // Start preview after initialization
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _agoraBloc.add(StartPreview(_channelName));
        }
      });
    });
  }

  @override
  void didUpdateWidget(covariant AgoraHostPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ensure page controller maintains position when widget rebuilds
    if (_pageController.hasClients) {
      _pageController.jumpToPage(_currentPage);
    }
  }

  /// Ensure the livestream ID is available for the host. First try to fetch an
  /// existing active livestream for the channel; if none exists, create one.
  Future<void> _ensureLivestreamId() async {
    if (_currentLivestreamId != null) return;

    try {
      // Try to find existing active livestream for the channel
      final existing =
          await _metadataRepository.getLivestreamMetadataByChannel(_channelName);
      if (existing != null) {
        setState(() {
          _currentLivestreamId = existing.id;
        });
        debugPrint(
            'Found existing livestream id for channel $_channelName: ${existing.id}');
        return;
      }

      // If none found, create a new metadata entry
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Read context before async operation
      // ignore: use_build_context_synchronously
      final authRepo = context.read<FirebaseAuthRepository>();

      final userOption = await authRepo.getCurrentUser();

      String hostName;
      if (userOption.isSome()) {
        final userData =
            userOption.getOrElse(() => throw Exception('User data not found'));
        hostName = userData.userName.isNotEmpty ? userData.userName : 'Host';
      } else {
        hostName = user.displayName?.isNotEmpty == true ? user.displayName! : 'Host';
      }

      final metadata = LivestreamMetadata(
        id: '',
        channelName: _channelName,
        hostId: user.uid,
        hostName: hostName,
        startAt: DateTime.now(),
        isActive: true,
      );

      final createdId =
          await _metadataRepository.createLivestreamMetadata(metadata);
      setState(() {
        _currentLivestreamId = createdId;
      });
      debugPrint(
          'Created livestream metadata id for channel $_channelName: $createdId');
    } catch (e) {
      debugPrint('Failed to ensure livestream id: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Go Live'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        // actions: [
        //   IconButton(
        //     onPressed: () => Navigator.of(context).pop(),
        //     icon: const Icon(Icons.close),
        //   ),
        // ],
      ),
      body: BlocConsumer<AgoraHostBloc, AgoraState>(
        listener: (context, state) {
          if (state is AgoraError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          } else if (state is AgoraBroadcasting && _currentLivestreamId == null) {
            // Ensure we have a livestream ID when broadcasting - try fetch by channel first, then create
            _ensureLivestreamId();
          }
        },
        builder: (context, state) {
          final isBroadcasting = state is AgoraBroadcasting;
          return Stack(
            children: [
              _buildMainContent(state),
              // When broadcasting, show swipeable pages instead of overlay controls
              if (isBroadcasting)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragEnd: (details) {
                      // Handle swipe gestures manually
                      if (details.primaryVelocity != null) {
                        if (details.primaryVelocity! < 0 && _currentPage == 0) {
                          // Swipe left - go to controls page
                          setState(() {
                            _currentPage = 1;
                          });
                        } else if (details.primaryVelocity! > 0 && _currentPage == 1) {
                          // Swipe right - go to comments page
                          setState(() {
                            _currentPage = 0;
                          });
                        }
                      }
                    },
                    child: Stack(
                      children: [
                        // Show current page content
                        IndexedStack(
                          index: _currentPage,
                          children: [
                            // Page 1: Comments
                            Container(
                              color: Colors.transparent,
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Comments display
                                    SizedBox(
                                      height: 250,
                                      child: LivestreamCommentWidget(
                                        isVisible: isBroadcasting,
                                        height: 250,
                                        commentsStream: _currentLivestreamId != null
                                            ? _commentRepository.getCommentsStream(
                                                _currentLivestreamId!,
                                              )
                                            : const Stream.empty(),
                                      ),
                                    ),
                                    // Comment input for host
                                    LivestreamCommentInputWidget(
                                      isVisible: isBroadcasting,
                                      onCommentSubmitted: (message) async {
                                        final user = FirebaseAuth.instance.currentUser;
                                        if (user != null) {
                                          // Try to get user data from Firestore first
                                          final authRepo = context.read<FirebaseAuthRepository>();
                                          final userOption = await authRepo.getCurrentUser();

                                          String userName;
                                          String userAvatar;

                                          if (userOption.isSome()) {
                                            // Use data from Firestore
                                            final userData = userOption.getOrElse(
                                              () => throw Exception('User data not found'),
                                            );
                                            userName = userData.userName.isNotEmpty
                                                ? userData.userName
                                                : 'Host';
                                            userAvatar = userData.avatar;
                                          } else {
                                            // Fallback to Firebase Auth data
                                            userName = user.displayName?.isNotEmpty == true
                                                ? user.displayName!
                                                : 'Host';
                                            userAvatar = user.photoURL ?? '';
                                          }

                                          await _commentRepository.addComment(
                                            livestreamId: _currentLivestreamId!,
                                            userId: user.uid,
                                            userName: userName,
                                            message: message,
                                            userAvatar: userAvatar,
                                          );

                                          // Update comment count in metadata
                                          if (_currentLivestreamId != null) {
                                            _currentCommentCount++;
                                            await _metadataRepository.incrementCommentCount(
                                              _currentLivestreamId!,
                                            );
                                          }
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Please login to comment'),
                                            ),
                                          );
                                        }
                                      },
                                      placeholder: 'Comment as host...',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Page 2: Controls
                            Container(
                              color: Colors.transparent,
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: _buildOverlayControls(state),
                              ),
                            ),
                          ],
                        ),
                        // Page indicators
                        Positioned(
                          top: 30,
                          left: 0,
                          right: 0,
                          child: Column(
                            children: [
                              Text(
                                _currentPage == 0 ? 'Comments' : 'Controls',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  2,
                                  (index) => Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _currentPage == index
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.3),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                // Show overlay controls when not broadcasting
                _buildOverlayControls(state),
            ],
          );
        },
      ),
    );
  }

  /// Build main content based on current state
  Widget _buildMainContent(AgoraState state) {
    if (state is AgoraLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Initializing...')],
        ),
      );
    }

    if (state is AgoraError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(state.message),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (!_agoraBloc.isClosed) {
                  _agoraBloc.add(const InitializeAgora());
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Default: Show camera preview or broadcast view
    if (state is AgoraPreview || state is AgoraBroadcasting) {
      final engine = _agoraBloc.repository.service.engine;
      if (engine == null) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Preparing camera...'),
            ],
          ),
        );
      }

      return Container(
        color: Colors.black,
        child: AgoraVideoView(
          controller: VideoViewController(rtcEngine: engine, canvas: const VideoCanvas(uid: 0)),
        ),
      );
    }

    // Default fallback
    return Container(color: Colors.black);
  }

  /// Build overlay controls
  Widget _buildOverlayControls(AgoraState state) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Transform.scale(
        scale: 0.8,
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Camera toggle
              IconButton(
                onPressed:
                    (state is AgoraPreview || state is AgoraBroadcasting) && !_agoraBloc.isClosed
                    ? () {
                        if (!_agoraBloc.isClosed) {
                          _agoraBloc.add(const ToggleCamera());
                        }
                      }
                    : null,
                icon: const Icon(Icons.cameraswitch, color: Colors.white),
                tooltip: 'Switch Camera',
              ),

              // Mic toggle
              IconButton(
                onPressed:
                    (state is AgoraPreview || state is AgoraBroadcasting) && !_agoraBloc.isClosed
                    ? () {
                        if (!_agoraBloc.isClosed) {
                          _agoraBloc.add(const ToggleMic());
                        }
                      }
                    : null,
                icon: BlocBuilder<AgoraHostBloc, AgoraState>(
                  builder: (context, state) {
                    final isMuted =
                        state is AgoraPreview && state.isMicMuted ||
                        state is AgoraBroadcasting && state.isMicMuted;
                    return Icon(isMuted ? Icons.mic_off : Icons.mic, color: Colors.white);
                  },
                ),
                tooltip: 'Toggle Microphone',
              ),

              // Main action button
              _buildMainActionButton(state),

              // Settings
              IconButton(
                onPressed: () => _showSettingsDialog(context),
                icon: const Icon(Icons.settings, color: Colors.white),
                tooltip: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build main action button based on state
  Widget _buildMainActionButton(AgoraState state) {
    if (state is AgoraLoading) {
      return const SizedBox(
        width: 64,
        height: 64,
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (state is AgoraPreview) {
      return ElevatedButton(
        onPressed: !_agoraBloc.isClosed
            ? () {
                if (!_agoraBloc.isClosed) {
                  _agoraBloc.add(const StartBroadcasting());
                }
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(16),
        ),
        child: const Icon(Icons.play_arrow, size: 32),
      );
    }

    if (state is AgoraBroadcasting) {
      return ElevatedButton(
        onPressed: !_agoraBloc.isClosed
            ? () async {
                // End livestream metadata first
                if (_currentLivestreamId != null) {
                  await _metadataRepository.endLivestream(
                    _currentLivestreamId!,
                    finalPeakView: _currentViewCount,
                    finalCommentCount: _currentCommentCount,
                  );
                }

                // End livestream and close page - check bloc state before adding event
                if (!_agoraBloc.isClosed) {
                  _agoraBloc.add(const LeaveChannel());
                }

                // Use Future.delayed to ensure bloc operation completes before navigation
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                });
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(16),
        ),
        child: const Icon(Icons.stop, size: 32),
      );
    }

    // Default fallback
    return const SizedBox.shrink();
  }

  /// Show settings dialog
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stream Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Video Quality'),
              subtitle: const Text('HD (720p)'),
              onTap: () {
                // TODO: Implement video quality settings
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic),
              title: const Text('Audio Quality'),
              subtitle: const Text('High'),
              onTap: () {
                // TODO: Implement audio quality settings
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }
}
