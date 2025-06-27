import 'dart:math';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = constraints.maxWidth;
        final double cardHeight = constraints.maxHeight;

        return Container(
          width: cardWidth,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24, width: 2),
            gradient: LinearGradient(
              begin: Alignment.bottomRight,
              end: Alignment.topLeft,
              colors: [
                textHighlightedColor,
                textSecondaryHighlightedColor,
              ],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ..._generateStaticCircles(widget.index, cardWidth, cardHeight),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.icon, size: 40, color: inAppBackgroundColor),
                        const SizedBox(height: 10),
                        Text(
                          widget.title,
                          style: TextStyle(
                            color: inAppBackgroundColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _generateStaticCircles(int seed, double cardWidth, double cardHeight) {
    final List<Widget> circles = [];
    final random = Random(seed);

    const int circleCount = 18;

    for (int i = 0; i < circleCount; i++) {
      final double size = 4 + random.nextDouble() * 4;
      final double top = random.nextDouble() * (cardHeight - size);
      final double left = random.nextDouble() * (cardWidth - size);
      final double opacity = 0.1 + random.nextDouble() * 0.15;

      circles.add(Positioned(
        top: top,
        left: left,
        child: _circle(size, inAppForegroundColor.withOpacity(opacity)),
      ));
    }

    return circles;
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
