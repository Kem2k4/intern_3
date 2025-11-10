import 'package:firebase_database/firebase_database.dart';
import '../models/video_call.dart';

abstract class VideoCallDataSource {
  Future<String> createCall(VideoCall call);
  Future<void> updateCall(String callId, Map<String, dynamic> updates);
  Future<VideoCall?> getCall(String callId);
  Future<void> deleteCall(String callId);
  Stream<VideoCall?> watchCall(String callId);
  Stream<List<VideoCall>> watchIncomingCalls(String userId);
}

class VideoCallFirebaseDataSource implements VideoCallDataSource {
  final FirebaseDatabase _database;

  VideoCallFirebaseDataSource(this._database);

  @override
  Future<String> createCall(VideoCall call) async {
    try {
      final callRef = _database.ref('video_calls').push();
      final callId = callRef.key!;

      final callData = call.copyWith(callId: callId).toJson();
      await callRef.set(callData);

      return callId;
    } catch (e) {
      throw Exception('Failed to create call: $e');
    }
  }

  @override
  Future<void> updateCall(String callId, Map<String, dynamic> updates) async {
    try {
      await _database.ref('video_calls/$callId').update(updates);
    } catch (e) {
      throw Exception('Failed to update call: $e');
    }
  }

  @override
  Future<VideoCall?> getCall(String callId) async {
    try {
      final snapshot = await _database.ref('video_calls/$callId').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return VideoCall.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get call: $e');
    }
  }

  @override
  Future<void> deleteCall(String callId) async {
    try {
      await _database.ref('video_calls/$callId').remove();
    } catch (e) {
      throw Exception('Failed to delete call: $e');
    }
  }

  @override
  Stream<VideoCall?> watchCall(String callId) {
    return _database
        .ref('video_calls/$callId')
        .onValue
        .map((event) {
          if (event.snapshot.exists) {
            final data = Map<String, dynamic>.from(event.snapshot.value as Map);
            return VideoCall.fromJson(data);
          }
          return null;
        });
  }

  @override
  Stream<List<VideoCall>> watchIncomingCalls(String userId) {
    return _database
        .ref('video_calls')
        .orderByChild('receiverId')
        .equalTo(userId)
        .onValue
        .map((event) {
          final calls = <VideoCall>[];
          if (event.snapshot.exists) {
            final data = event.snapshot.value as Map?;
            if (data != null) {
              for (final entry in data.entries) {
                final callData = Map<String, dynamic>.from(entry.value as Map);
                final call = VideoCall.fromJson(callData);
                // Only include calls that are still active (not ended or rejected)
                if (call.status == 'calling') {
                  calls.add(call);
                }
              }
            }
          }
          return calls;
        });
  }
}