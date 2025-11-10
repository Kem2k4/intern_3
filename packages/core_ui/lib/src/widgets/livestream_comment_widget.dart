import 'package:flutter/material.dart';
import 'livestream_comment_model.dart';

/// Widget to display livestream comments with realtime updates
class LivestreamCommentWidget extends StatefulWidget {
  /// Whether to show the comment widget
  final bool isVisible;

  /// Height of the comment section
  final double height;

  /// Stream of comments to display
  final Stream<List<LivestreamComment>>? commentsStream;

  const LivestreamCommentWidget({
    super.key,
    this.isVisible = true,
    this.height = 300,
    this.commentsStream,
  });

  @override
  State<LivestreamCommentWidget> createState() => _LivestreamCommentWidgetState();
}

class _LivestreamCommentWidgetState extends State<LivestreamCommentWidget> {
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    // If no stream provided, show empty state
    if (widget.commentsStream == null) {
      return Container(
        height: widget.height,
        color: Colors.transparent,
        child: const Center(
          child: Text('No comments yet...', style: TextStyle(color: Colors.white60, fontSize: 14)),
        ),
      );
    }

    return Container(
      height: widget.height,
      color: Colors.transparent,
      child: StreamBuilder<List<LivestreamComment>>(
        stream: widget.commentsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading comments',
                style: TextStyle(color: Colors.red.withValues(alpha: 0.8), fontSize: 14),
              ),
            );
          }

          final comments = snapshot.data ?? [];

          if (comments.isEmpty) {
            return const Center(
              child: Text(
                'No comments yet...',
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
            );
          }

          // Auto scroll when new comments arrive
          _scrollToBottom();

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: comments.length,
            itemBuilder: (context, index) {
              return _buildCommentItem(comments[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildCommentItem(LivestreamComment comment) {
    // For join messages, show special styling
    if (comment.isJoinMessage) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.cyan.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.cyan.withValues(alpha: 0.5), width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.login, color: Colors.cyan, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        comment.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Regular comment
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User avatar
          CircleAvatar(
            radius: 14,
            backgroundColor: _getRandomColor(comment.userId),
            child: Text(
              (comment.userName.isNotEmpty ? comment.userName[0] : '?').toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Comment content
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(comment.message, style: const TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Generate consistent color for each user
  Color _getRandomColor(String userId) {
    final hash = userId.hashCode;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.cyan,
    ];
    return colors[hash.abs() % colors.length];
  }
}
