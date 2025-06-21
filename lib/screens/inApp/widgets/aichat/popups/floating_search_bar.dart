import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/aichat/buttons/mini_menu_button.dart';
import 'package:optima/screens/inApp/widgets/aichat/chat_controller.dart';
import 'package:provider/provider.dart';

class FloatingSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onClose;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const FloatingSearchBar({
    super.key,
    required this.controller,
    required this.onClose,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  State<FloatingSearchBar> createState() => _FloatingSearchBarState();
}

class _FloatingSearchBarState extends State<FloatingSearchBar> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // Auto-focus after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: inAppForegroundColor,
          border: Border.all(color: textDimColor, width: 1.3),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Consumer<ChatController>(
          builder: (context, chat, _) {
            final matchText = '${chat.currentMatch} / ${chat.totalMatches}';

            return Row(
              children: [
                Expanded(
                  child: TextField(
                    focusNode: _focusNode,
                    controller: widget.controller,
                    onChanged: (v) => context.read<ChatController>().updateSearchQuery(v),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Search messages...',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (matchText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      matchText,
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                MiniMenuButton(onPressed: widget.onPrevious, icon: Icons.keyboard_arrow_up),
                const SizedBox(width: 6),
                MiniMenuButton(onPressed: widget.onNext, icon: Icons.keyboard_arrow_down),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: widget.onClose,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(Icons.close, color: textColor, size: 24),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
