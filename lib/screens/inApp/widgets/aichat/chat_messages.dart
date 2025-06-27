import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/aichat/buttons/mini_menu_button.dart';
import 'package:optima/screens/inApp/widgets/aichat/typing_dots.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:provider/provider.dart';
import 'chat_controller.dart';
import 'chat_message.dart';

import 'package:flutter_markdown/flutter_markdown.dart' show MarkdownBody, MarkdownStyleSheet;


class ChatMessageBubble extends StatefulWidget {
  final AiChatMessage msg;
  final EventData event;

  const ChatMessageBubble({
    super.key,
    required this.msg,
    required this.event,
  });

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> with TickerProviderStateMixin {
  late ChatController chat;

  bool _startTyping = false;
  bool _showActions = false;
  bool _wasMinimized = false;
  Timer? _hideTimer;


  late final AnimationController _bubbleController;
  late final Animation<double> _scaleAnim;
  late final AnimationController _buttonsController;


  final GlobalKey _buttonsKey = GlobalKey();


  @override
  void initState() {
    super.initState();
    chat = context.read<ChatController>();

    chat.openMessageId.addListener(_syncActionVisibility);
    screenScaleNotifier.addListener(_handleScaleChange);

    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnim = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _bubbleController, curve: Curves.easeOut),
    );

    _buttonsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    if (widget.msg.content != "...thinking" && !widget.msg.hasAnimated) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _startTyping = true);
      });
    } else {
      _startTyping = true;
    }
  }


  @override
  void dispose() {
    chat.openMessageId.removeListener(_syncActionVisibility);
    screenScaleNotifier.removeListener(_handleScaleChange);

    _bubbleController.dispose();
    _buttonsController.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }




  void _onLongPress() {
    _hideTimer?.cancel();

    chat.openMenu(widget.msg.id);

    _bubbleController.forward(from: 0).whenComplete(() {
      if (mounted) {
        setState(() => _showActions = true);
        _buttonsController.forward(from: 0);

        // Scale back up AFTER icons show
        _bubbleController.reverse();
      }
    });

  }

  void _hideIcons() {
    _hideTimer?.cancel();
    chat.closeMenu();

    _buttonsController.reverse().whenComplete(() {
      if (mounted) {
        setState(() => _showActions = false);
        _bubbleController.reverse();
      }
    });
  }

  void _syncActionVisibility() {
    final openId = chat.openMessageId.value;
    final isOpen = openId == widget.msg.id;

    if (!isOpen && _showActions) {
      _hideIcons();
    }
  }

  void _handleScaleChange() {
    final isMinimized = screenScaleNotifier.value < 0.99;

    if (isMinimized && !_wasMinimized) {
      _wasMinimized = true;
      if (_showActions) _hideIcons();
    } else if (!isMinimized && _wasMinimized) {
      _wasMinimized = false;
    }
  }




  Widget _actionIcon(IconData icon, VoidCallback onTap) {
    return MiniMenuButton(
      icon: icon,
      onPressed: onTap,
    );
  }



  @override
  Widget build(BuildContext context) {
    final isUser = widget.msg.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Dismiss layer
          if (_showActions)
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (event) {
                  final bubbleBox = context.findRenderObject() as RenderBox?;
                  final buttonsBox = _buttonsKey.currentContext?.findRenderObject() as RenderBox?;

                  final tap = event.position;

                  isInsideBox(RenderBox? box) {
                    if (box == null) return false;
                    final offset = box.localToGlobal(Offset.zero);
                    final size = box.size;
                    return tap.dx >= offset.dx &&
                        tap.dx <= offset.dx + size.width &&
                        tap.dy >= offset.dy &&
                        tap.dy <= offset.dy + size.height;
                  }

                  final tappedInsideBubble = isInsideBox(bubbleBox);
                  final tappedInsideButtons = isInsideBox(buttonsBox);

                  if (!tappedInsideBubble && !tappedInsideButtons) {
                    _hideIcons();
                  }
                },

                child: const SizedBox(),
              ),
            ),


          // Message bubble
          Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: RawGestureDetector(
              gestures: {
                LongPressGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
                      () => LongPressGestureRecognizer(duration: const Duration(milliseconds: 200)),
                      (instance) => instance.onLongPress = _onLongPress,
                ),
              },
              child: AnimatedBuilder(
                animation: _bubbleController,
                builder: (context, child) => Transform.scale(
                  scale: _scaleAnim.value,
                  child: child,
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.65,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? (chat.hasPermission ? textHighlightedColor : textSecondaryHighlightedColor)
                        : inAppForegroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isUser
                          ? (chat.hasPermission ? textHighlightedColor : textSecondaryHighlightedColor)
                          : textDimColor,
                      width: 1.3,
                    ),
                  ),
                  child: widget.msg.content == '...thinking'
                      ? const ChatBubbleThinkingDots()
                      : _buildMessageContent(context, isUser, chat),
                ),
              ),
            ),
          ),

          // Action buttons above bubble
          if (_showActions)
            Positioned(
              top: -50,
              right: isUser ? 0 : null,
              left: !isUser ? 0 : null,
              child: AnimatedBuilder(
                animation: Listenable.merge([_buttonsController, screenScaleNotifier]),
                builder: (context, child) {
                  final screenScale = screenScaleNotifier.value;
                  return Transform.scale(
                    scale: screenScale.clamp(0.6, 1.0),
                    alignment: Alignment.topRight,
                    child: FadeTransition(
                      opacity: _buttonsController,
                      child: child,
                    ),
                  );
                },
                child: GestureDetector(
                  key: _buttonsKey,
                  onTapDown: (_) => chat.ignoreNextTap(),
                  child: Row(
                    children: [
                      _actionIcon(Icons.push_pin_outlined, _hideIcons),
                      const SizedBox(width: 8),
                      _actionIcon(Icons.delete, _hideIcons),
                    ],
                  ),
                ),
              )
            ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, bool isUser, ChatController chat) {
    final highlight = chat.searchQuery.value;
    final msg = widget.msg;
    final shouldAnimate = !_startTyping || msg.hasAnimated;
    final textStyle = TextStyle(
      color: isUser ? inAppForegroundColor : textColor,
      fontWeight: FontWeight.w900,
      fontSize: 15.5,
      height: 1.4,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (msg.replyTo != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              "↪ ${msg.replyTo}",
              style: const TextStyle(
                color: Colors.white60,
                fontStyle: FontStyle.italic,
                fontSize: 13,
              ),
            ),
          ),
        _startTyping
            ? AnimatedHighlightText(
          fullText: msg.content,
          highlight: highlight,
          baseStyle: textStyle,
          isUser: isUser,
          hasPermission: chat.hasPermission,
          durationPerChar: shouldAnimate ? Duration.zero : const Duration(milliseconds: 25),
          id: msg.id,
          onFinished: () {} //() => msg.hasAnimated = true,
        )
            : const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            TimeOfDay.fromDateTime(msg.timestamp).format(context),
            style: TextStyle(
              color: isUser ? inAppBackgroundColor : Colors.white38,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}



class AnimatedHighlightText extends StatefulWidget {
  final String fullText;
  final String highlight;
  final TextStyle baseStyle;
  final Duration durationPerChar;
  final bool isUser;
  final bool hasPermission;
  final String id;
  final VoidCallback onFinished;

  const AnimatedHighlightText({
    super.key,
    required this.fullText,
    required this.highlight,
    required this.baseStyle,
    required this.isUser,
    required this.hasPermission,
    required this.id,
    required this.onFinished,
    this.durationPerChar = const Duration(milliseconds: 30),
  });

  @override
  State<AnimatedHighlightText> createState() => _AnimatedHighlightTextState();
}

class _AnimatedHighlightTextState extends State<AnimatedHighlightText> {
  int _visibleChars = 0;
  Timer? _timer;

  bool get _skipAnimation => widget.durationPerChar == Duration.zero || widget.onFinished == _noOp;

  static void _noOp() {}

  @override
  void initState() {
    super.initState();
    if (_skipAnimation) {
      _visibleChars = widget.fullText.length;
    } else {
      _timer = Timer.periodic(widget.durationPerChar, (timer) {
        if (_visibleChars >= widget.fullText.length) {
          timer.cancel();
          widget.onFinished();
        } else {
          setState(() => _visibleChars++);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textToShow = widget.fullText.substring(0, _visibleChars);
    return _buildHighlightedText(textToShow);
  }

  Widget _buildHighlightedText(String content) {
    return MarkdownBody(
      data: content,
      styleSheet: MarkdownStyleSheet(
        p: widget.baseStyle,
        h1: widget.baseStyle.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
        h2: widget.baseStyle.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
        h3: widget.baseStyle.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
        em: widget.baseStyle.copyWith(fontStyle: FontStyle.italic),
        strong: widget.baseStyle.copyWith(fontWeight: FontWeight.bold),
        del: widget.baseStyle.copyWith(decoration: TextDecoration.lineThrough),
        code: widget.baseStyle.copyWith(
          fontFamily: 'monospace',
          backgroundColor: Colors.black.withOpacity(0.4),
          color: widget.baseStyle.color,
        ),
        codeblockPadding: EdgeInsets.zero,
        codeblockDecoration: BoxDecoration(
          color: Colors.transparent,
        ),
        blockquote: widget.baseStyle.copyWith(
          color: Colors.grey[400],
          fontStyle: FontStyle.italic,
        ),
        listBullet: widget.baseStyle,
        blockSpacing: 8,
      ),
    );
  }
}
