import 'package:cloud_firestore/cloud_firestore.dart';
// no flutter import needed here

class CallSignalingService {
  CallSignalingService._();
  static final CallSignalingService instance = CallSignalingService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _col => _firestore.collection('call_signals');

  /// Send a call invite from caller -> callee
  Future<String> sendInvite({
    required String callerId,
    required String calleeId,
    required String channel,
    String? rtcToken,
    String? callerName,
  }) async {
    final doc = await _col.add({
      'type': 'call_invite',
      'channel': channel,
      'callerId': callerId,
      'calleeId': calleeId,
      'rtcToken': rtcToken,
      'callerName': callerName ?? '',
      'timestamp': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> sendAccept({
    required String callerId,
    required String calleeId,
    required String channel,
    String? rtcToken,
  }) async {
    await _col.add({
      'type': 'call_accept',
      'channel': channel,
      'callerId': callerId,
      'calleeId': calleeId,
      'rtcToken': rtcToken,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendReject({
    required String callerId,
    required String calleeId,
    required String channel,
  }) async {
    await _col.add({
      'type': 'call_reject',
      'channel': channel,
      'callerId': callerId,
      'calleeId': calleeId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendEnd({
    required String fromId,
    required String toId,
    required String channel,
  }) async {
    await _col.add({
      'type': 'call_end',
      'channel': channel,
      'fromId': fromId,
      'toId': toId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Stream of signals where the current user is involved (either caller or callee)
  Stream<QuerySnapshot> listenSignalsForUser(String userId) {
    return _col
        .where('calleeId', isEqualTo: userId)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /// Stream of responses directed to a caller (used by caller to wait for accept/reject)
  Stream<QuerySnapshot> listenResponsesForCaller(String callerId) {
    return _col
        .where('callerId', isEqualTo: callerId)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
}
