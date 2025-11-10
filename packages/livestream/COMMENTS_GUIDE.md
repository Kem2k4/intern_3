# Livestream Comments Guide

## 📝 Tổng quan

Hệ thống comment realtime cho livestream sử dụng Firebase Realtime Database để đồng bộ comments giữa host và viewers.

## 🏗️ Kiến trúc

### 1. **LivestreamCommentRepository**
- Quản lý tất cả các thao tác với Firebase Realtime Database
- Đường dẫn: `packages/livestream/lib/src/data/repositories/livestream_comment_repository.dart`

### 2. **LivestreamCommentWidget**
- Widget hiển thị danh sách comments realtime
- Đường dẫn: `packages/core_ui/lib/src/widgets/livestream_comment_widget.dart`

### 3. **LivestreamCommentInputWidget**
- Widget input để nhập comment mới
- Đường dẫn: `packages/core_ui/lib/src/widgets/livestream_comment_input_widget.dart`

## 🔥 Firebase Structure

```
livestream_comments/
  └── {channelName}/
      └── {commentId}/
          ├── userId: "uid_123"
          ├── userName: "John Doe"
          ├── userAvatar: "https://..."
          ├── message: "Great stream!"
          └── timestamp: 1730635200000
```

## 🚀 Cách sử dụng

### Host Page (Broadcaster)

```dart
// 1. Khởi tạo repository
late final LivestreamCommentRepository _commentRepository;
late final User? _currentUser;
final String _channelName = 'livestream';

@override
void initState() {
  super.initState();
  _commentRepository = LivestreamCommentRepository();
  _currentUser = FirebaseAuth.instance.currentUser;
}

// 2. Hiển thị comments
LivestreamCommentWidget(
  isVisible: true,
  height: 250,
  commentsStream: _commentRepository.getCommentsStream(_channelName),
)

// 3. Input để gửi comment
LivestreamCommentInputWidget(
  isVisible: true,
  onCommentSubmitted: (message) async {
    if (_currentUser != null) {
      await _commentRepository.addComment(
        channelName: _channelName,
        userId: _currentUser.uid,
        userName: _currentUser.displayName ?? 'Host',
        message: message,
        userAvatar: _currentUser.photoURL ?? '',
      );
    }
  },
  placeholder: 'Comment as host...',
)
```

### Viewer Page

```dart
// Tương tự như Host Page
LivestreamCommentWidget(
  isVisible: isWatching,
  height: 250,
  commentsStream: _commentRepository.getCommentsStream(widget.channelName),
)

LivestreamCommentInputWidget(
  isVisible: isWatching,
  onCommentSubmitted: (message) async {
    if (_currentUser != null) {
      await _commentRepository.addComment(
        channelName: widget.channelName,
        userId: _currentUser.uid,
        userName: _currentUser.displayName ?? 'Viewer',
        message: message,
        userAvatar: _currentUser.photoURL ?? '',
      );
    }
  },
  placeholder: 'Comment as viewer...',
)
```

## 📊 Repository Methods

### `addComment()`
Thêm comment mới vào database
```dart
await _commentRepository.addComment(
  channelName: 'livestream',
  userId: 'user_123',
  userName: 'John Doe',
  message: 'Hello everyone!',
  userAvatar: 'https://...',
);
```

### `getCommentsStream()`
Stream comments realtime
```dart
Stream<List<LivestreamComment>> stream = 
  _commentRepository.getCommentsStream('livestream');
```

### `deleteComment()`
Xóa một comment cụ thể
```dart
await _commentRepository.deleteComment(
  channelName: 'livestream',
  commentId: 'comment_123',
);
```

### `clearAllComments()`
Xóa tất cả comments (thường dùng khi kết thúc stream)
```dart
await _commentRepository.clearAllComments('livestream');
```

### `getCommentCount()`
Lấy số lượng comments
```dart
int count = await _commentRepository.getCommentCount('livestream');
```

## ✨ Features

### ✅ Realtime Updates
- Comments tự động đồng bộ giữa tất cả viewers
- Không cần refresh hoặc pull-to-refresh

### ✅ Auto-scroll
- Tự động scroll xuống khi có comment mới
- Smooth animation

### ✅ User Avatar
- Mỗi user có màu avatar riêng (generated từ userId)
- Hiển thị ký tự đầu tiên của username

### ✅ Comment Limit
- Tự động giới hạn 50 comments gần nhất
- Tránh tải quá nhiều data

### ✅ Error Handling
- Xử lý lỗi kết nối
- Hiển thị loading state
- Skip invalid comments

## 🎨 UI/UX

### Comment Display
- Background trong suốt (alpha: 0.3)
- Comment bubbles với border radius
- Username in đậm
- Message màu trắng

### Comment Input
- Background mờ với rounded corners
- Send button với hiệu ứng visual
- Disable khi chưa nhập text
- Auto-clear sau khi gửi

## 🔒 Security Rules (Firebase)

Thêm rules sau vào Firebase Realtime Database:

```json
{
  "rules": {
    "livestream_comments": {
      "$channelName": {
        ".read": true,
        ".write": "auth != null",
        "$commentId": {
          ".validate": "newData.hasChildren(['userId', 'userName', 'message', 'timestamp'])"
        }
      }
    }
  }
}
```

## 📱 Layout trong Host Page

Host page sử dụng PageView với 2 trang:
1. **Page 0 (Comments)**: Hiển thị comments + input
2. **Page 1 (Controls)**: Hiển thị controls (camera, mic, start/stop)

Swipe trái/phải để chuyển đổi giữa 2 trang.

## 🐛 Troubleshooting

### Comments không hiển thị?
1. Kiểm tra Firebase rules
2. Kiểm tra user đã login chưa
3. Kiểm tra channelName có đúng không

### Comments không realtime?
1. Kiểm tra internet connection
2. Kiểm tra Firebase database URL
3. Check console logs for errors

### Send button không hoạt động?
1. Kiểm tra currentUser != null
2. Kiểm tra message không rỗng
3. Check Firebase permissions

## 📦 Dependencies

```yaml
dependencies:
  firebase_database: ^10.5.7
  firebase_auth: ^4.20.0
```

## 🔄 Lifecycle

### Khi bắt đầu livestream:
- Repository tự động listen stream từ Firebase
- Comments mới sẽ được push realtime

### Khi kết thúc livestream:
- Có thể giữ comments hoặc clear all
- Stream tự động dispose khi widget dispose

## 💡 Best Practices

1. **Always check user authentication** trước khi add comment
2. **Use consistent channel names** giữa host và viewers
3. **Clear old comments** periodically để tránh database bloat
4. **Handle errors gracefully** với try-catch
5. **Dispose streams properly** khi widget dispose

## 🎯 Future Enhancements

- [ ] Emoji reactions
- [ ] Reply to comments
- [ ] Comment moderation (host can delete)
- [ ] Pinned comments
- [ ] Comment filters (profanity, spam)
- [ ] User mentions (@username)
- [ ] Rich text support (bold, italic)
- [ ] Image/GIF comments
- [ ] Comment analytics
