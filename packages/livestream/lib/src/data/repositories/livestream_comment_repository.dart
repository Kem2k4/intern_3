import 'package:firebase_database/firebase_database.dart';
import 'package:core_ui/core_ui.dart';

/// Repository for managing livestream comments using Firebase Realtime Database
class LivestreamCommentRepository {
  final FirebaseDatabase _database;

  LivestreamCommentRepository({FirebaseDatabase? database})
    : _database = database ?? FirebaseDatabase.instance;

  /// Get reference to comments for a specific livestream
  DatabaseReference _getCommentsRef(String livestreamId) {
    return _database.ref('livestream_comments/$livestreamId');
  }

  /// Add a new comment to the livestream
  Future<void> addComment({
    required String livestreamId,
    required String userId,
    required String userName,
    required String message,
    String userAvatar = '',
    bool isJoinMessage = false,
  }) async {
    try {
      final commentRef = _getCommentsRef(livestreamId).push();
      final comment = LivestreamComment(
        id: commentRef.key ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        message: message,
        timestamp: DateTime.now(),
        isJoinMessage: isJoinMessage,
      );

      await commentRef.set({
        'userId': comment.userId,
        'userName': comment.userName,
        'userAvatar': comment.userAvatar,
        'message': comment.message,
        'timestamp': comment.timestamp.millisecondsSinceEpoch,
        'isJoinMessage': comment.isJoinMessage,
      });
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  /// Add a join message when viewer joins the livestream
  Future<void> addJoinMessage({
    required String livestreamId,
    required String userId,
    required String userName,
    String userAvatar = '',
  }) async {
    final message = '$userName đã tham gia livestream';
    await addComment(
      livestreamId: livestreamId,
      userId: userId,
      userName: userName,
      message: message,
      userAvatar: userAvatar,
      isJoinMessage: true,
    );
  }

  /// Stream of comments for a specific livestream
  Stream<List<LivestreamComment>> getCommentsStream(String livestreamId) {
    return _getCommentsRef(livestreamId)
        .orderByChild('timestamp')
        .limitToLast(50) // Limit to last 50 comments
        .onValue
        .map((event) {
          final comments = <LivestreamComment>[];

          if (event.snapshot.value != null) {
            final data = event.snapshot.value as Map<dynamic, dynamic>;

            data.forEach((key, value) {
              if (value is Map) {
                try {
                  final comment = LivestreamComment(
                    id: key.toString(),
                    userId: value['userId']?.toString() ?? '',
                    userName: value['userName']?.toString() ?? 'Anonymous',
                    userAvatar: value['userAvatar']?.toString() ?? '',
                    message: value['message']?.toString() ?? '',
                    timestamp: DateTime.fromMillisecondsSinceEpoch(value['timestamp'] as int? ?? 0),
                    isJoinMessage: value['isJoinMessage'] as bool? ?? false,
                  );
                  comments.add(comment);
                } catch (e) {
                  // Skip invalid comment data
                }
              }
            });

            // Sort by timestamp
            comments.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          }

          return comments;
        });
  }

  /// Delete a specific comment
  Future<void> deleteComment({required String livestreamId, required String commentId}) async {
    try {
      await _getCommentsRef(livestreamId).child(commentId).remove();
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  /// Clear all comments for a livestream (useful when livestream ends)
  Future<void> clearAllComments(String livestreamId) async {
    try {
      await _getCommentsRef(livestreamId).remove();
    } catch (e) {
      throw Exception('Failed to clear comments: $e');
    }
  }

  /// Get comment count for a livestream
  Future<int> getCommentCount(String livestreamId) async {
    try {
      final snapshot = await _getCommentsRef(livestreamId).get();
      if (snapshot.exists && snapshot.value is Map) {
        return (snapshot.value as Map).length;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}
