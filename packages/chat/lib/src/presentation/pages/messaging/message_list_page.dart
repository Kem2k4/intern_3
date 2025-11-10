import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chat/chat.dart';

class MessageListPage extends StatefulWidget {
  const MessageListPage({super.key});

  @override
  State<MessageListPage> createState() => _MessageListPageState();
}

class _MessageListPageState extends State<MessageListPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatUser> allUsers = [];
  List<ChatUser> filteredUsers = [];

  // Track when we last refreshed to avoid spamming
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    // Initialize Chat and load users from Firebase
    context.read<ChatBloc>().add(const InitializeChat());
    context.read<ChatBloc>().add(const LoadUsers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredUsers = allUsers;
      } else {
        filteredUsers = allUsers
            .where(
              (user) =>
                  user.name.toLowerCase().contains(query.toLowerCase()) ||
                  user.email.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  void _refreshUsers() {
    // Throttle refresh to max once per 2 seconds
    final now = DateTime.now();
    if (_lastRefreshTime != null && now.difference(_lastRefreshTime!).inSeconds < 2) {
      return;
    }

    _lastRefreshTime = now;
    context.read<ChatBloc>().add(const LoadUsers());
  }

  void _clearSearch() {
    _searchController.clear();
    _filterUsers('');
  }

  void _updateUserLastMessage(String userId, String messageText, DateTime timestamp) {
    setState(() {
      // Find and update the specific user in allUsers
      final userIndex = allUsers.indexWhere((user) => user.id == userId);
      if (userIndex != -1) {
        final user = allUsers[userIndex];

        // Create updated user with new last message
        final updatedUser = ChatUser(
          id: user.id,
          name: user.name,
          email: user.email,
          avatar: user.avatar,
          lastMessage: messageText,
          time: _formatTime(timestamp),
          unreadCount: user.unreadCount + 1, // Increment unread
          isOnline: user.isOnline,
        );

        // Remove from current position
        allUsers.removeAt(userIndex);
        // Add to top (most recent)
        allUsers.insert(0, updatedUser);

        // Update filtered list as well
        _filterUsers(_searchController.text);
      }
    });
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
      return days[time.weekday % 7];
    } else {
      return '${time.day}/${time.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state is UsersLoaded) {
          setState(() {
            allUsers = state.users;
            filteredUsers = state.users;
          });
        } else if (state is UsersLoadError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Thử lại',
                textColor: Colors.white,
                onPressed: _refreshUsers,
              ),
            ),
          );
        } else if (state is MessageReceived) {
          // Update only the specific user who sent the message
          _updateUserLastMessage(
            state.message.senderId,
            state.message.text,
            state.message.timestamp,
          );
        } else if (state is MessageSent) {
          // Don't need to refresh - optimistic update already handled
          // The message was already added to the chat UI
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: theme.primaryColor,
          title: const Text(
            'Tin nhắn',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                // TODO: Tạo cuộc trò chuyện mới
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tính năng tạo cuộc trò chuyện mới'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              tooltip: 'Tạo cuộc trò chuyện mới',
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // TODO: Menu tùy chọn
              },
              tooltip: 'Tùy chọn',
            ),
          ],
        ),
        body: Column(
          children: [
            // Search bar
            Container(
              color: theme.primaryColor,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextField(
                controller: _searchController,
                onChanged: _filterUsers,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm theo tên hoặc email...',
                  hintStyle: TextStyle(color: Colors.white.withAlpha(179)),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white),
                          onPressed: _clearSearch,
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withAlpha(51),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),

            // Message list
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state is UsersLoading || state is ChatInitializing) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (filteredUsers.isEmpty && allUsers.isEmpty) {
                    return _buildEmptyState();
                  }

                  if (filteredUsers.isEmpty) {
                    return _buildNoResultsState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      _refreshUsers();
                      // Wait a bit for the refresh
                      await Future.delayed(const Duration(seconds: 1));
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: filteredUsers.length,
                      padding: const EdgeInsets.only(top: 8),
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return _buildMessageItem(context, user);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(BuildContext context, ChatUser user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () {
          // Navigate to chat page with ChatBloc
          final chatBloc = context.read<ChatBloc>(); // Đọc ChatBloc trước khi navigate
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => BlocProvider.value(
                value: chatBloc, // Dùng chatBloc đã lưu
                child: MessagePage(user: user),
              ),
            ),
          );
        },
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey[300],
              backgroundImage: user.avatar.isNotEmpty && user.avatar.startsWith('http')
                  ? NetworkImage(user.avatar)
                  : null,
              child: user.avatar.isEmpty || !user.avatar.startsWith('http')
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            if (user.isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.name,
                style: TextStyle(
                  fontWeight: user.unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              user.time,
              style: TextStyle(
                color: user.unreadCount > 0 ? Theme.of(context).primaryColor : Colors.grey[600],
                fontSize: 12,
                fontWeight: user.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  user.lastMessage,
                  style: TextStyle(
                    color: user.unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                    fontWeight: user.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (user.unreadCount > 0)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${user.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Chưa có người dùng nào',
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text('Hãy mời bạn bè tham gia!', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshUsers,
            icon: const Icon(Icons.refresh),
            label: const Text('Tải lại'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy kết quả',
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử tìm kiếm với từ khóa khác',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
