import 'package:flutter/material.dart';
import 'package:optima/globals.dart';

class MembersChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  const MembersChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });

  @override
  State<MembersChatInputBar> createState() => _MembersChatInputBarState();
}

class _MembersChatInputBarState extends State<MembersChatInputBar> {
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomInset),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: inAppForegroundColor,
          border: Border.all(color: textDimColor, width: 1.2),
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            const SizedBox(width: 4),
            Flexible(child: _buildTextField()),
            const SizedBox(width: 4),
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 120),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        keyboardType: TextInputType.multiline,
        maxLines: null,
        minLines: 1,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: "Type a message...",
          hintStyle: TextStyle(color: Colors.white60),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }


  Widget _buildSendButton() {
    return GestureDetector(
      onTap: widget.onSend,
      behavior: HitTestBehavior.opaque,
      child: Icon(
        Icons.send,
        color: textColor,
        size: 22,
      ),
    );
  }
}
