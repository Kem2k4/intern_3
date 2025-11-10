# Firebase Functions - Video Call System

## 📦 Installation

```bash
cd firebase_functions
npm install
```

## 🚀 Development

### Local Emulator
```bash
npm run serve
```

### Watch Mode
```bash
npm run build:watch
```

## 🌐 Deployment

### Deploy all functions
```bash
npm run deploy
```

### Deploy specific function
```bash
firebase deploy --only functions:sendCallNotification
firebase deploy --only functions:cleanupOldCalls
```

## 📊 View Logs

```bash
npm run logs
```

Or in Firebase Console: Functions → Logs

## 🧪 Testing

### Test sendCallNotification

1. Create a call in Realtime Database manually:
```json
{
  "calls": {
    "test_call_123": {
      "callId": "test_call_123",
      "callerId": "user1",
      "callerName": "Test User",
      "receiverId": "user2",
      "status": "calling",
      "createAt": 1234567890
    }
  }
}
```

2. Check logs to see if FCM was sent

### Test with HTTP Callable

From Flutter:
```dart
final callable = FirebaseFunctions.instance.httpsCallable('testFCMNotification');
final result = await callable.call({
  'receiverId': 'userId',
  'title': 'Test',
  'body': 'This is a test',
});
```

## ⚙️ Configuration

Make sure your Firebase project has:
- ✅ Realtime Database enabled
- ✅ Firestore enabled
- ✅ Cloud Functions enabled (Blaze plan required)
- ✅ Cloud Messaging enabled

## 📝 Functions List

| Function | Trigger | Description |
|----------|---------|-------------|
| sendCallNotification | onCreate /calls/{callId} | Gửi FCM khi có cuộc gọi mới |
| cleanupOldCalls | Scheduled (daily 2AM) | Xóa cuộc gọi cũ hơn 24h |
| handleCallTimeout | onCreate /calls/{callId} | Đánh dấu timeout sau 30s |
| testFCMNotification | HTTP Callable | Test gửi FCM thủ công |

## 🐛 Troubleshooting

### "Permission denied" error
- Check Firebase billing plan (Functions require Blaze plan)
- Verify service account permissions

### "Module not found" error
```bash
npm install
npm run build
```

### "Function execution timeout"
- Increase timeout in firebase.json
- Optimize function code

## 📚 Resources

- [Firebase Functions Docs](https://firebase.google.com/docs/functions)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
- [FCM Server Documentation](https://firebase.google.com/docs/cloud-messaging/server)
