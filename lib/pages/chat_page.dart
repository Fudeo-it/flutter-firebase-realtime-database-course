import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_essentials_kit/flutter_essentials_kit.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:telegram_app/blocs/chat/chat_bloc.dart';
import 'package:telegram_app/blocs/friend_status/friend_status_bloc.dart';
import 'package:telegram_app/cubits/user_cubit.dart';
import 'package:telegram_app/cubits/user_status/user_status_cubit.dart';
import 'package:telegram_app/models/user.dart' as models;
import 'package:telegram_app/widgets/connectivity_widget.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatPage extends ConnectivityWidget implements AutoRouteWrapper {
  final User user;
  final models.User other;

  ChatPage({
    Key? key,
    required this.user,
    required this.other,
  }) : super(key: key);

  @override
  Widget wrappedRoute(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => UserStatusCubit(
              other,
              userRepository: context.read(),
            ),
          ),
          BlocProvider(
            create: (context) => FriendStatusBloc(
              friendRepository: context.read(),
            )..fetchStatus(
                me: user.uid,
                user: other.id!,
              ),
          ),
          BlocProvider(
            create: (context) => ChatBloc(
              friendStatusBloc: context.read(),
              chatRepository: context.read(),
            )..findChat(
                user: user.uid,
                other: other.id!,
              ),
          ),
          BlocProvider(
            lazy: false,
            create: (context) => UserCubit(
              user.uid,
              userRepository: context.read(),
              chatBloc: context.read(),
            ),
          ),
        ],
        child: this,
      );

  @override
  Widget connectedBuild(BuildContext context) =>
      BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) => Scaffold(
          appBar: _appBar(
            context,
            chatState: state,
          ),
          body: _body(
            context,
            state: state,
          ),
        ),
      );

  PreferredSizeWidget _appBar(
    BuildContext context, {
    required ChatState chatState,
  }) =>
      AppBar(
        title: BlocConsumer<UserStatusCubit, UserStatusState>(
          listener: (context, state) {
            _shouldShowErrorSnackbar(context, state: state);
          },
          builder: (context, state) => Row(
            children: [
              _otherAvatar(),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _otherName(
                      context,
                      other:
                          state is UpdatedUserStatusState ? state.user : other,
                    ),
                    _otherLastAccess(
                      context,
                      other:
                          state is UpdatedUserStatusState ? state.user : other,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: () {
          final items = [
            if (chatState is ChatAvailableState)
              PopupMenuItem<_AppBarMenuActions>(
                child: Text(
                  AppLocalizations.of(context)?.action_delete_chat ?? '',
                ),
                value: _AppBarMenuActions.ACTION_DELETE,
              ),
          ];

          return items.isNotEmpty
              ? [
                  PopupMenuButton<_AppBarMenuActions>(
                    icon: Icon(Icons.more_vert),
                    itemBuilder: (_) => items,
                    onSelected: (action) {
                      if (_AppBarMenuActions.ACTION_DELETE == action) {
                        _showDeleteChatDialog(
                          context,
                          state: chatState as ChatAvailableState,
                        );
                      }
                    },
                  )
                ]
              : null;
        }(),
      );

  Widget _body(BuildContext context, {required ChatState state}) => Column(
        children: [
          _messagesBody(chatState: state),
          if (state is! ErrorChatState)
            _footer(context, disabled: state is FetchingChatState),
        ],
      );

  Widget _messagesBody({required ChatState chatState}) => Expanded(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/telegram_background.jpg"),
              fit: BoxFit.cover,
            ),
          ),
          child: BlocBuilder<FriendStatusBloc, FriendStatusState>(
            builder: (context, friendStatusState) {
              final friends = friendStatusState is FetchedFriendStatusState &&
                  friendStatusState.friends;

              return Stack(
                children: [
                  if (chatState is NoChatAvailableState &&
                      friendStatusState is FetchedFriendStatusState &&
                      !friendStatusState.friends)
                    _noFriendsWidget(context),
                  if (chatState is NoChatAvailableState && friends)
                    _noMessagesWidget(context),
                  if (chatState is ErrorChatState ||
                      friendStatusState is ErrorFriendStatusState)
                    _genericErrorWidget(context),
                ],
              );
            },
          ),
        ),
      );

  Widget _noFriendsWidget(BuildContext context) => Positioned(
        bottom: 16,
        left: 16,
        right: 16,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.all(Radius.circular(16)),
            border: Border.all(color: Colors.grey[400]!),
          ),
          padding: const EdgeInsets.all(16),
          child: Text(
            AppLocalizations.of(context)?.label_no_friends(other.displayName) ??
                '',
          ),
        ),
      );

  Widget _genericErrorWidget(BuildContext context) => Positioned(
        bottom: 16,
        left: 16,
        right: 16,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.all(Radius.circular(16)),
            border: Border.all(color: Colors.grey[400]!),
          ),
          padding: const EdgeInsets.all(16),
          child: Text(
            AppLocalizations.of(context)?.label_chat_error ?? '',
          ),
        ),
      );

  Widget _noMessagesWidget(BuildContext context) => Positioned(
        bottom: 16,
        left: 16,
        right: 16,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.all(Radius.circular(16)),
            border: Border.all(color: Colors.grey[400]!),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context)?.label_no_messages_available ?? '',
              ),
              MaterialButton(
                onPressed: () => context.read<ChatBloc>().sendMessage(
                      user: user.uid,
                      other: other.id!,
                      message: AppLocalizations.of(context)?.action_hello ?? '',
                    ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.handSparkles,
                      size: 16,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        AppLocalizations.of(context)
                                ?.action_say_hi(other.displayName) ??
                            '',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _footer(BuildContext context, {bool disabled = false}) => Card(
        shape: Border(),
        margin: EdgeInsets.zero,
        child: StreamBuilder<bool>(
            stream: context.watch<ChatBloc>().emptyChat,
            builder: (context, snapshot) => Row(
                  children: [
                    _emojiButton(disabled: disabled),
                    _textField(context),
                    if (!snapshot.hasData || snapshot.data!)
                      _attachmentsButton(disabled: disabled),
                    if (!snapshot.hasData || snapshot.data!)
                      _audioButton(disabled: disabled),
                    if (snapshot.hasData && !snapshot.data!)
                      _sendMessageButton(context, disabled: disabled),
                  ],
                )),
      );

  Widget _emojiButton({bool disabled = false}) => IconButton(
        icon: Icon(Icons.emoji_emotions_outlined),
        onPressed: disabled ? null : () {},
      );

  Widget _textField(BuildContext context) => Expanded(
        child: TwoWayBindingBuilder<String>(
          binding: context.watch<ChatBloc>().messageBinding,
          builder: (
            context,
            controller,
            data,
            onChanged,
            error,
          ) =>
              TextField(
            minLines: 1,
            maxLines: 6,
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              errorText: error?.localizedString(context),
              hintText: AppLocalizations.of(context)?.label_message,
              border: InputBorder.none,
            ),
            keyboardType: TextInputType.text,
          ),
        ),
      );

  Widget _attachmentsButton({bool disabled = false}) => IconButton(
        icon: Icon(Icons.attachment),
        onPressed: disabled ? null : () {},
      );

  Widget _audioButton({bool disabled = false}) => IconButton(
        onPressed: disabled ? null : () {},
        icon: Icon(Icons.mic),
      );

  Widget _sendMessageButton(BuildContext context, {bool disabled = false}) =>
      IconButton(
        icon: Icon(
          Icons.send,
          color: Colors.blue,
        ),
        onPressed: disabled
            ? null
            : () => context
                .read<ChatBloc>()
                .sendMessage(user: user.uid, other: other.id!),
      );

  Widget _otherAvatar() => CircleAvatar(
        child: Text(other.initials),
      );

  Widget _otherName(
    BuildContext context, {
    required models.User other,
  }) =>
      Text(
        other.displayName,
        style: Theme.of(context).textTheme.headline6?.copyWith(
              color: Colors.white,
            ),
      );

  Widget _otherLastAccess(
    BuildContext context, {
    required models.User other,
  }) =>
      Text(
        other.lastAccess != null
            ? timeago.format(
                other.lastAccess!,
                locale: AppLocalizations.of(context)?.localeName,
              )
            : AppLocalizations.of(context)?.label_last_access ?? '',
        style: Theme.of(context).textTheme.caption?.copyWith(
              color: Colors.white70,
            ),
      );

  void _shouldShowErrorSnackbar(
    BuildContext context, {
    required UserStatusState state,
  }) {
    if (WidgetsBinding.instance != null) {
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        if (state is ErrorUserStatusState) {
          final scaffold = ScaffoldMessenger.of(context);

          scaffold.showSnackBar(
            SnackBar(
              content:
                  Text(AppLocalizations.of(context)?.label_other_error ?? ''),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: AppLocalizations.of(context)?.action_ok ?? '',
                onPressed: scaffold.hideCurrentSnackBar,
              ),
            ),
          );
        }
      });
    }
  }

  void _showDeleteChatDialog(
    BuildContext context, {
    required ChatAvailableState state,
  }) {
    if (WidgetsBinding.instance != null) {
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
              title: Text(
                  AppLocalizations.of(context)?.dialog_delete_chat_title ?? ''),
              content: Text(
                  AppLocalizations.of(context)?.dialog_delete_chat_message ??
                      ''),
              actions: [
                TextButton(
                  onPressed: () {
                    context.read<ChatBloc>().deleteChat(state.chat.id!);
                    context.router.pop();
                  },
                  child: Text(AppLocalizations.of(context)?.action_yes ?? ''),
                ),
                TextButton(
                  child: Text(AppLocalizations.of(context)?.action_no ?? ''),
                  onPressed: () => context.router.pop(),
                ),
              ]),
        );
      });
    }
  }
}

enum _AppBarMenuActions {
  ACTION_DELETE,
}
