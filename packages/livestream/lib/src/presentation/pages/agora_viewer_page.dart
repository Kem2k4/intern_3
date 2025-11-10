import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:core_ui/core_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auth/auth.dart';
import '../bloc/agora_viewer_bloc.dart';
import '../../data/repositories/livestream_comment_repository.dart';
import '../../data/repositories/livestream_metadata_repository.dart';

/// Agora Viewer Page - For watching livestreams as an audience member
class AgoraViewerPage extends StatefulWidget {
  final String channelName;

  const AgoraViewerPage({super.key, required this.channelName});

  @override
  State<AgoraViewerPage> createState() => _AgoraViewerPageState();
}

class _AgoraViewerPageState extends State<AgoraViewerPage> {
  late final AgoraViewerBloc _agoraBloc;
  late final LivestreamCommentRepository _commentRepository;
  late final LivestreamMetadataRepository _metadataRepository;
  String? _livestreamId;
  bool _hasPostedJoinMessage = false; // Track if join message was posted

  @override
  void initState() {
    super.initState();
    // Get bloc from context
    _agoraBloc = context.read<AgoraViewerBloc>();

    // Initialize repositories
    _commentRepository = LivestreamCommentRepository();
    _metadataRepository = LivestreamMetadataRepository();

    // Get livestream ID from channel name
    _getLivestreamId();

    // Initialize Agora first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _agoraBloc.add(JoinAsViewer(widget.channelName));
    });
  }

  /// Get livestream ID from channel name
  Future<void> _getLivestreamId() async {
    try {
      final metadata = await _metadataRepository.getLivestreamMetadataByChannel(widget.channelName);
      if (metadata != null) {
        setState(() {
          _livestreamId = metadata.id;
        });
        // Try to post join message after getting livestream ID
        await _postJoinMessage();
      }
    } catch (e) {
      // If can't get livestream ID, comments won't work but viewer can still watch
      debugPrint('Failed to get livestream ID: $e');
    }
  }

  /// Post join message when viewer successfully joins
  Future<void> _postJoinMessage() async {
    if (_hasPostedJoinMessage || _livestreamId == null) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Try to get user data from Firestore first
        final authRepo = context.read<FirebaseAuthRepository>();
        final userOption = await authRepo.getCurrentUser();

        String userName;
        String userAvatar;

        if (userOption.isSome()) {
          // Use data from Firestore
          final userData = userOption.getOrElse(() => throw Exception('User data not found'));
          userName = userData.fullName.isNotEmpty ? userData.fullName : 'Viewer';
          userAvatar = userData.avatar;
        } else {
          // Fallback to Firebase Auth data
          userName = user.displayName?.isNotEmpty == true ? user.displayName! : 'Viewer';
          userAvatar = user.photoURL ?? '';
        }

        await _commentRepository.addJoinMessage(
          livestreamId: _livestreamId!,
          userId: user.uid,
          userName: userName,
          userAvatar: userAvatar,
        );

        _hasPostedJoinMessage = true;
      }
    } catch (e) {
      debugPrint('Failed to post join message: $e');
    }
  }

  @override
  void dispose() {
    // Properly cleanup when leaving page (don't await to avoid blocking UI)
    _cleanupOnDispose();
    super.dispose();
  }

  /// Cleanup resources when page is disposed
  void _cleanupOnDispose() {
    try {
      // Check if bloc is still active before adding events
      if (!_agoraBloc.isClosed) {
        final currentState = _agoraBloc.state;

        // If watching, properly leave channel (but don't affect host)
        if (currentState is AgoraWatching) {
          // Trigger cleanup through bloc
          _agoraBloc.add(const LeaveChannel());
        }
      }
    } catch (e) {
      // Bloc might already be closed or disposed, ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Watching: ${widget.channelName}'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        // actions: [
        //   IconButton(
        //     onPressed: () => Navigator.of(context).pop(),
        //     icon: const Icon(Icons.close),
        //   ),
        // ],
      ),
      body: BlocConsumer<AgoraViewerBloc, AgoraState>(
        listener: (context, state) {
          if (state is AgoraError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }

          // Note: Join message is already posted in _getLivestreamId()
          // This listener is kept as a fallback if livestream ID fetch fails
          if (state is AgoraWatching && !_hasPostedJoinMessage && _livestreamId != null) {
            _postJoinMessage();
          }
        },
        builder: (context, state) {
          final isWatching = state is AgoraWatching;
          return Stack(
            children: [
              _buildMainContent(state),
              // Comments section - only show when watching
              if (isWatching)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Comments display
                      SizedBox(
                        height: 250,
                        child: LivestreamCommentWidget(
                          isVisible: isWatching,
                          height: 250,
                          commentsStream: _livestreamId != null
                              ? _commentRepository.getCommentsStream(_livestreamId!)
                              : const Stream.empty(),
                        ),
                      ),
                      // Comment input
                      LivestreamCommentInputWidget(
                        isVisible: isWatching,
                        onCommentSubmitted: (message) async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            // Try to get user data from Firestore first
                            // ignore: use_build_context_synchronously
                            final authRepo = context.read<FirebaseAuthRepository>();
                            final userOption = await authRepo.getCurrentUser();

                            String userName;
                            String userAvatar;

                            if (userOption.isSome()) {
                              // Use data from Firestore
                              final userData = userOption.getOrElse(
                                () => throw Exception('User data not found'),
                              );
                              userName = userData.fullName.isNotEmpty
                                  ? userData.fullName
                                  : 'Viewer';
                              userAvatar = userData.avatar;
                            } else {
                              // Fallback to Firebase Auth data
                              userName = user.displayName?.isNotEmpty == true
                                  ? user.displayName!
                                  : 'Viewer';
                              userAvatar = user.photoURL ?? '';
                            }

                            if (_livestreamId != null) {
                              await _commentRepository.addComment(
                                livestreamId: _livestreamId!,
                                userId: user.uid,
                                userName: userName,
                                message: message,
                                userAvatar: userAvatar,
                              );
                            } else {
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cannot comment: livestream not found'),
                                ),
                              );
                            }
                          } else {
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please login to comment')),
                            );
                          }
                        },
                        placeholder: 'Comment as viewer...',
                      ),
                    ],
                  ),
                ),
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
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Joining livestream...'),
          ],
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
                  _agoraBloc.add(JoinAsViewer(widget.channelName));
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is AgoraWatching) {
      final engine = _agoraBloc.repository.service.engine;
      if (engine == null) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Connecting to stream...'),
            ],
          ),
        );
      }

      // For livestream viewer: Show broadcaster's video full screen
      return Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand, // Full screen
          children: [
            // Full screen broadcaster view
            if (state.broadcasterUid != null)
              AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: engine,
                  canvas: VideoCanvas(uid: state.broadcasterUid!),
                  connection: RtcConnection(channelId: state.channelName),
                ),
              )
            else
              const Center(
                child: Text(
                  'Waiting for broadcaster...',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
          ],
        ),
      );
    }

    // Default: Show loading
    return const Center(child: CircularProgressIndicator());
  }

  /// Build overlay controls
  Widget _buildOverlayControls(AgoraState state) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Viewer count
          if (state is AgoraWatching)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.visibility, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${state.remoteUids.length + (state.broadcasterUid != null ? 1 : 0) - 1} watching',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),

          // Exit button - Simple leave and close
          IconButton(
            onPressed: () {
              if (!_agoraBloc.isClosed) {
                _agoraBloc.add(const LeaveChannel());
              }
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.close, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: Colors.black.withValues(alpha: 0.6)),
            tooltip: 'Leave livestream',
          ),
        ],
      ),
    );
  }
}
