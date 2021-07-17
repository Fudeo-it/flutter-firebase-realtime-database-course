part of 'chat_bloc.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class FetchingChatState extends ChatState {}

class NoChatAvailableState extends ChatState {}

class ChatAvailableState extends ChatState {
  final Chat chat;

  ChatAvailableState(this.chat);

  @override
  List<Object?> get props => [chat];
}

class ErrorChatState extends ChatState {}
