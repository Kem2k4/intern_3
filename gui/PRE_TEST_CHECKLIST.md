# Pre-Testing Checklist ✅

## Status: Ready for End-to-End Testing

The incoming call detection system has been **FIXED** and is ready for testing!

---

## Quick Summary of Changes

| Component | Status | Change |
|-----------|--------|--------|
| Firebase Listener | ✅ FIXED | `onValue` → `onChildAdded` |
| Riverpod Providers | ✅ READY | Global listener set up |
| HomePage | ✅ UPDATED | Added incoming call overlay |
| Main App | ✅ CONFIGURED | ProviderScope wrapper added |

---

## 5-Minute Pre-Test Setup

### 1. Configure Agora (2 min)
```
File: packages/video_call/lib/data/services/video_call_service.dart
Line: 15
Find: static const String _agoraAppId = '1ba9507a85a6458ab556245408db710a';
Go to: https://console.agora.io/
Replace with your App ID
```

### 2. Clean & Build (3 min)
```powershell
cd c:\Vietravel\intern_3
flutter clean
flutter pub get
flutter run
```

---

## Pre-Test Verification

- [ ] No compilation errors: `flutter analyze` returns 0 errors
- [ ] App runs without crashing: `flutter run` succeeds
- [ ] Firebase Realtime Database enabled in Firebase Console
- [ ] Camera & Microphone permissions enabled on test devices

---

## Test Execution (10-15 minutes)

### Setup
- [ ] Device A: Android Emulator or Physical Phone
- [ ] Device B: Android Emulator or Physical Phone
- [ ] Both devices logged into Firebase with different users
- [ ] Both devices connected to same network (if physical)

### Test Flow

#### Phase 1: Basic Incoming Call Detection (3 min)
```
Device A:
1. Open app and login
2. Go to Chats
3. Start chat with any user
4. Tap video camera icon 📹

Device B:
5. Should see "Incoming video call" overlay within 1-3 seconds
   ✓ Shows text: "Incoming video call"
   ✓ Shows caller avatar
   ✓ Shows Accept & Decline buttons
```

**Expected Result:** ✅ Overlay appears on Device B

**If Failed:**
- [ ] Check Firebase Realtime Database is created
- [ ] Verify `/calls` path is readable
- [ ] Run `flutter clean && flutter pub get`
- [ ] Check device logs: `flutter logs`

---

#### Phase 2: Accept Call (3 min)
```
Device B:
1. Tap green "Accept" button

Device A:
2. "Calling..." screen closes
3. Screen navigates to video call view

Device B:
4. "Incoming video call" overlay closes
5. Screen navigates to video call view

Both devices:
6. Should show:
   ✓ Local camera feed in corner
   ✓ Remote camera feed fullscreen
   ✓ Mute button
   ✓ Camera toggle button
   ✓ Speaker button
   ✓ End call button
```

**Expected Result:** ✅ Video call screen shows on both

**If Failed:**
- [ ] Check Agora App ID configured
- [ ] Verify camera permissions granted
- [ ] Check network connectivity

---

#### Phase 3: Video Connection (2 min)
```
Device A:
1. Should see Device B's camera feed on fullscreen

Device B:
2. Should see Device A's camera feed on fullscreen

Both:
3. Can see each other's video in real-time
4. Tap camera icon - video should toggle off/on
5. Tap mic icon - audio mute should work
```

**Expected Result:** ✅ Video streams display correctly

**If Failed:**
- [ ] Wait 5 seconds (connection takes time)
- [ ] Check network bandwidth
- [ ] Verify Agora status: https://console.agora.io/

---

#### Phase 4: End Call (2 min)
```
Device A:
1. Tap red "End Call" button

Device B:
2. Call screen closes immediately
3. Returns to home/chat screen

Device A:
3. Call screen closes
4. Returns to home/chat screen
```

**Expected Result:** ✅ Both disconnect cleanly

**If Failed:**
- [ ] Check Firebase `status` field updated to 'ended'
- [ ] Verify no crashes in logs

---

#### Phase 5: Reject Call (2 min)
```
Device A:
1. Tap video call button

Device B:
2. See incoming call overlay
3. Tap "Decline" button

Device A:
4. "Calling..." should close (or show "Call rejected")

Device B:
5. Overlay closes
6. Returns to normal screen
```

**Expected Result:** ✅ Call rejection handled properly

---

## Detailed Verification Points

### Firebase Database
- [ ] Go to Firebase Console
- [ ] Realtime Database section
- [ ] Should see `/calls` node with structure:
```json
{
  "calls": {
    "uuid-string-here": {
      "callerId": "user-a-id",
      "calleeId": "user-b-id",
      "status": "ringing|accepted|ended",
      "createdAt": 1234567890000
    }
  }
}
```

### Console Logs (Terminal)
- [ ] `flutter logs` should show:
```
D: Agora engine initialized successfully
D: Call request sent: <channelId>
D: New incoming call detected: <channelId> for user: <userId>
D: Joined channel: <channelId>
D: Left channel: <channelId>
```

### App Console (When running)
- [ ] No red errors visible
- [ ] No yellow warnings for this feature
- [ ] No crashes reported

---

## Troubleshooting During Test

### Incoming call doesn't appear
```
Diagnosis:
1. Check Firebase Console - is call record created?
2. Check logs: flutter logs | grep -i "call"
3. Verify Device B user ID matches calleeId in Firebase

Solutions:
- Device B not logged in? Login again
- Firebase Rules blocking? Use Test Mode
- Agora App ID wrong? Update in code
- Provider not initialized? Restart app
```

### Video doesn't connect
```
Diagnosis:
1. Check Agora dashboard for errors
2. Verify both devices on same network
3. Check camera permissions granted

Solutions:
- Allow camera permission: Settings → Apps → intern_3 → Permissions
- Retry call after permissions changed
- Restart app if just granted permissions
- Check firewall/proxy blocking Agora ports 40000-40004
```

### App crashes when calling
```
Diagnosis:
1. Check flutter logs for error messages
2. Look for stack trace with file names

Solutions:
- If "RtcEngine not initialized": Bug in our code, report it
- If "Permission denied": Grant all permissions
- If "FirebaseException": Check Realtime Database enabled
```

---

## Success Indicators 🎉

You'll know it's working when:

1. ✅ Device A initiates call
2. ✅ Device B sees overlay in <3 seconds
3. ✅ Device B taps Accept
4. ✅ Both navigate to video screen
5. ✅ Both see each other's video
6. ✅ Both can end call cleanly

**If all 6 pass: SUCCESS! Feature is working! 🎊**

---

## Post-Test Actions

### If Tests Pass ✅
1. Document test results
2. Test on 2-3 more device combinations (iPhone, Samsung, etc.)
3. Move to production configuration (see IMPLEMENTATION_SUMMARY.md)
4. Deploy to TestFlight/Play Store

### If Tests Fail ❌
1. Collect error logs
2. Check "Troubleshooting During Test" section above
3. Verify all configuration steps completed
4. If still failing: Check packages/video_call/lib/data/services/video_call_service.dart line 115 has correct `onChildAdded` implementation

---

## Test Log Template

Copy this for documenting your test:

```
TEST DATE: ________________
TESTED BY: ________________

Device A: ________________ (Android/iOS, emulator/physical)
Device B: ________________ (Android/iOS, emulator/physical)
Network: ________________ (WiFi/4G)

Phase 1 - Incoming Call Detection:   [ ] PASS  [ ] FAIL
Phase 2 - Accept Call:               [ ] PASS  [ ] FAIL
Phase 3 - Video Connection:          [ ] PASS  [ ] FAIL
Phase 4 - End Call:                  [ ] PASS  [ ] FAIL
Phase 5 - Reject Call:               [ ] PASS  [ ] FAIL

Overall Result: [ ] SUCCESS [ ] PARTIAL [ ] FAILED

Issues Found:
_________________________________________
_________________________________________

Time Taken: ________________
Notes:
_________________________________________
_________________________________________
```

---

## Quick Links

| Document | Purpose |
|----------|---------|
| `QUICK_TEST_GUIDE.md` | Step-by-step testing instructions |
| `VIDEO_CALL_FIXED.md` | Detailed technical documentation |
| `IMPLEMENTATION_SUMMARY.md` | Architecture and implementation details |
| `packages/video_call/README.md` | Package-specific documentation |

---

## Support Resources

**Problem Solving:**
1. Check relevant troubleshooting section above
2. Review logs: `flutter logs`
3. Check Firebase Console
4. Check Agora Dashboard

**Configuration:**
1. Agora App ID: https://console.agora.io/
2. Firebase Setup: https://firebase.google.com/
3. Flutter Docs: https://flutter.dev/docs

**Common Fixes:**
- App not updating code: `flutter clean && flutter pub get && flutter run`
- Permissions not working: Restart app after granting permissions
- Firebase connection: Verify database created in Test Mode
- Agora not working: Verify App ID copied correctly (no spaces)

---

## Final Checklist Before Starting

- [ ] Agora App ID configured
- [ ] Firebase Realtime Database created
- [ ] `flutter clean && flutter pub get` completed
- [ ] App runs without errors: `flutter run`
- [ ] 2 devices/emulators available
- [ ] Both devices can authenticate to Firebase
- [ ] Network connectivity verified
- [ ] Camera & Microphone permissions available
- [ ] Read through QUICK_TEST_GUIDE.md once
- [ ] Collected test device information

---

## Ready to Test! 🚀

When all checkboxes above are complete, begin with Phase 1 in "Test Execution" section.

**Expected Time:** 15-20 minutes for full test cycle

**Success Rate:** Should be 100% if configuration complete ✅

---

**Status: READY FOR TESTING** ✅

Last Updated: 2024
Feature: Incoming Call Detection (Video Call Module)
Version: 1.0 - Fixed Implementation

