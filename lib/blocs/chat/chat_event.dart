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
  List<Object?> get props => [
        ...super.props,
        message,
      ];
}

class SendMessageEvent extends CreateChatEvent {
  final String chat;

  SendMessageEvent(
    this.chat, {
    required String user,
    required String other,
    required String message,
  }) : super(
          user: user,
          other: other,
          message: message,
        );

  @override
  List<Object?> get props => [
        ...super.props,
        chat,
      ];
}

class DeleteChatEvent extends ChatEvent {
  final String id;
  final StreamSubscription? streamSubscription;

  DeleteChatEvent(this.id, {this.streamSubscription,});

  @override
  List<Object?> get props => [id, streamSubscription];
}

class NewMessagesEvent extends ChatEvent {
  final Chat chat;
  final List<Message> messages;
  final StreamSubscription? streamSubscription;

  NewMessagesEvent(
    this.chat, {
    this.messages = const [],
    this.streamSubscription,
  });

  @override
  List<Object?> get props => [
        chat,
        messages,
        streamSubscription,
      ];
}

class EmitErrorChatEvent extends ChatEvent {
  final StreamSubscription? streamSubscription;

  EmitErrorChatEvent(this.streamSubscription);

  @override
  List<Object?> get props => [streamSubscription];
}
