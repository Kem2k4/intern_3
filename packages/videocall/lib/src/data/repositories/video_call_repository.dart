import 'dart:async';
import '../datasources/video_call_firebase_data_source.dart';
import '../models/video_call.dart';

abstract class VideoCallRepository {
  Future<String> createCall({
    required String callerId,
    required String callerName,
    required String callerAvatar,
    required String receiverId,
    required String receiverName,
    required String receiverAvatar,
    String? channelName,
    String? token,
  });

  Future<void> acceptCall(String callId);
  Future<void> rejectCall(String callId);
  Future<void> endCall(String callId);
  Future<VideoCall?> getCall(String callId);
  Future<void> deleteCall(String callId);
  Stream<VideoCall?> watchCall(String callId);
  Stream<List<VideoCall>> watchIncomingCalls(String userId);
}

class VideoCallRepositoryImpl implements VideoCallRepository {
  final VideoCallFirebaseDataSource dataSource;

  VideoCallRepositoryImpl(this.dataSource);

  @override
  Future<String> createCall({
    required String callerId,
    required String callerName,
    required String callerAvatar,
    required String receiverId,
    required String receiverName,
    required String receiverAvatar,
    String? channelName,
    String? token,
  }) async {
    final call = VideoCall(
      callId: '', // Will be set by Firebase
      callerId: callerId,
      callerName: callerName,
      callerAvatar: callerAvatar,
      receiverId: receiverId,
      receiverName: receiverName,
      receiverAvatar: receiverAvatar,
      startAt: DateTime.now(),
      status: 'calling',
      channelName: channelName,
      token: token,
    );

    return await dataSource.createCall(call);
  }

  @override
  Future<void> acceptCall(String callId) async {
    final updates = {
      'acceptAt': DateTime.now().millisecondsSinceEpoch,
      'status': 'accepted',
    };
    await dataSource.updateCall(callId, updates);
  }

  @override
  Future<void> rejectCall(String callId) async {
    final updates = {
      'rejectAt': DateTime.now().millisecondsSinceEpoch,
      'status': 'rejected',
    };
    await dataSource.updateCall(callId, updates);
  }

  @override
  Future<void> endCall(String callId) async {
    final updates = {
      'endAt': DateTime.now().millisecondsSinceEpoch,
      'status': 'ended',
    };
    await dataSource.updateCall(callId, updates);
  }

  @override
  Future<VideoCall?> getCall(String callId) async {
    return await dataSource.getCall(callId);
  }

  @override
  Future<void> deleteCall(String callId) async {
    await dataSource.deleteCall(callId);
  }

  @override
  Stream<VideoCall?> watchCall(String callId) {
    return dataSource.watchCall(callId);
  }

  @override
  Stream<List<VideoCall>> watchIncomingCalls(String userId) {
    return dataSource.watchIncomingCalls(userId);
  }
}