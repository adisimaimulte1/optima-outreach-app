import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:optima/globals.dart';

class TutorialCardItem extends StatefulWidget {
  final int index;
  final double currentPage;
  final String title;
  final IconData icon;

  const TutorialCardItem({
    super.key,
    required this.index,
    required this.currentPage,
    required this.title,
    required this.icon,
  });

  @override
  State<TutorialCardItem> createState() => _TutorialCardItemState();
}

class _TutorialCardItemState extends State<TutorialCardItem> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _controller.forward();
  void _onTapUp(_) async {
    await Future.delayed(const Duration(milliseconds: 120));
    if (mounted) _controller.reverse();
  }

  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          final double distance = (widget.currentPage - widget.index).abs();
          final double pageScale = 1.0 - (0.3 * distance).clamp(0.0, 0.3);
          final double finalScale = pageScale * _scaleAnimation.value;

          return Transform.scale(
            scale: finalScale,
            child: child,
          );
        },
        child: _buildCardContent(),
      ),
    );
  }

  Widget _buildCardContent() {
    return Container(
      width: 220,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/tutorials/tutorial_${widget.index}.png',
              fit: BoxFit.cover,
              cacheWidth: 300,
            ),
            Container(
              color: inAppForegroundColor.withOpacity(0.3),
            ),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.icon, size: 40, color: textHighlightedColor),
                        const SizedBox(height: 10),
                        Text(
                          widget.title,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black, blurRadius: 3)],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
