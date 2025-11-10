class ChatUser {
  final String id;
  final String avatar;
  final String name;
  final String email;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isOnline;

  ChatUser({
    required this.id,
    required this.avatar,
    required this.name,
    required this.email,
    this.lastMessage = '',
    this.time = '',
    this.unreadCount = 0,
    this.isOnline = false,
  });
}
