import 'package:equatable/equatable.dart';

/// Model for livestream comments
class LivestreamComment extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String message;
  final DateTime timestamp;
  final bool isJoinMessage;

  const LivestreamComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.message,
    required this.timestamp,
    this.isJoinMessage = false,
  });

  @override
  List<Object?> get props => [id, userId, userName, userAvatar, message, timestamp, isJoinMessage];

  /// Create a copy with modified fields
  LivestreamComment copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? message,
    DateTime? timestamp,
    bool? isJoinMessage,
  }) {
    return LivestreamComment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isJoinMessage: isJoinMessage ?? this.isJoinMessage,
    );
  }

  /// Convert to JSON (for future Firebase integration)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isJoinMessage': isJoinMessage,
    };
  }

  /// Create from JSON (for future Firebase integration)
  factory LivestreamComment.fromJson(Map<String, dynamic> json) {
    return LivestreamComment(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isJoinMessage: json['isJoinMessage'] as bool? ?? false,
    );
  }
}
