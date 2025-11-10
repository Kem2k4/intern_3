import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/livestream_metadata.dart';

/// Repository for managing livestream metadata using Firestore
class LivestreamMetadataRepository {
  final FirebaseFirestore _firestore;

  LivestreamMetadataRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference for livestream metadata
  CollectionReference get _livestreamsCollection => _firestore.collection('livestreams');

  /// Create a new livestream metadata document
  Future<String> createLivestreamMetadata(LivestreamMetadata metadata) async {
    final docRef = await _livestreamsCollection.add(metadata.toJson());
    return docRef.id;
  }

  /// Get livestream metadata by ID
  Future<LivestreamMetadata?> getLivestreamMetadata(String livestreamId) async {
    try {
      final doc = await _livestreamsCollection.doc(livestreamId).get();
      if (doc.exists) {
        return LivestreamMetadata.fromJson(doc.data()! as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get livestream metadata by channel name
  Future<LivestreamMetadata?> getLivestreamMetadataByChannel(String channelName) async {
    try {
      final query = await _livestreamsCollection
          .where('channelName', isEqualTo: channelName)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        return LivestreamMetadata.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Update livestream metadata
  Future<void> updateLivestreamMetadata(String livestreamId, LivestreamMetadata metadata) async {
    await _livestreamsCollection.doc(livestreamId).update(metadata.toJson());
  }

  /// End livestream and update final statistics
  Future<void> endLivestream(
    String livestreamId, {
    int finalPeakView = 0,
    int finalCommentCount = 0,
  }) async {
    final metadata = await getLivestreamMetadata(livestreamId);
    if (metadata != null) {
      final updatedMetadata = metadata.endLivestream().copyWith(
        peakView: finalPeakView > metadata.peakView ? finalPeakView : metadata.peakView,
        commentCount: finalCommentCount,
      );
      await updateLivestreamMetadata(livestreamId, updatedMetadata);
    }
  }

  /// Update peak view count for active livestream
  Future<void> updatePeakView(String livestreamId, int viewCount) async {
    final metadata = await getLivestreamMetadata(livestreamId);
    if (metadata != null && metadata.isActive) {
      final updatedMetadata = metadata.updatePeakView(viewCount);
      await updateLivestreamMetadata(livestreamId, updatedMetadata);
    }
  }

  /// Increment comment count for active livestream
  Future<void> incrementCommentCount(String livestreamId) async {
    final metadata = await getLivestreamMetadata(livestreamId);
    if (metadata != null && metadata.isActive) {
      final updatedMetadata = metadata.incrementCommentCount();
      await updateLivestreamMetadata(livestreamId, updatedMetadata);
    }
  }

  /// Get all livestreams for a specific host
  Future<List<LivestreamMetadata>> getHostLivestreams(String hostId, {int limit = 50}) async {
    try {
      final query = await _livestreamsCollection
          .where('hostId', isEqualTo: hostId)
          .orderBy('startAt', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => LivestreamMetadata.fromJson(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get active livestreams
  Future<List<LivestreamMetadata>> getActiveLivestreams({int limit = 20}) async {
    try {
      final query = await _livestreamsCollection
          .where('isActive', isEqualTo: true)
          .orderBy('startAt', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => LivestreamMetadata.fromJson(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Stream of livestream metadata for real-time updates
  Stream<LivestreamMetadata?> getLivestreamMetadataStream(String livestreamId) {
    return _livestreamsCollection.doc(livestreamId).snapshots().map((doc) {
      if (doc.exists) {
        return LivestreamMetadata.fromJson(doc.data()! as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  /// Stream of active livestreams
  Stream<List<LivestreamMetadata>> getActiveLivestreamsStream({int limit = 20}) {
    return _livestreamsCollection
        .where('isActive', isEqualTo: true)
        .orderBy('startAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (query) => query.docs
              .map((doc) => LivestreamMetadata.fromJson(doc.data() as Map<String, dynamic>, doc.id))
              .toList(),
        );
  }

  /// Delete livestream metadata
  Future<void> deleteLivestreamMetadata(String livestreamId) async {
    await _livestreamsCollection.doc(livestreamId).delete();
  }

  /// Get livestream statistics for a host
  Future<Map<String, dynamic>> getHostStatistics(String hostId) async {
    try {
      final livestreams = await getHostLivestreams(hostId, limit: 1000);

      int totalLivestreams = livestreams.length;
      int totalDuration = livestreams
          .where((ls) => ls.duration != null)
          .fold(0, (acc, ls) => acc + ls.duration!.inMinutes);
      int totalViews = livestreams.fold(0, (acc, ls) => acc + ls.peakView);
      int totalComments = livestreams.fold(0, (acc, ls) => acc + ls.commentCount);

      return {
        'totalLivestreams': totalLivestreams,
        'totalDurationMinutes': totalDuration,
        'totalViews': totalViews,
        'totalComments': totalComments,
        'averageViewsPerStream': totalLivestreams > 0 ? (totalViews / totalLivestreams).round() : 0,
        'averageCommentsPerStream': totalLivestreams > 0
            ? (totalComments / totalLivestreams).round()
            : 0,
      };
    } catch (e) {
      return {
        'totalLivestreams': 0,
        'totalDurationMinutes': 0,
        'totalViews': 0,
        'totalComments': 0,
        'averageViewsPerStream': 0,
        'averageCommentsPerStream': 0,
      };
    }
  }
}
