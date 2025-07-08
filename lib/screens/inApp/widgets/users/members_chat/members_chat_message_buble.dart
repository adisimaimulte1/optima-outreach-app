import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/aichat/ai_chat_message_bubble.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:optima/screens/inApp/widgets/users/members_chat/members_chat_message.dart';
import 'package:optima/screens/inApp/widgets/aichat/buttons/mini_menu_button.dart';
import 'package:intl/intl.dart';
import 'package:optima/services/livesync/event_live_sync.dart';


class MembersChatMessageBubble extends StatefulWidget {
  final MembersChatMessage msg;
  final EventData event;
  final bool isMe;
  final bool hasAccess;

  const MembersChatMessageBubble({
    super.key,
    required this.msg,
    required this.event,
    required this.isMe,
    required this.hasAccess,
  });

  @override
  State<MembersChatMessageBubble> createState() => _MembersChatMessageBubbleState();
}

class _MembersChatMessageBubbleState extends State<MembersChatMessageBubble> with TickerProviderStateMixin {
  late final AnimationController _bubbleController;
  late final Animation<double> _scaleAnim;
  late final AnimationController _buttonsController;

  final GlobalKey _bubbleKey = GlobalKey();
  final GlobalKey _buttonsKey = GlobalKey();

  bool _showActions = false;




  @override
  void initState() {
    super.initState();
    usersController.openMessageId.addListener(_syncActionVisibility);

    usersController.bubbleKeyMap[widget.msg.id] = _bubbleKey;
    usersController.buttonsKeyMap[widget.msg.id] = _buttonsKey;

    _bubbleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _bubbleController, curve: Curves.easeOut),
    );
    _buttonsController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
  }



  @override
  void dispose() {
    usersController.openMessageId.removeListener(_syncActionVisibility);
    usersController.bubbleKeyMap.remove(widget.msg.id);
    usersController.buttonsKeyMap.remove(widget.msg.id);
    _bubbleController.dispose();
    _buttonsController.dispose();
    super.dispose();
  }




  void _onLongPress() async {
    usersController.openMessageOptions(widget.msg.id);
  }

  void _syncActionVisibility() {
    final isOpen = usersController.openMessageId.value == widget.msg.id;

    if (isOpen && !_showActions) {
      setState(() => _showActions = true);
      _buttonsController.forward(from: 0);
      _bubbleController.forward(from: 0).then((_) {
        if (mounted) _bubbleController.reverse();
      });
    } else if (!isOpen && _showActions) {
      _hideIcons();
    }
  }

  void _hideIcons() {
    _buttonsController.reverse();
    _bubbleController.reverse();
    usersController.openMessageId.value = null;

    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _showActions = false);
    });
  }




  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Align(
                alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: RawGestureDetector(
                  gestures: {
                    LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
                          () => LongPressGestureRecognizer(duration: const Duration(milliseconds: 200)),
                          (instance) => instance.onLongPress = _onLongPress,
                    ),
                  },
                  child: AnimatedBuilder(
                    animation: _bubbleController,
                    key: _bubbleKey,
                    builder: (context, child) => Transform.scale(scale: _scaleAnim.value, child: child),
                    child: _buildMessageBubble(),
                  ),
                ),
              ),
              if (_showActions) _buildDeleteButton(),
            ],
          ),
          if (_showActions) _buildReactionPickerRow(),
        ],
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Positioned(
      key: _buttonsKey,
      top: 6,
      right: !widget.isMe ? 0 : null,
      left: widget.isMe ? 0 : null,
      child: FadeTransition(
        opacity: _buttonsController,
        child: MiniMenuButton(
          icon: Icons.delete,
          onPressed: () async {
            _hideIcons();
            MembersChatMessage removed = MembersChatMessage(id: '', senderId: '', content: '', timestamp: DateTime.now());

            final index = widget.event.membersChatMessages.indexWhere((m) => m.id == widget.msg.id);
            setState(() {
              removed = widget.event.membersChatMessages[index];

              EventLiveSyncService().getNotifier(widget.event.id!)!.value = widget.event.copyWith(
                membersChatMessages: List<MembersChatMessage>.from(widget.event.membersChatMessages)..removeAt(index));
            });

            final result = await usersController.deleteMessage(widget.msg, widget.event);

            debugPrint('Deleted message: $result');

            if (result != 200)  {
              setState(() {
                EventLiveSyncService().getNotifier(widget.event.id!)!.value.membersChatMessages.insert(index, removed);
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildMessageBubble() {
    final color = widget.isMe ? textHighlightedColor : inAppForegroundColor;
    final border = widget.isMe ? textHighlightedColor : textDimColor;

    return Column(
      crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1.3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.msg.replyTo != null) _buildReplyText(),
              _buildFormattedContent(),
              _buildTimestamp(),
            ],
          ),
        ),
        if (widget.msg.reactions != null && widget.msg.reactions!.isNotEmpty)
          Align(
            alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: GestureDetector(
              onTap: _showReactionSummary,
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _buildReactions(),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReplyText() => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      "↪ ${widget.msg.replyTo}",
      style: const TextStyle(
        color: Colors.white60,
        fontStyle: FontStyle.italic,
        fontSize: 13,
      ),
    ),
  );

  Widget _buildFormattedContent() {
    final baseStyle = TextStyle(
      color: widget.isMe ? inAppForegroundColor : textColor,
      fontWeight: FontWeight.w900,
      fontSize: 15.5,
      height: 1.4,
    );

    return AnimatedHighlightText(
      fullText: widget.msg.content,
      highlight: '',
      baseStyle: baseStyle,
      durationPerChar: Duration.zero,
      isUser: widget.isMe,
      hasPermission: true,
      id: widget.msg.id,
      onFinished: () {},
    );
  }

  Widget _buildTimestamp() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            "${formatDate(widget.msg.timestamp)} - ${DateFormat('h:mm a').format(widget.msg.timestamp)}",
            style: TextStyle(
              color: widget.isMe ? inAppBackgroundColor : Colors.white38,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildReactions() {
    final entries = widget.msg.reactions?.entries.toList() ?? [];

    // Sort by number of reactions descending
    final reactionOrder = reactions.keys.toList(); // ['like', 'love', 'laugh', 'fire', 'sad']

    entries.sort((a, b) {
      final popularityDiff = b.value.length.compareTo(a.value.length);
      if (popularityDiff != 0) return popularityDiff;

      // Fallback to defined order
      final aIndex = reactionOrder.indexOf(a.key);
      final bIndex = reactionOrder.indexOf(b.key);
      return aIndex.compareTo(bIndex);
    });


    return entries.map((entry) {
      final emoji = entry.key;
      final userList = entry.value;
      final icon = reactions[emoji];

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.isMe ? textHighlightedColor : Colors.white24,
            width: 3,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: widget.isMe ? textHighlightedColor : Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              "${userList.length}",
              style: TextStyle(
                color: widget.isMe ? textHighlightedColor : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildReactionPickerRow() {
    final baseColor = widget.hasAccess ? textHighlightedColor : textSecondaryHighlightedColor;
    final uid = FirebaseAuth.instance.currentUser?.email;
    if (uid == null) return const SizedBox();

    return FadeTransition(
      opacity: _buttonsController,
      child: Align(
        alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: inAppForegroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: textDimColor,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: reactions.entries.map((entry) {
              final emoji = entry.key;
              final icon = entry.value;
              final allReactions = widget.msg.reactions ?? {};
              final isReacted = allReactions[emoji]?.contains(uid) ?? false;

              return GestureDetector(
                onTap: () async {
                  final newMap = <String, List<String>>{};

                  // Remove user from all emojis
                  for (final e in allReactions.entries) {
                    final users = List<String>.from(e.value)..remove(uid);
                    if (users.isNotEmpty) {
                      newMap[e.key] = users;
                    }
                  }

                  // If not already selected, add new one
                  if (!isReacted) {
                    newMap[emoji] = [...(newMap[emoji] ?? []), uid];
                  }

                  setState(() {
                    widget.msg.reactions = newMap;
                  });

                  _hideIcons();
                  await usersController.updateMessageReactions(widget.event.id!, widget.msg.id, emoji);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    icon,
                    size: 28,
                    color: isReacted ? baseColor : textColor.withOpacity(0.7),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }



  void _showReactionSummary() {
    final eventId = widget.event.id!;
    final messageId = widget.msg.id;

    popupStackCount.value++;

    final maxHeight = MediaQuery.of(context).size.height * 0.3;

    showModalBottomSheet(
      context: context,
      backgroundColor: inAppForegroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return ValueListenableBuilder<EventData>(
          valueListenable: EventLiveSyncService().getNotifier(eventId)!,
          builder: (context, updatedEvent, __) {
            final updatedMsg = updatedEvent.membersChatMessages.firstWhere((m) => m.id == messageId, orElse: () => widget.msg);
            final allReactions = updatedMsg.reactions ?? {};
            final sortedEntries = allReactions.entries.toList();
            final order = reactions.keys.toList();

            sortedEntries.sort((a, b) {
              final diff = b.value.length.compareTo(a.value.length);
              if (diff != 0) return diff;
              return order.indexOf(a.key).compareTo(order.indexOf(b.key));
            });

            final rowHeight = 28.0;
            final titleHeight = 32.0 + 14;
            final padding = 14.0 * 1;
            final totalHeight = (sortedEntries.length * rowHeight) + titleHeight + padding;

            return SizedBox(
              height: totalHeight.clamp(0, maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  children: [
                    Container(
                      height: 4,
                      width: 50,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: sortedEntries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, index) {
                          final entry = sortedEntries[index];
                          final icon = reactions[entry.key];
                          final users = entry.value;

                          return Row(
                            children: [
                              Expanded(
                                child: Center(
                                  child: Text(
                                    users.join('\n'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w900,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                              Icon(icon, size: 28, color: textHighlightedColor),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() => popupStackCount.value--);
  }
}
