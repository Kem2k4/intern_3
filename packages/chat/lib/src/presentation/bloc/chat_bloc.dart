import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../data/models/chat_user.dart';
import '../../data/models/message.dart';

// Events
abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class InitializeChat extends ChatEvent {
  const InitializeChat();
}

class LoadUsers extends ChatEvent {
  const LoadUsers();
}

class LoadChatHistory extends ChatEvent {
  final String otherUserId;

  const LoadChatHistory(this.otherUserId);

  @override
  List<Object?> get props => [otherUserId];
}

class SendMessage extends ChatEvent {
  final String receiverId;
  final String text;

  const SendMessage(this.receiverId, this.text);

  @override
  List<Object?> get props => [receiverId, text];
}

class ReceiveMessage extends ChatEvent {
  final Message message;

  const ReceiveMessage(this.message);

  @override
  List<Object?> get props => [message];
}

class CheckUserOnlineStatus extends ChatEvent {
  final String userId;

  const CheckUserOnlineStatus(this.userId);

  @override
  List<Object?> get props => [userId];
}

// States
abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatInitializing extends ChatState {
  const ChatInitializing();
}

class ChatReady extends ChatState {
  const ChatReady();
}

class UsersLoading extends ChatState {
  const UsersLoading();
}

class UsersLoaded extends ChatState {
  final List<ChatUser> users;

  const UsersLoaded(this.users);

  @override
  List<Object?> get props => [users];
}

class UsersLoadError extends ChatState {
  final String message;

  const UsersLoadError(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatHistoryLoading extends ChatState {
  const ChatHistoryLoading();
}

class ChatHistoryLoaded extends ChatState {
  final List<Message> messages;
  final String otherUserId;

  const ChatHistoryLoaded(this.messages, this.otherUserId);

  @override
  List<Object?> get props => [messages, otherUserId];
}

class ChatHistoryLoadError extends ChatState {
  final String message;

  const ChatHistoryLoadError(this.message);

  @override
  List<Object?> get props => [message];
}

class MessageSending extends ChatState {
  const MessageSending();
}

class MessageSent extends ChatState {
  const MessageSent();
}

class MessageSendError extends ChatState {
  final String message;

  const MessageSendError(this.message);

  @override
  List<Object?> get props => [message];
}

class MessageReceived extends ChatState {
  final Message message;

  const MessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}

class UserOnlineStatusUpdated extends ChatState {
  final String userId;
  final bool isOnline;

  const UserOnlineStatusUpdated(this.userId, this.isOnline);

  @override
  List<Object?> get props => [userId, isOnline];
}

// BLoC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _repository;
  StreamSubscription? _messageSubscription;

  ChatBloc(this._repository) : super(const ChatInitial()) {
    on<InitializeChat>(_onInitializeChat);
    on<LoadUsers>(_onLoadUsers);
    on<LoadChatHistory>(_onLoadChatHistory);
    on<SendMessage>(_onSendMessage);
    on<ReceiveMessage>(_onReceiveMessage);
    on<CheckUserOnlineStatus>(_onCheckUserOnlineStatus);
  }

  Future<void> _onInitializeChat(InitializeChat event, Emitter<ChatState> emit) async {
    try {
      emit(const ChatInitializing());
      await _repository.initialize();

      // Listen for incoming messages
      _messageSubscription = _repository.messageStream.listen((message) {
        add(ReceiveMessage(message));
      });

      emit(const ChatReady());
    } catch (e) {
      emit(ChatHistoryLoadError('Failed to initialize chat: $e'));
    }
  }

  Future<void> _onLoadUsers(LoadUsers event, Emitter<ChatState> emit) async {
    try {
      emit(const UsersLoading());
      final users = await _repository.getUsers();
      emit(UsersLoaded(users));
    } catch (e) {
      emit(UsersLoadError('Failed to load users: $e'));
    }
  }

  Future<void> _onLoadChatHistory(LoadChatHistory event, Emitter<ChatState> emit) async {
    try {
      emit(const ChatHistoryLoading());
      final messages = await _repository.getChatHistory(event.otherUserId);
      emit(ChatHistoryLoaded(messages, event.otherUserId));
    } catch (e) {
      emit(ChatHistoryLoadError('Failed to load chat history: $e'));
    }
  }

  Future<void> _onSendMessage(SendMessage event, Emitter<ChatState> emit) async {
    try {
      emit(const MessageSending());
      await _repository.sendMessage(event.receiverId, event.text);
      emit(const MessageSent());
    } catch (e) {
      emit(MessageSendError('Failed to send message: $e'));
    }
  }

  Future<void> _onReceiveMessage(ReceiveMessage event, Emitter<ChatState> emit) async {
    emit(MessageReceived(event.message));
  }

  Future<void> _onCheckUserOnlineStatus(
    CheckUserOnlineStatus event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final isOnline = await _repository.isUserOnline(event.userId);
      emit(UserOnlineStatusUpdated(event.userId, isOnline));
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _repository.dispose();
    return super.close();
  }
}
