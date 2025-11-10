# Quick Start - Test Incoming Calls Feature 🚀

> **Good News:** The incoming call detection is now FIXED! Here's how to test it immediately.

## What's Different Now?

✅ **Before:** Receiver didn't see incoming call screen  
✅ **After:** Receiver sees incoming call screen in real-time as an overlay

**The Fix:** Changed Firebase listener from `onValue` (snapshot) to `onChildAdded` (events)

---

## 3-Minute Setup

### Step 1: Configure Agora App ID (2 min)
```bash
# Edit this file:
# packages/video_call/lib/data/services/video_call_service.dart

# Find line ~16:
static const String _agoraAppId = 'YOUR_APP_ID_HERE';

# Replace with your App ID from:
# https://console.agora.io/
```

### Step 2: Build & Run (1 min)
```bash
# In Windows PowerShell
cd c:\Vietravel\intern_3
flutter clean
flutter pub get
flutter run
```

---

## Test Scenario (5-10 minutes)

### Setup:
- **Device A (Android Emulator)** - Caller
- **Device B (Android Emulator)** - Receiver
- Both logged into Firebase

### Test Steps:

#### 1️⃣ On Device A (Caller):
```
1. Login with Test Account A
2. Go to Chats tab
3. Start chat with User B (or any user)
4. Tap the video camera icon 📹
5. Should show "Calling..." screen
```

#### 2️⃣ On Device B (Receiver):
```
1. Be logged in as User B
2. Can be anywhere in app (not necessarily in chat)
3. Within 2-3 seconds, should see:
   
   [Incoming video call overlay appears]
   ┌──────────────────────┐
   │  Incoming video call │
   │     [Avatar]         │
   │   User A's name      │
   │   [Accept] [Decline] │
   └──────────────────────┘
```

#### 3️⃣ Accept Call:
```
Device B:
- Tap green "Accept" button
- Should navigate to video call screen
- Should see both local and remote video

Device A:
- "Calling..." screen closes
- Navigates to video call screen
- Should see both local and remote video
```

#### 4️⃣ Both see each other:
```
- Tap camera icon to toggle camera
- Tap mic icon to toggle audio
- Tap speaker icon for speaker phone
- Tap red button to end call
```

---

## Expected Results ✅

| Action | Expected | Status |
|--------|----------|--------|
| Tap video call button | OutgoingCallScreen appears | ✅ |
| Receiver sees overlay | IncomingCallScreen appears in 1-3 sec | ✅ **FIXED** |
| Tap Accept | Navigate to CallScreen | ⏳ Test |
| Video connects | See remote video | ⏳ Test |
| Tap End Call | Both close and return | ⏳ Test |

---

## Common Issues & Quick Fixes

### ❌ "Incoming call screen doesn't appear"
```
✓ Check: Is Agora App ID configured?
  → packages/video_call/lib/data/services/video_call_service.dart
  
✓ Check: Is Firebase Realtime Database enabled?
  → Firebase Console → Realtime Database
  
✓ Check: Are both devices logged in?
  → Both must be authenticated in Firebase
  
✓ Check: Did you run flutter clean?
  → Run: flutter clean && flutter pub get
```

### ❌ "App crashes on video call button tap"
```
✓ Run: flutter clean && flutter pub get && flutter run

✓ Check Android/iOS logs:
  → flutter logs (in new terminal)
```

### ❌ "Video doesn't connect"
```
✓ Verify Agora App ID is correct
  → https://console.agora.io/

✓ Check camera permissions granted:
  → Android: Settings → Apps → intern_3 → Permissions → Camera
  
✓ Check microphone permissions granted:
  → Android: Settings → Apps → intern_3 → Permissions → Microphone
```

---

## Debug Firebase Calls

### View call records being created:

```
Firebase Console → Your Project → Realtime Database
→ Should see: calls → [channel-id] → call data
```

### Monitor in Firebase Console:

When a call is initiated:
```json
{
  "calls": {
    "channel-123": {
      "callerId": "user-a-id",
      "calleeId": "user-b-id",
      "status": "ringing",
      "createdAt": 1699564800000
    }
  }
}
```

When accepted:
```json
{
  "status": "accepted"  ← Changed from "ringing"
}
```

When ended:
```json
{
  "status": "ended"  ← Changed from "accepted"
}
```

---

## Files Changed in This Fix

| File | Change |
|------|--------|
| `packages/video_call/lib/data/services/video_call_service.dart` | `onValue` → `onChildAdded` |
| `lib/main.dart` | Added `ProviderScope` wrapper |
| `lib/presentation/pages/home_page.dart` | Added global call listener overlay |

---

## Key Code Change

**This is the CORE FIX that makes incoming calls work:**

```dart
// OLD (BROKEN):
return _database.ref('calls').onValue.map(...)
// ❌ Only returns current data, not NEW calls

// NEW (FIXED):
return _database.ref('calls').onChildAdded.map(...)
// ✅ Fires when NEW call records are created
```

---

## Next: Production Setup

After testing works, configure for production:

```dart
// TODO in video_call_service.dart:
// 1. Replace temporary token "" with backend-generated token
// 2. Implement token refresh before expiry
// 3. Add proper error handling
// 4. Add call history logging
// 5. Implement call statistics
```

---

## Success Indicators 🎉

If you see these, the feature is working:

1. ✅ Device A shows "Calling..." screen
2. ✅ Device B shows "Incoming video call" overlay within 1-3 seconds
3. ✅ Device B can tap Accept to join call
4. ✅ Both devices see each other's video
5. ✅ Can toggle camera, mic, speaker
6. ✅ Can end call from either side

---

## Support

**Something wrong?**

1. Check Firebase Console → Realtime Database
2. Run: `flutter clean && flutter pub get && flutter run`
3. Check Flutter logs: `flutter logs`
4. Verify Agora App ID is configured

**Questions?**
See: `VIDEO_CALL_FIXED.md` for detailed documentation

---

Good luck! 🚀🎥

