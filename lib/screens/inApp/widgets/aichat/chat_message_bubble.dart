import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/aichat/buttons/mini_menu_button.dart';
import 'package:optima/screens/inApp/widgets/aichat/typing_dots.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:provider/provider.dart';
import 'package:markdown/markdown.dart' as md;
import 'chat_controller.dart';
import 'chat_message.dart';
import 'package:intl/intl.dart';


import 'package:flutter_markdown/flutter_markdown.dart' show MarkdownBody, MarkdownElementBuilder, MarkdownStyleSheet;


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

  late final AnimationController _bubbleController;
  late final Animation<double> _scaleAnim;
  late final AnimationController _buttonsController;

  late final buttonsKey;
  late final bubbleKey;

  @override
  void initState() {
    super.initState();
    chat = context.read<ChatController>();
    buttonsKey = chat.getButtonsKey(widget.msg.id);
    bubbleKey = chat.getBubbleKey(widget.msg.id);

    chat.openMessageId.addListener(_syncActionVisibility);
    screenScaleNotifier.addListener(_handleScaleChange);

    _bubbleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _bubbleController, curve: Curves.easeOut),
    );

    _buttonsController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));

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
    super.dispose();
  }

  void _onLongPress() {
    if (!chat.hasPermission) return;
    chat.openMessageOptions(widget.msg.id);
  }

  void _hideIcons() {
    _buttonsController.reverse();
    _bubbleController.reverse();

    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _showActions = false);
    });
  }


  void _syncActionVisibility() {
    final isOpen = chat.openMessageId.value == widget.msg.id;

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

  void _handleScaleChange() {
    if (!mounted) return;

    final isMinimized = screenScaleNotifier.value < 0.99;
    if (isMinimized && !_wasMinimized) {
      _wasMinimized = true;

      if (_showActions) _hideIcons();
      if (chat.openMessageId.value!.isNotEmpty) {
        chat.closeMessageOptions();
      }
    } else if (!isMinimized && _wasMinimized) {
      _wasMinimized = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.msg.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildMessageBubble(context, isUser),
          if (_showActions) _buildActionButtons(isUser),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: RawGestureDetector(
        key: bubbleKey,
        gestures: {
          LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
                () => LongPressGestureRecognizer(duration: const Duration(milliseconds: 200)),
                (instance) => instance.onLongPress = _onLongPress,
          ),
        },
        child: AnimatedBuilder(
          animation: _bubbleController,
          builder: (context, child) => Transform.scale(scale: _scaleAnim.value, child: child),
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
    );
  }

  Widget _buildActionButtons(bool isUser) {
    return Positioned(
      top: 6,
      right: !isUser ? 0 : null,
      left: isUser ? 0 : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([_buttonsController, screenScaleNotifier]),
        builder: (context, child) {
          final screenScale = screenScaleNotifier.value;
          return Transform.scale(
            scale: screenScale.clamp(0.6, 1.0),
            alignment: Alignment.topRight,
            child: FadeTransition(opacity: _buttonsController, child: child),
          );
        },
        child: Row(
          key: buttonsKey,
          children: [
            MiniMenuButton(
              icon: Icons.push_pin_outlined,
              isActive: widget.msg.isPinned,
              enableActiveStyle: true,
              onPressed: () {
                setState(() {
                  widget.msg.isPinned = !widget.msg.isPinned;
                  chat.pinChatMessage(
                    messageId: widget.msg.id,
                    pin: widget.msg.isPinned,
                  );
                });
              },
            ),
            const SizedBox(width: 8),
            MiniMenuButton(
              icon: Icons.delete,
              onPressed: () async {
                await chat.deleteChatMessage(messageId: widget.msg.id);
              },
            ),
          ],
        ),
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
          onFinished: () {},
        )
            : const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "${formatDate(msg.timestamp)} - ${DateFormat('h:mm a').format(msg.timestamp)}",
                style: TextStyle(
                  color: isUser ? inAppBackgroundColor : Colors.white38,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (msg.isPinned) ...[
                const SizedBox(width: 6),
                Transform.translate(
                  offset: const Offset(0, 4),
                  child: Icon(
                    Icons.push_pin_rounded,
                    size: 16,
                    color: isUser ? inAppBackgroundColor : Colors.white38,
                  ),
                ),
              ],
            ],
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
    final highlight = widget.highlight.trim();
    if (highlight.isEmpty) {
      return MarkdownBody(
        data: content,
        styleSheet: _styleSheet(),
        extensionSet: md.ExtensionSet.gitHubFlavored,
      );
    }

    // Inject ==...== around matches (won’t break Markdown like bold/italic)
    final escaped = RegExp.escape(highlight);
    final pattern = RegExp('($escaped)', caseSensitive: false);

    final injected = content.replaceAllMapped(
      pattern,
          (match) => '==${match[0]}==',
    );

    return MarkdownBody(
      data: injected,
      styleSheet: _styleSheet(),
      extensionSet: md.ExtensionSet(
        md.ExtensionSet.gitHubFlavored.blockSyntaxes,
        [
          ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
          HighlightSyntax(),
        ],
      ),
      builders: {
        'highlight': _HighlightBuilder(widget.baseStyle, widget.isUser, widget.hasPermission),
      },
    );
  }



  MarkdownStyleSheet _styleSheet() {
    return MarkdownStyleSheet(
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
      codeblockDecoration: const BoxDecoration(color: Colors.transparent),
      blockquote: widget.baseStyle.copyWith(
        color: Colors.grey[400],
        fontStyle: FontStyle.italic,
      ),
      listBullet: widget.baseStyle,
      blockSpacing: 8,
    );
  }
}



class HighlightSyntax extends md.InlineSyntax {
  HighlightSyntax() : super(r'==(.+?)==');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final el = md.Element.text('highlight', match[1]!);
    parser.addNode(el);
    return true;
  }
}

class _HighlightBuilder extends MarkdownElementBuilder {
  final TextStyle baseStyle;
  final bool isUser;
  final bool hasPermission;

  _HighlightBuilder(this.baseStyle, this.isUser, this.hasPermission);

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final color = isUser
        ? (hasPermission
        ? textSecondaryHighlightedColor.withOpacity(0.6)
        : textHighlightedColor.withOpacity(0.6))
        : textDimColor.withOpacity(0.3);

    final effectiveStyle = preferredStyle ?? baseStyle;

    return RichText(
      text: TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                element.textContent,
                style: effectiveStyle.copyWith(
                  color: effectiveStyle.color?.withOpacity(0.95),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

