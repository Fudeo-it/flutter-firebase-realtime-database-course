import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_essentials_kit/misc/two_way_binding.dart';
import 'package:telegram_app/blocs/friend_status/friend_status_bloc.dart';
import 'package:telegram_app/models/chat.dart';
import 'package:telegram_app/repositories/chat_repository.dart';

part 'chat_event.dart';

part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final FriendStatusBloc friendStatusBloc;
  final ChatRepository chatRepository;

  final messageBinding = TwoWayBinding<String>();

  Stream<bool> get emptyChat => messageBinding.stream.map((message) => message == null || message.isEmpty);

  ChatBloc({
    required this.friendStatusBloc,
    required this.chatRepository,
  }) : super(FetchingChatState());

  @override
  Stream<ChatState> mapEventToState(ChatEvent event,) async* {
    if (event is SendMessageEvent) {
      yield* _mapSendMessageEventToState(event);
    } else if (event is CreateChatEvent) {
      yield* _mapCreateChatEventToState(event);
    } else if (event is FindChatEvent) {
      yield* _mapFindChatEventToState(event);
    } else if (event is DeleteChatEvent) {
      yield* _mapDeleteChatEventToState(event);
    }
  }

  Stream<ChatState> _mapSendMessageEventToState(SendMessageEvent event) async* {
    try {
      if (!friendStatusBloc.friends) {
        friendStatusBloc.createFriendship(
          me: event.user,
          user: event.other,
        );
      }

      await chatRepository.update(
        chat: event.chat,
        lastMessage: event.message,
      );
    } catch (error) {
      yield ErrorChatState();
    }
  }

  Stream<ChatState> _mapCreateChatEventToState(CreateChatEvent event) async* {
    Chat? chat;
    try {
      chat = await chatRepository.create(
        me: event.user,
        other: event.other,
        message: event.message,
      );
    } catch (error) {
      yield ErrorChatState();
    }

    if (chat != null) {
      add(
        SendMessageEvent(
          chat.id!,
          user: event.user,
          other: event.other,
          message: event.message,
        ),
      );

      yield ChatAvailableState(chat);
    }
  }

  Stream<ChatState> _mapFindChatEventToState(FindChatEvent event) async* {
    yield FetchingChatState();

    List<Chat>? chats;
    try {
      chats = await chatRepository.find(
        event.user,
        other: event.other,
      );
    } catch (error) {
      yield ErrorChatState();
    }

    if (chats != null) {
      if (chats.length == 1) {
        yield ChatAvailableState(chats.first);
      } else if (chats.isEmpty) {
        yield NoChatAvailableState();
      } else {
        yield ErrorChatState();
      }
    }
  }

  Stream<ChatState> _mapDeleteChatEventToState(DeleteChatEvent event) async* {
    bool success = true;

    try {
      await chatRepository.delete(event.id);
    } catch (error) {
      success = false;
      yield ErrorChatState();
    } finally {
      if (success) {
        yield NoChatAvailableState();
      }
    }
  }

  void findChat({
    required String user,
    required String other,
  }) =>
      add(FindChatEvent(user: user, other: other));

  void sendMessage({
    required String user,
    required String other,
    String? chat,
    String? message,
  }) {
    add(
        (state is ChatAvailableState) ? SendMessageEvent(
          chat ?? (state as ChatAvailableState).chat.id!, user: user,
          other: other,
          message: message ?? messageBinding.value ?? '',) :
        CreateChatEvent(user: user,
          other: other,
          message: message ?? messageBinding.value ?? '',)
    );

    messageBinding.value = '';
  }

  void deleteChat(String id) => add(DeleteChatEvent(id));

  @override
  Future<void> close() async {
    await messageBinding.close();

    return super.close();
  }
}
