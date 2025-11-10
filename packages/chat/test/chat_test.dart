import 'package:flutter_test/flutter_test.dart';

import 'package:chat/chat.dart';

void main() {
  test('ChatUser model test', () {
    final chatUser = ChatUser(
      id: '1',
      name: 'Test User',
      email: 'test@example.com',
      avatar: 'avatar.png',
      lastMessage: 'Hello',
      time: '10:00',
      unreadCount: 1,
      isOnline: true,
    );

    expect(chatUser.id, '1');
    expect(chatUser.name, 'Test User');
    expect(chatUser.email, 'test@example.com');
    expect(chatUser.isOnline, true);
  });

  test('Message model test', () {
    final message = Message(
      id: '1',
      senderId: 'user1',
      senderName: 'User 1',
      text: 'Hello World',
      timestamp: DateTime.now(),
      isMe: false,
    );

    expect(message.id, '1');
    expect(message.senderId, 'user1');
    expect(message.text, 'Hello World');
    expect(message.isMe, false);
  });
}
