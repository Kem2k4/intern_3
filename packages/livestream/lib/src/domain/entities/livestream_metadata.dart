/// Model representing livestream metadata
class LivestreamMetadata {
  final String id;
  final String channelName;
  final String hostId;
  final String hostName;
  final DateTime startAt;
  final DateTime? endAt;
  final Duration? duration;
  final int peakView;
  final int commentCount;
  final bool isActive;

  const LivestreamMetadata({
    required this.id,
    required this.channelName,
    required this.hostId,
    required this.hostName,
    required this.startAt,
    this.endAt,
    this.duration,
    this.peakView = 0,
    this.commentCount = 0,
    this.isActive = true,
  });

  /// Create LivestreamMetadata from Firestore document
  factory LivestreamMetadata.fromJson(Map<String, dynamic> json, String id) {
    return LivestreamMetadata(
      id: id,
      channelName: json['channelName'] as String,
      hostId: json['hostId'] as String,
      hostName: json['hostName'] as String,
      startAt: DateTime.fromMillisecondsSinceEpoch(json['startAt'] as int),
      endAt: json['endAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['endAt'] as int)
          : null,
      duration: json['duration'] != null ? Duration(milliseconds: json['duration'] as int) : null,
      peakView: json['peakView'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Convert LivestreamMetadata to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'channelName': channelName,
      'hostId': hostId,
      'hostName': hostName,
      'startAt': startAt.millisecondsSinceEpoch,
      'endAt': endAt?.millisecondsSinceEpoch,
      'duration': duration?.inMilliseconds,
      'peakView': peakView,
      'commentCount': commentCount,
      'isActive': isActive,
    };
  }

  /// Create a copy of LivestreamMetadata with modified fields
  LivestreamMetadata copyWith({
    String? id,
    String? channelName,
    String? hostId,
    String? hostName,
    DateTime? startAt,
    DateTime? endAt,
    Duration? duration,
    int? peakView,
    int? commentCount,
    bool? isActive,
  }) {
    return LivestreamMetadata(
      id: id ?? this.id,
      channelName: channelName ?? this.channelName,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      duration: duration ?? this.duration,
      peakView: peakView ?? this.peakView,
      commentCount: commentCount ?? this.commentCount,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Calculate duration when livestream ends
  LivestreamMetadata endLivestream() {
    final now = DateTime.now();
    final calculatedDuration = now.difference(startAt);
    return copyWith(endAt: now, duration: calculatedDuration, isActive: false);
  }

  /// Update peak view count
  LivestreamMetadata updatePeakView(int newViewCount) {
    return copyWith(peakView: newViewCount > peakView ? newViewCount : peakView);
  }

  /// Increment comment count
  LivestreamMetadata incrementCommentCount() {
    return copyWith(commentCount: commentCount + 1);
  }
}
