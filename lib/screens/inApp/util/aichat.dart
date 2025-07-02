import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/abstract_screen.dart';
import 'package:optima/screens/inApp/widgets/aichat/chat_controller.dart';
import 'package:optima/screens/inApp/widgets/aichat/chat_drawer.dart';
import 'package:optima/screens/inApp/widgets/aichat/chat_input_bar.dart';
import 'package:optima/screens/inApp/widgets/aichat/chat_message_bubble.dart';
import 'package:optima/screens/inApp/widgets/aichat/chat_top_bar.dart';
import 'package:optima/screens/inApp/widgets/aichat/popups/floating_search_bar.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: chatController,
      child: AbsScreen(
        sourceType: ChatScreen,
        builder: (context, isMinimized, scale) {
          chatController.handleScaleChange(scale);

          if (chatController.isScrollDisabled) {
            FocusScope.of(context).unfocus();
            chatController.focusNode.unfocus();
          }

          if (scale < 0.99 && chatController.isSearchBarVisible.value) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              chatController.toggleSearchBar(false);
            });
          }



          return ValueListenableBuilder<bool>(
            valueListenable: chatController.isSearchBarVisible,
            builder: (context, isSearchVisible, _) {
              return Consumer<ChatController>(
                builder: (context, chat, _) {
                  final currentEvent = chat.currentEvent;

                  return ValueListenableBuilder<double>(
                    valueListenable: screenScaleNotifier,
                    builder: (context, scale, _) {
                      // Close drawer automatically if scale drops
                      if (scale < 0.99 && aiChatScaffoldKey.currentState?.isDrawerOpen == true) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          aiChatScaffoldKey.currentState?.closeDrawer();
                        });
                      }

                      return Stack(
                        children: [
                          Scaffold(
                            key: aiChatScaffoldKey,
                            drawer: ChatDrawer(onSelect: chat.setEvent),
                            drawerEnableOpenDragGesture: scale >= 0.99,
                            backgroundColor: Colors.transparent,
                            resizeToAvoidBottomInset: true,
                            body: SafeArea(child: _buildChatBody(chat, currentEvent)),
                          ),

                          if (scale < 0.99)
                            Positioned.fill(
                              child: AbsorbPointer(
                                absorbing: true,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onPanDown: (_) {
                                    if (aiChatScaffoldKey.currentState?.isDrawerOpen ?? false) {
                                      aiChatScaffoldKey.currentState?.closeDrawer();
                                    }
                                  },
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            ),

                          if (isSearchVisible) _buildFloatingSearchBar(),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );

        },
      ),
    );
  }

  Widget _buildChatBody(ChatController chat, EventData? currentEvent) {
    return Column(
      children: [
        ChatTopBar(scaffoldKey: aiChatScaffoldKey),
        if (currentEvent == null)
          _buildNoEventMessage()
        else ...[
          _buildMessageList(currentEvent),
          _buildChatInput(chat),
        ],
      ],
    );
  }

  Widget _buildNoEventMessage() {
    return Expanded(
      child: Center(
        child: Transform.translate(
          offset: Offset(0, -6),
          child: const Text(
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



  Widget _buildMessageList(EventData event) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (details) => chatController.handleOutsideTap(details, context),
        child: ValueListenableBuilder<bool>(
          valueListenable: chatController.showPinnedOnly,
          builder: (context, showPinnedOnly, _) {
            final allMessages = event.aiChatMessages;
            final filteredMessages = showPinnedOnly
                ? allMessages.where((m) => m.isPinned).toList()
                : allMessages;

            if (filteredMessages.isEmpty) {
              return Center(
                child: Text(
                  showPinnedOnly ? "no pinned messages" : "no messages",
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              );
            }

            return ScrollablePositionedList.builder(
              key: ValueKey(showPinnedOnly),
              itemCount: filteredMessages.length,
              itemScrollController: chatController.itemScrollController,
              itemPositionsListener: chatController.itemPositionsListener,
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemBuilder: (context, index) {
                final msg = filteredMessages[filteredMessages.length - 1 - index];
                return ChatMessageBubble(
                  key: chatController.getBubbleKey(msg.id),
                  msg: msg,
                  event: event,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildChatInput(ChatController chat) {
    final event = chat.currentEvent;

    if (!event!.hasPermission(FirebaseAuth.instance.currentUser!.email!)) return const SizedBox.shrink();

    return ChatInputBar(
      controller: chat.inputController,
      focusNode: chat.focusNode,
      onSend: chat.sendMessage,
    );
  }

  Widget _buildFloatingSearchBar() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.18,
      left: 20,
      right: 20,
      child: FloatingSearchBar(
        controller: chatController.searchTextController,
        onClose: () => chatController.toggleSearchBar(false),
        onNext: chatController.goToNextMatch,
        onPrevious: chatController.goToPreviousMatch,
      ),
    );
  }
}