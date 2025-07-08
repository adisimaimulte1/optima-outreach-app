import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:optima/screens/inApp/widgets/users/members_chat/members_chat_input_bar.dart';
import 'package:optima/screens/inApp/widgets/users/members_chat/members_chat_message.dart';
import 'package:optima/screens/inApp/widgets/users/members_chat/members_chat_message_buble.dart';
import 'package:optima/services/livesync/event_live_sync.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class MembersChatDialog extends StatefulWidget {
  final EventData event;

  const MembersChatDialog({super.key, required this.event});

  @override
  State<MembersChatDialog> createState() => _MembersChatDialogState();
}

class _MembersChatDialogState extends State<MembersChatDialog> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();




  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final msg = MembersChatMessage(
      id: UniqueKey().toString(),
      content: text,
      timestamp: DateTime.now(),
      senderId: user.uid,
      replyTo: null,
      seenBy: [user.uid],
      reactions: {},
    );

    setState(() {
      EventLiveSyncService().getNotifier(widget.event.id!)!.value.membersChatMessages.insert(0, msg);
    });


    if (usersController.itemScrollController.isAttached) {
      usersController.itemScrollController.scrollTo(
        index: 0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0.0,
      );
    }

    _controller.clear();

    await usersController.addMessage(msg, widget.event);

    if (usersController.itemScrollController.isAttached) {
      usersController.itemScrollController.scrollTo(
        index: 0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0.0,
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
    usersController.openMessageId.value = null;
  }




  @override
  Widget build(BuildContext context) {
    final notifier = EventLiveSyncService().getNotifier(widget.event.id!);

    return ValueListenableBuilder<EventData>(
        valueListenable: notifier!,
        builder: (context, liveEvent, _) {
          return _buildContent(liveEvent);
    });
  }

  Widget _buildContent(EventData event) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: usersController.handleOutsideTap,
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1C2837), Color(0xFF24324A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(event),
            const SizedBox(height: 10),
            _buildChatList(event),
            if (_isManagerFor(event))
              MembersChatInputBar(
                controller: _controller,
                focusNode: _focusNode,
                onSend: _sendMessage,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(EventData event) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: _isManagerFor(event) ? textHighlightedColor : textSecondaryHighlightedColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            event.eventName,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: inAppBackgroundColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildChatList(EventData event) {
    final list = event.membersChatMessages;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: list.isEmpty
            ? Center(
          child: Transform.translate(
            offset: const Offset(0, -6),
            child: Text(
              "no messages",
              style: TextStyle(
                color: Colors.white24,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        )
            : ScrollablePositionedList.builder(
          itemCount: list.length,
          itemScrollController: usersController.itemScrollController,
          itemPositionsListener: usersController.itemPositionsListener,
          reverse: true,
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemBuilder: (context, index) {
            final msg = list[index];
            final isMe = msg.senderId == FirebaseAuth.instance.currentUser?.uid;
            return MembersChatMessageBubble(
              key: usersController.getBubbleKey(msg.id),
              msg: msg,
              event: event,
              isMe: isMe,
              hasAccess: _isManagerFor(event),
            );
          },
        ),
      ),
    );
  }


  
  
  bool _isManagerFor(EventData event) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return event.eventManagers.map((e) => e.toLowerCase()).contains(email.toLowerCase());
  }
}
