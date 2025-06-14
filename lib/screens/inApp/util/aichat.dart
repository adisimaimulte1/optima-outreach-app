import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/abstract_screen.dart';
import 'package:optima/screens/inApp/widgets/aichat/chat_controller.dart';
import 'package:optima/screens/inApp/widgets/aichat/chat_drawer.dart';
import 'package:optima/screens/inApp/widgets/aichat/chat_input_bar.dart';
import 'package:optima/screens/inApp/widgets/aichat/chat_messages.dart';
import 'package:optima/screens/inApp/widgets/aichat/chat_top_bar.dart';
import 'package:provider/provider.dart';


class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatController chat;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    chat = ChatController();
  }

  @override
  void dispose() {
    chat.disposeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: chat,
      child: AbsScreen(
        sourceType: ChatScreen,
        builder: (context, isMinimized, scale) {
          final disableScroll = scale < 0.99;
          if (disableScroll) {
            FocusScope.of(context).unfocus();
            chat.focusNode.unfocus();
          }

          return Scaffold(
            key: _scaffoldKey,
            drawer: ChatDrawer(
              onSelect: chat.setEvent,
            ),
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Column(
                children: [
                  ChatTopBar(
                    scaffoldKey: _scaffoldKey,
                  ),

                  Expanded(
                    child: Consumer<ChatController>(
                      builder: (context, chat, _) {
                        if (chat.currentEvent == null) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 60),
                              child: Text(
                                "select an event to \n start chatting",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white24,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: chat.scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          itemCount: chat.messages.length,
                          itemBuilder: (context, index) =>
                              ChatMessageBubble(msg: chat.messages[index]),
                        );
                      },
                    ),
                  ),

                  ChatInputBar(
                    controller: chat.inputController,
                    focusNode: chat.focusNode,
                    onSend: chat.sendMessage,
                    onImage: chat.pickAndSendImage,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
