part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class FindChatEvent extends ChatEvent {
  final String user;
  final String other;

  FindChatEvent({
    required this.user,
    required this.other,
  });

  @override
  List<Object?> get props => [
        user,
        other,
      ];
}

class CreateChatEvent extends FindChatEvent {
  final String message;

  CreateChatEvent({
    required String user,
    required String other,
    required this.message,
  }) : super(
          user: user,
          other: other,
        );

  @override
  List<Object?> get props => [...super.props, message,];
}

class SendMessageEvent extends CreateChatEvent {
  final String chat;

  SendMessageEvent(this.chat, {
    required String user,
    required String other,
    required String message,
  }) : super(user: user, other: other, message: message,);

  @override
  List<Object?> get props => [...super.props, chat,];
}

class DeleteChatEvent extends ChatEvent {
  final String id;

  DeleteChatEvent(this.id);

  @override
  List<Object?> get props => [id];
}
