import 'package:flutter/material.dart';
import 'package:optima/screens/inApp/widgets/abstract_screen.dart';
import 'package:optima/screens/inApp/widgets/aichat/chat_controller.dart';
import 'package:optima/screens/inApp/widgets/aichat/chat_drawer.dart';
import 'package:optima/screens/inApp/widgets/aichat/chat_input_bar.dart';
import 'package:optima/screens/inApp/widgets/aichat/chat_messages.dart';
import 'package:optima/screens/inApp/widgets/aichat/chat_top_bar.dart';
import 'package:optima/screens/inApp/widgets/aichat/popups/floating_search_bar.dart';
import 'package:provider/provider.dart';


class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  late final ChatController chat;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    chat = ChatController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    chat.disposeAll();
    super.dispose();
  }


  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    if (bottomInset > 0) {
      // Wait for keyboard to fully open and layout to stabilize
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          chat.scrollToBottom();
        }
      });
    }
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

          return ValueListenableBuilder<bool>(
            valueListenable: chat.isSearchBarVisible,
            builder: (context, isSearchVisible, _) {
              return Consumer<ChatController>(
                builder: (context, chat, _) {
                  final hasEvent = chat.currentEvent != null;

                  return Stack(
                    children: [
                      Scaffold(
                        key: _scaffoldKey,
                        drawer: ChatDrawer(onSelect: chat.setEvent),
                        backgroundColor: Colors.transparent,
                        resizeToAvoidBottomInset: true,
                        body: SafeArea(child: _buildChatBody(chat, hasEvent)),
                      ),
                      if (isSearchVisible) _buildFloatingSearchBar(),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }



  Widget _buildChatBody(ChatController chat, bool hasEvent) {
    return Column(
      children: [
        ChatTopBar(scaffoldKey: _scaffoldKey),
        if (!hasEvent)
          _buildNoEventMessage()
        else ...[
          _buildMessageList(chat),
          _buildChatInput(chat),
        ],
      ],
    );
  }

  Widget _buildNoEventMessage() {
    return Expanded(
      child: Transform.translate(
        offset: const Offset(0, -6), // shift up by 15 pixels
        child: Center(
          child: Text(
            "no events",
            style: TextStyle(
              color: Colors.white24,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList(ChatController chat) {
    final visibleMessages = chat.messages;

    if (visibleMessages.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.white24),
              const SizedBox(height: 8),
              Text(
                "no messages yet",
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        controller: chat.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: visibleMessages.length,
        itemBuilder: (context, index) {
          final msg = visibleMessages[index];
          return ValueListenableBuilder<String>(
            valueListenable: chat.searchQuery,
            builder: (context, query, _) =>
                ChatMessageBubble(
                  key: ValueKey(msg['id']),
                  msg: msg,
                ),
          );
        },
      ),
    );
  }

  Widget _buildChatInput(ChatController chat) {
    return ChatInputBar(
      controller: chat.inputController,
      focusNode: chat.focusNode,
      onSend: chat.sendMessage,
      onImage: chat.pickAndSendImage,
    );
  }

  Widget _buildFloatingSearchBar() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.18,
      left: 20,
      right: 20,
      child: FloatingSearchBar(
        controller: chat.searchTextController,
        onClose: () => chat.toggleSearchBar(false),
        onNext: chat.goToNextMatch,
        onPrevious: chat.goToPreviousMatch,
      ),
    );
  }
}
