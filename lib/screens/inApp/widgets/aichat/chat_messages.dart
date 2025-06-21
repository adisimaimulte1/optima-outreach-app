import 'dart:async';
import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/aichat/typing_dots.dart';
import 'package:provider/provider.dart';
import 'chat_controller.dart';

class ChatMessageBubble extends StatefulWidget {
  final Map<String, String> msg;

  const ChatMessageBubble({super.key, required this.msg});

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> with TickerProviderStateMixin {
  bool _expanded = false;
  bool _startTyping = false;

  @override
  void initState() {
    super.initState();
    _handleInitialAnimationState();
  }

  void _handleInitialAnimationState() {
    final content = widget.msg['content'];
    final id = widget.msg['id'];
    final animate = widget.msg['animate'] != 'false';

    if (content != '...thinking') {
      _expanded = true;

      if (id != null && animatedMessagesCache[id] == true) {
        _startTyping = true;
      } else {
        _startTyping = animate;
      }
    }

  }

  @override
  void didUpdateWidget(covariant ChatMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_transitionedFromThinking(oldWidget)) {
      _triggerThinkingTransitionAnimation();
    }
  }

  bool _transitionedFromThinking(ChatMessageBubble oldWidget) {
    return oldWidget.msg['content'] == '...thinking' &&
        widget.msg['content'] != '...thinking';
  }

  void _triggerThinkingTransitionAnimation() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _expanded = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _startTyping = true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.msg['role'] == 'user';
    final isThinking = widget.msg['content'] == '...thinking';
    final chat = context.read<ChatController>();
    final time = _getFormattedTime();

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: _expanded ? 280 : 80, minHeight: 40),
        decoration: _buildBubbleDecoration(isUser, chat),
        child: _buildBubbleContent(isThinking, isUser, chat, time),
      ),
    );
  }

  String _getFormattedTime() {
    final timestamp = widget.msg['timestamp'];
    if (timestamp == null) return '';
    return TimeOfDay.fromDateTime(DateTime.parse(timestamp)).format(context);
  }

  Decoration _buildBubbleDecoration(bool isUser, ChatController chat) {
    final permissionColor = chat.hasPermission
        ? textSecondaryHighlightedColor
        : textHighlightedColor;

    return BoxDecoration(
      color: isUser ? permissionColor : inAppForegroundColor,
      borderRadius: BorderRadius.circular(_expanded ? 16 : 100),
      border: Border.all(
        color: isUser ? permissionColor : textDimColor,
        width: 1.3,
      ),
    );
  }

  Widget _buildBubbleContent(bool isThinking, bool isUser, ChatController chat, String time) {
    if (!_expanded) return const ChatBubbleThinkingDots();
    if (!_startTyping) return const SizedBox(height: 16);
    return _buildMessageContent(isUser, chat, time);
  }

  Widget _buildMessageContent(bool isUser, ChatController chat, String time) {
    final content = widget.msg['content'] ?? '';
    final highlight = chat.searchQuery.value;
    final duration = widget.msg['animate'] == 'false'
        ? Duration.zero
        : const Duration(milliseconds: 30);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.msg.containsKey('replyTo'))
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              "↪ ${widget.msg['replyTo']}",
              style: const TextStyle(
                color: Colors.white60,
                fontStyle: FontStyle.italic,
                fontSize: 13,
              ),
            ),
          ),
        AnimatedHighlightText(
          fullText: content,
          highlight: highlight,
          baseStyle: TextStyle(
            color: isUser ? inAppForegroundColor : textColor,
            fontWeight: FontWeight.w600,
            fontSize: 15.5,
            height: 1.4,
          ),
          isUser: isUser,
          hasPermission: chat.hasPermission,
          durationPerChar: duration,
          id: widget.msg['id'] ?? '',
        ),
        if (time.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              time,
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


  const AnimatedHighlightText({
    super.key,
    required this.fullText,
    required this.highlight,
    required this.baseStyle,
    required this.isUser,
    required this.hasPermission,
    required this.id,
    this.durationPerChar = const Duration(milliseconds: 30),
  });

  @override
  State<AnimatedHighlightText> createState() => _AnimatedHighlightTextState();
}

class _AnimatedHighlightTextState extends State<AnimatedHighlightText> {
  int _visibleChars = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.durationPerChar == Duration.zero) {
      _visibleChars = widget.fullText.length;
    } else {
      _timer = Timer.periodic(widget.durationPerChar, (timer) {
        if (_visibleChars >= widget.fullText.length) {
          timer.cancel();
          animatedMessagesCache[widget.id] = true;
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
    final visibleText = widget.fullText.substring(0, _visibleChars);
    return _buildHighlightedText(visibleText);
  }

  Widget _buildHighlightedText(String content) {
    if (widget.highlight.isEmpty) return Text(content, style: widget.baseStyle);

    final lowerContent = content.toLowerCase();
    final lowerHighlight = widget.highlight.toLowerCase();

    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lowerContent.indexOf(lowerHighlight, start);
      if (index < 0) {
        spans.add(TextSpan(text: content.substring(start), style: widget.baseStyle));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: content.substring(start, index), style: widget.baseStyle));
      }

      spans.add(TextSpan(
        text: content.substring(index, index + widget.highlight.length),
        style: widget.baseStyle.copyWith(
          backgroundColor: widget.isUser
              ? (widget.hasPermission ? textHighlightedColor : textSecondaryHighlightedColor)
              : inAppBackgroundColor,
          fontWeight: FontWeight.bold,
        ),
      ));

      start = index + widget.highlight.length;
    }

    return RichText(text: TextSpan(children: spans));
  }
}
