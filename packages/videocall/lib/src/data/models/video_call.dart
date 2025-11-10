import 'package:equatable/equatable.dart';

class VideoCall extends Equatable {
  final String callId;
  final String callerId;
  final String callerName;
  final String callerAvatar;
  final String receiverId;
  final String receiverName;
  final String receiverAvatar;
  final DateTime? startAt;
  final DateTime? acceptAt;
  final DateTime? rejectAt;
  final DateTime? endAt;
  final String status; // 'calling', 'accepted', 'rejected', 'ended'
  final String? channelName;
  final String? token;

  const VideoCall({
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.callerAvatar,
    required this.receiverId,
    required this.receiverName,
    required this.receiverAvatar,
    this.startAt,
    this.acceptAt,
    this.rejectAt,
    this.endAt,
    required this.status,
    this.channelName,
    this.token,
  });

  factory VideoCall.fromJson(Map<String, dynamic> json) {
    return VideoCall(
      callId: json['callId'] as String,
      callerId: json['callerId'] as String,
      callerName: json['callerName'] as String,
      callerAvatar: json['callerAvatar'] as String? ?? '',
      receiverId: json['receiverId'] as String,
      receiverName: json['receiverName'] as String,
      receiverAvatar: json['receiverAvatar'] as String? ?? '',
      startAt: json['startAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['startAt'] as int)
          : null,
      acceptAt: json['acceptAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['acceptAt'] as int)
          : null,
      rejectAt: json['rejectAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['rejectAt'] as int)
          : null,
      endAt: json['endAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['endAt'] as int)
          : null,
      status: json['status'] as String,
      channelName: json['channelName'] as String?,
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'callId': callId,
      'callerId': callerId,
      'callerName': callerName,
      'callerAvatar': callerAvatar,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverAvatar': receiverAvatar,
      'startAt': startAt?.millisecondsSinceEpoch,
      'acceptAt': acceptAt?.millisecondsSinceEpoch,
      'rejectAt': rejectAt?.millisecondsSinceEpoch,
      'endAt': endAt?.millisecondsSinceEpoch,
      'status': status,
      'channelName': channelName,
      'token': token,
    };
  }

  VideoCall copyWith({
    String? callId,
    String? callerId,
    String? callerName,
    String? callerAvatar,
    String? receiverId,
    String? receiverName,
    String? receiverAvatar,
    DateTime? startAt,
    DateTime? acceptAt,
    DateTime? rejectAt,
    DateTime? endAt,
    String? status,
    String? channelName,
    String? token,
  }) {
    return VideoCall(
      callId: callId ?? this.callId,
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      callerAvatar: callerAvatar ?? this.callerAvatar,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      receiverAvatar: receiverAvatar ?? this.receiverAvatar,
      startAt: startAt ?? this.startAt,
      acceptAt: acceptAt ?? this.acceptAt,
      rejectAt: rejectAt ?? this.rejectAt,
      endAt: endAt ?? this.endAt,
      status: status ?? this.status,
      channelName: channelName ?? this.channelName,
      token: token ?? this.token,
    );
  }

  @override
  List<Object?> get props => [
        callId,
        callerId,
        callerName,
        callerAvatar,
        receiverId,
        receiverName,
        receiverAvatar,
        startAt,
        acceptAt,
        rejectAt,
        endAt,
        status,
        channelName,
        token,
      ];
}