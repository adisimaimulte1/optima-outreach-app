import 'dart:async';
import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
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
  bool _startTyping = false;
  bool _showActions = false;
  Timer? _hideTimer;


  late final AnimationController _bubbleController;
  late final Animation<double> _shakeAnim;
  late final Animation<double> _scaleAnim;
  late final AnimationController _buttonsController;



  @override
  void initState() {
    super.initState();

    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 3.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 3.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _bubbleController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
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
    _bubbleController.dispose();
    _buttonsController.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }




  void _onLongPress() {
    setState(() => _showActions = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showActions = false);
    });
  }

  void _hideIcons() {
    _hideTimer?.cancel();
    setState(() => _showActions = false);
  }

  Widget _actionIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: inAppForegroundColor,
          border: Border.all(color: textDimColor, width: 1.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 30, color: textColor),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final isUser = widget.msg.role == 'user';
    final chat = context.read<ChatController>();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (_showActions)
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideIcons,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox(),
            ),
          ),
        GestureDetector(
          onLongPress: _onLongPress,
            child: Align(
              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: AnimatedBuilder(
                animation: _bubbleController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnim.value, 0),
                    child: Transform.scale(
                      scale: _scaleAnim.value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(maxWidth: 280, minHeight: 40),
                  decoration: BoxDecoration(
                    color: isUser
                        ? (chat.hasPermission ? textSecondaryHighlightedColor : textHighlightedColor)
                        : inAppForegroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isUser
                          ? (chat.hasPermission ? textSecondaryHighlightedColor : textHighlightedColor)
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
        if (_showActions)
          Positioned(
            top: -50,
            right: isUser ? 0 : null,
            left: !isUser ? 0 : null,
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: _buttonsController,
                curve: Curves.easeOutBack,
              ),
              child: Row(
                children: [
                  _actionIcon(Icons.push_pin_rounded, () {
                    debugPrint("📌 Pin message: ${widget.msg.id}");
                    _hideIcons();
                  }),
                  const SizedBox(width: 8),
                  _actionIcon(Icons.delete_outline_rounded, () {
                    debugPrint("🗑️ Delete message: ${widget.msg.id}");
                    _hideIcons();
                  }),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMessageContent(BuildContext context, bool isUser, ChatController chat) {
    final highlight = chat.searchQuery.value;
    final msg = widget.msg;
    final shouldAnimate = !_startTyping || msg.hasAnimated;
    final textStyle = TextStyle(
      color: isUser ? inAppForegroundColor : textColor,
      fontWeight: FontWeight.w600,
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
