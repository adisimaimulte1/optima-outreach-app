import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/aichat/ai_chat_controller.dart';
import 'package:provider/provider.dart';

class AiChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  const AiChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });

  @override
  State<AiChatInputBar> createState() => _AiChatInputBarState();
}

class _AiChatInputBarState extends State<AiChatInputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChange);
  }

  void _handleTextChange() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<AiChatController>();
    if (chat.currentEvent == null) return const SizedBox.shrink();

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return ValueListenableBuilder<int>(
      valueListenable: creditNotifier,
      builder: (_, credits, __) {
        final hasCredits = credits > 0;
        return Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomInset),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: hasCredits ? inAppForegroundColor : inAppForegroundColor.withOpacity(0.5),
              border: Border.all(
                color: hasCredits ? textDimColor : Colors.grey,
                width: 1.2,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                const SizedBox(width: 4),
                _buildTextField(hasCredits),
                const SizedBox(width: 4),
                _buildSendButton(hasCredits),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(bool hasCredits) {
    return Expanded(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 120),
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: hasCredits,
          keyboardType: TextInputType.multiline,
          maxLines: null,
          minLines: 1,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: hasCredits
                ? "Ask Jamie something..."
                : "You need credits to ask Jamie.",
            hintStyle: const TextStyle(color: Colors.white60),
            border: InputBorder.none,
            isDense: true,
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton(bool hasCredits) {
    final isSendActive = hasCredits && _hasText;
    return GestureDetector(
      onTap: isSendActive ? widget.onSend : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          Icons.send,
          color: isSendActive ? textColor : Colors.grey,
          size: 22,
        ),
      ),
    );
  }
}