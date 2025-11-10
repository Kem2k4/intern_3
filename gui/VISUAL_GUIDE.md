# Visual Guide - Incoming Call Detection Fix 📊

## The Problem → Solution → Result

```
┌─────────────────────────────────────────────────────────────────┐
│                    BEFORE (BROKEN)                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Caller (Device A)              Firebase              Receiver   │
│        │                            │                   │        │
│        ├─ Tap Call ─────────────────┤                   │        │
│        │                         Create Record          │        │
│        │                        ✓ Record Created        │        │
│        │                             │                  │        │
│        │  OutgoingScreen             │ onValue listener │        │
│        │  "Calling..."           ┌───┴─────────────────┼────┐  │
│        │                         │ Only returns         │    │  │
│        │                         │ CURRENT data         │    │  │
│        │                         │ Doesn't fire for     │    │  │
│        │                         │ NEW records          │    │  │
│        │                         │ ❌ Receiver         │    │  │
│        │                         │    sees NOTHING      │    │  │
│        │                         └─────────────────────┼────┘  │
│        │                                                │        │
│        │ ❌ FAILURE                              ❌ FAILURE     │
│        └────────────────────────────────────────────────┘       │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                    RECEIVER DOESN'T SEE CALL ❌
```

```
┌─────────────────────────────────────────────────────────────────┐
│                    AFTER (FIXED)                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Caller (Device A)              Firebase              Receiver   │
│        │                            │                   │        │
│        ├─ Tap Call ─────────────────┤                   │        │
│        │                         Create Record          │        │
│        │                        ✓ Record Created        │        │
│        │                             │                  │        │
│        │  OutgoingScreen             │ onChildAdded  ───┼────┐  │
│        │  "Calling..."           ┌───┴─────────────────┼─┐  │  │
│        │                         │ Fires for EVERY      │ │  │  │
│        │                         │ NEW record added     │ │  │  │
│        │                         │ ✅ Event Stream  ───┼─┼──┼──┤ │
│        │                         │    emits CallModel   │ │  │ │ │
│        │                         └─────────────────────┼─┘  │ │ │
│        │                                                │ ref.listen()
│        │                                                │ triggers │
│        │                                                ├─────────┤
│        │                                                │         │
│        │                                                │ IncomingCall
│        │                                                │ Screen
│        │                                                │ Overlay
│        │                                                │ appears ✅
│        │                                                │         │
│        │                                         [Accept][Decline]│
│        │◄─── Receiver taps Accept ──────────────────────┤        │
│        │                                                │         │
│        ├─ Navigate to CallScreen ──────────────────────►│         │
│        │                                                │         │
│        ├─ Join Agora Channel ──────────────────────────►│         │
│        │ ↔ Video/Audio Streams ↔ (Agora RTC Engine)   │         │
│        │ Both see each other's video ✅                │         │
│        │                                                │         │
│        └────────────────────────────────────────────────┘        │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                    RECEIVER SEES CALL ✅
```

---

## Firebase Listener Comparison

### ❌ WRONG: onValue (Snapshot-Based)
```
Time ───────────────────────────────────→

Listener activated
    │
    ├─ Returns CURRENT state of /calls
    │  (only existing records at connection time)
    │
    │  New calls added AFTER won't be detected
    │  Stream doesn't emit new events
    │
    └─ Result: Receiver doesn't see incoming calls ❌
```

### ✅ CORRECT: onChildAdded (Event-Based)
```
Time ───────────────────────────────────→

Listener activated
    │
    ├─ Returns existing records
    │
    ├─ NEW call added
    │  └─ onChildAdded fires ✓
    │     └─ Stream emits new CallModel ✓
    │        └─ Riverpod triggers ref.listen() ✓
    │           └─ Overlay appears ✓
    │
    ├─ Another NEW call added
    │  └─ onChildAdded fires ✓
    │     └─ Stream emits new CallModel ✓
    │
    └─ Result: Receiver sees all incoming calls ✅
```

---

## Code Change Visualization

### Location: `packages/video_call/lib/data/services/video_call_service.dart`

```dart
// LINE ~115
┌─────────────────────────────────────────────────────────────────┐
│  OLD (Broken):                                                   │
│  ─────────────────────────────────────────────────────────────  │
│                                                                   │
│  Stream<CallModel?> listenIncomingCalls(String userId) {       │
│    return _database.ref('calls').onValue  ← WRONG              │
│                              ^^^^^^                             │
│      .map((event) { /* ... */ });                              │
│  }                                                               │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘

                              ⬇️⬇️⬇️ CHANGED TO ⬇️⬇️⬇️

┌─────────────────────────────────────────────────────────────────┐
│  NEW (Fixed):                                                    │
│  ─────────────────────────────────────────────────────────────  │
│                                                                   │
│  Stream<CallModel?> listenIncomingCalls(String userId) {       │
│    return _database                                            │
│        .ref('calls')                                           │
│        .orderByChild('calleeId')  ← Filter by receiver        │
│        .equalTo(userId)                                        │
│        .onChildAdded  ← CORRECT                               │
│        ^^^^^^^^^^^                                              │
│      .map((event) {                                            │
│        // Process only 'ringing' status                        │
│        // Return CallModel for UI                             │
│      });                                                        │
│  }                                                               │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## App-Level Integration

### Before: No Global Listener
```
main.dart
    ↓
MaterialApp
    ↓
HomePage
    ├─ MessagePage (with video call button)
    ├─ ChatListPage
    └─ etc.
    
❌ Problem: No one listening for incoming calls
```

### After: Global Listener Added
```
main.dart
    ↓
ProviderScope  ← ADDED: Enables Riverpod
    ↓
MaterialApp
    ↓
HomePage
    ├─ _IncomingCallListener (wrapper)  ← ADDED: Global listener
    │  ├─ ref.listen(incomingCallProvider(userId))
    │  ├─ Shows IncomingCallScreen as overlay
    │  └─ Auto-dismisses after 30s
    │
    └─ MainBottomNavBar
       ├─ MessagePage (with video call button)  ← Can initiate call
       ├─ ChatListPage
       └─ etc.

✅ Solution: Incoming calls detected anywhere in app
```

---

## Real-Time Event Flow

### Event Sequence Timeline

```
T0 (Start)
│
├─ Device A: User logs in
│
├─ Device B: User logs in
│  └─ _IncomingCallListener starts
│  └─ ref.listen(incomingCallProvider('B_uid')) ← Listening
│
T1 (+5 sec)
│
├─ Device A: User taps video call button
│  └─ requestCall(callerId='A_uid', calleeId='B_uid')
│  └─ Creates: /calls/{channelId}
│     { callerId: 'A_uid', calleeId: 'B_uid', status: 'ringing' }
│
T2 (+100ms)
│
├─ Firebase triggers onChildAdded event
│  └─ All subscribers to /calls notified
│
T3 (+200ms)
│
├─ Device B: incomingCallProvider stream emits CallModel
│  └─ Filter check: calleeId == 'B_uid' ✓
│  └─ Status check: 'ringing' == 'ringing' ✓
│
T4 (+300ms)
│
├─ Device B: ref.listen() callback triggered
│  └─ _showIncomingCallOverlay(callModel)
│  └─ Creates OverlayEntry
│  └─ Inserts into Overlay.of(context)
│
T5 (+400ms)
│
├─ Device B: IncomingCallScreen appears on screen ✅
│  ├─ User sees: "Incoming video call"
│  ├─ User sees: Caller avatar
│  └─ User sees: Accept/Decline buttons
│
T6 (+2 sec)
│
├─ Device B: User taps "Accept"
│  └─ acceptCall(channelId)
│  └─ Update Firebase: status = 'accepted'
│
T7 (+100ms)
│
├─ Device A: Detects status change
│  └─ Navigates to CallScreen
│  └─ joinChannel(channelId)
│
├─ Device B: Navigates to CallScreen
│  └─ joinChannel(channelId)
│
T8 (+1 sec)
│
├─ Agora RTC Engine: Both connected
│  └─ Video stream starts flowing
│  └─ Both see remote video ✅
│
Success! Video call connected! 🎉
```

---

## Component Interaction Diagram

```
┌──────────────────────────────────┐
│      Firebase Realtime DB        │
│     (Cloud Storage)              │
│  /calls/{channelId}/             │
│  ├─ callerId                     │
│  ├─ calleeId                     │
│  ├─ status                       │
│  └─ createdAt                    │
└─────────────┬──────────────────┬─┘
              │                  │
           writes               reads/listens
              │                  │
         requestCall()     onChildAdded
         acceptCall()      Stream events
         rejectCall()      
         leaveChannel()    
              │                  │
         ┌────▼──────────────────▼────┐
         │   VideoCallService         │
         │   (Singleton)              │
         │                            │
         │ ├─ initAgora()            │
         │ ├─ requestCall()          │
         │ ├─ listenIncomingCalls()  │ ← THE FIX
         │ ├─ acceptCall()           │
         │ ├─ listenToCall()         │
         │ ├─ joinChannel()          │
         │ └─ leaveChannel()         │
         └────┬──────────────────┬───┘
              │                  │
         provides           provides Stream
              │                  │
         ┌────▼──────────────────▼────┐
         │  Riverpod Providers        │
         │                            │
         │ ├─ videoCallServiceProvider
         │ ├─ incomingCallProvider    │ ← Streams CallModel
         │ └─ callStatusProvider      │
         └────┬──────────────────┬───┘
              │                  │
           provides           provides data
              │                  │
         ┌────▼──────────────────▼────┐
         │  HomePage                  │
         │  _IncomingCallListener      │ ← Global listener
         │                            │
         │  ref.listen(              │
         │    incomingCallProvider   │
         │  )                         │
         │                            │
         │  ├─ Detects new calls    │
         │  ├─ Shows overlay        │
         │  └─ Auto-dismisses       │
         └────┬──────────────────┬───┘
              │                  │
          display           display
              │                  │
         ┌────▼──────────────┐  ┌──▼──────────────┐
         │ OutgoingCallScreen│  │IncomingCallScreen│
         │                   │  │                  │
         │ Caller:           │  │ Receiver:       │
         │ "Calling..."      │  │ "Incoming call" │
         │ [Cancel]          │  │ [Accept][Deny]  │
         └───────────────────┘  └──────────────────┘
                 │                       │
            User accepts            User accepts
                 │                       │
         ┌───────▼───────────────────────▼──────┐
         │     Both navigate to CallScreen       │
         │     joinChannel(channelId)           │
         │     Connect to Agora RTC Engine      │
         │     Share video/audio streams        │
         │     Display remote video feed        │
         └──────────────────────────────────────┘
```

---

## Data Model

### CallModel Structure
```dart
class CallModel {
  String channelId;           // Unique call ID (UUID)
  String callerId;            // Caller's user ID
  String calleeId;            // Receiver's user ID
  CallStatus status;          // ringing|accepted|rejected|ended|missed
  int createdAt;              // Timestamp in milliseconds
}

enum CallStatus {
  ringing,                    // ← Initial state when call created
  accepted,                   // ← Updated when receiver accepts
  rejected,                   // ← Updated when receiver declines
  ended,                      // ← Updated when someone ends call
  missed,                     // ← Updated when timeout
}
```

### Firebase Database Structure
```json
{
  "calls": {
    "550e8400-e29b-41d4-a716-446655440000": {
      "callerId": "uid-of-caller-user",
      "calleeId": "uid-of-receiver-user",
      "status": "ringing",
      "createdAt": 1699564800000
    },
    "another-channel-uuid": {
      "callerId": "uid-user-a",
      "calleeId": "uid-user-b",
      "status": "accepted",
      "createdAt": 1699564850000
    }
  }
}
```

---

## Testing Flow Diagram

```
┌────────────────────────────────────────────────┐
│            Test Execution Phases               │
├────────────────────────────────────────────────┤
│                                                │
│  Phase 1: Incoming Call Detection              │
│  ├─ Device A: requestCall()                   │
│  ├─ Device B: Check Firebase record created  │
│  ├─ Device B: Check overlay appears           │
│  └─ Expected: Overlay in <3 seconds ✅        │
│                                                │
│  Phase 2: Accept Call                         │
│  ├─ Device B: Tap "Accept"                   │
│  ├─ Device A: Verify status changes          │
│  ├─ Both: Check navigation to CallScreen     │
│  └─ Expected: Both on CallScreen ✅           │
│                                                │
│  Phase 3: Video Connection                    │
│  ├─ Device A: Check remote video            │
│  ├─ Device B: Check remote video            │
│  ├─ Both: Check camera toggle                │
│  └─ Expected: Bidirectional video ✅          │
│                                                │
│  Phase 4: End Call                            │
│  ├─ Either device: Tap "End Call"            │
│  ├─ Both: Check navigation back              │
│  ├─ Check: Firebase status = 'ended'         │
│  └─ Expected: Clean disconnect ✅             │
│                                                │
│  Phase 5: Reject Call                         │
│  ├─ Device A: requestCall()                   │
│  ├─ Device B: Tap "Decline"                  │
│  ├─ Both: Return to normal screens           │
│  └─ Expected: Clean rejection ✅              │
│                                                │
│  ✅ ALL PHASES PASS: FEATURE WORKING!        │
│                                                │
└────────────────────────────────────────────────┘
```

---

## Success Indicators

```
✅ Phase 1: Incoming call overlay appears within 1-3 seconds
   └─ If fails: Check Firebase listener, Riverpod setup

✅ Phase 2: Accept button navigates to video call
   └─ If fails: Check Firebase status update, navigation logic

✅ Phase 3: Video streams show on both devices
   └─ If fails: Check Agora App ID, camera permissions

✅ Phase 4: End call closes cleanly
   └─ If fails: Check leaveChannel(), Firebase cleanup

✅ Phase 5: Reject button works correctly
   └─ If fails: Check rejectCall() implementation

✅ OVERALL: 5/5 phases pass = Feature is working perfectly! 🎉
```

---

## Quick Reference Card

| Component | Change | Impact |
|-----------|--------|--------|
| `listenIncomingCalls()` | `onValue` → `onChildAdded` | **CRITICAL** - Enables detection |
| `HomePage` | Added listener | Enables global listening |
| `main.dart` | Added `ProviderScope` | Enables Riverpod |
| No other files | No changes needed | Everything uses existing patterns |

---

This visual guide helps understand:
- ❌ What was wrong before
- ✅ What's fixed now  
- 📊 How components interact
- 🔄 Real-time event flow
- ✨ Why it now works

**Next Step:** See `QUICK_TEST_GUIDE.md` to start testing! →

