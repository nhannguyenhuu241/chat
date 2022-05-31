import 'package:chat/chat_ui/widgets/replied_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import '../util.dart';
import 'inherited_chat_theme.dart';
import 'inherited_l10n.dart';
import 'inherited_user.dart';

/// A class that represents file message widget
class FileMessage extends StatelessWidget {
  /// Creates a file message widget based on a [types.FileMessage]
  const FileMessage({
    Key? key,
    required this.message,
    required this.showUserNameForRepliedMessage,
    required this.onMessageTap,
  }) : super(key: key);

  /// [types.FileMessage]
  final types.FileMessage message;

  /// Show user name for replied message.
  final bool showUserNameForRepliedMessage;

  /// See [Message.onMessageTap]
  final void Function(BuildContext context, types.Message)? onMessageTap;

  @override
  Widget build(BuildContext context) {
    final _user = InheritedUser
        .of(context)
        .user;
    final _color = _user.id == message.author.id
        ? InheritedChatTheme
        .of(context)
        .theme
        .sentMessageDocumentIconColor
        : InheritedChatTheme
        .of(context)
        .theme
        .receivedMessageDocumentIconColor;

    return Semantics(
      label: InheritedL10n
          .of(context)
          .l10n
          .fileButtonAccessibilityLabel,
      child: Container(
        padding: EdgeInsetsDirectional.fromSTEB(
          InheritedChatTheme
              .of(context)
              .theme
              .messageInsetsVertical,
          InheritedChatTheme
              .of(context)
              .theme
              .messageInsetsVertical,
          InheritedChatTheme
              .of(context)
              .theme
              .messageInsetsHorizontal,
          InheritedChatTheme
              .of(context)
              .theme
              .messageInsetsVertical,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.repliedMessage != null)
              RepliedMessage(
                messageAuthorId: message.author.id,
                repliedMessage: message.repliedMessage,
                showUserNames: showUserNameForRepliedMessage,
                onMessageTap: onMessageTap,
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(21),
                  ),
                  height: 42,
                  width: 42,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (message.isLoading ?? false)
                        Positioned.fill(
                          child: CircularProgressIndicator(
                            color: _color,
                            strokeWidth: 2,
                          ),
                        ),
                      InheritedChatTheme
                          .of(context)
                          .theme
                          .documentIcon != null
                          ? InheritedChatTheme
                          .of(context)
                          .theme
                          .documentIcon!
                          : Image.asset(
                        'assets/icon-document.png',
                        color: _color,
                        package: 'chat',
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Container(
                    margin: const EdgeInsetsDirectional.only(
                      start: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.name,
                          style: _user.id == message.author.id
                              ? InheritedChatTheme
                              .of(context)
                              .theme
                              .sentMessageBodyTextStyle
                              : InheritedChatTheme
                              .of(context)
                              .theme
                              .receivedMessageBodyTextStyle,
                          textWidthBasis: TextWidthBasis.longestLine,
                        ),
                        Container(
                          margin: const EdgeInsets.only(
                            top: 4,
                          ),
                          child: Text(
                            formatBytes(message.size.truncate()),
                            style: _user.id == message.author.id
                                ? InheritedChatTheme
                                .of(context)
                                .theme
                                .sentMessageCaptionTextStyle
                                : InheritedChatTheme
                                .of(context)
                                .theme
                                .receivedMessageCaptionTextStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}