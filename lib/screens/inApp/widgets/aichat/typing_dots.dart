import 'package:flutter/material.dart';
import 'dart:math';

class ChatBubbleThinkingDots extends StatefulWidget {
  const ChatBubbleThinkingDots({super.key});

  @override
  State<ChatBubbleThinkingDots> createState() => _ChatBubbleThinkingDotsState();
}

class _ChatBubbleThinkingDotsState extends State<ChatBubbleThinkingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const amplitudes = [4.0, 2.5, 5.0];
    const offsets = [0.0, pi / 1.5, pi];

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final offsetY = sin((_controller.value * 2 * pi) + offsets[i]) * amplitudes[i];

            return Transform.translate(
              offset: Offset(0, -offsetY),
              child: Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: Colors.white70,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
