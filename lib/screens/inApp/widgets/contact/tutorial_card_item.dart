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

class _TutorialCardItemState extends State<TutorialCardItem> {
  double _pressScale = 1.0;

  void _onTapDown(_) {
    setState(() => _pressScale = 0.85);
  }

  Future<void> _onTapUp(_) async {
    await Future.delayed(const Duration(milliseconds: 120));
    setState(() => _pressScale = 1.0);
  }

  void _onTapCancel() {
    setState(() => _pressScale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final double distance = (widget.currentPage - widget.index).abs();
    final double pageScale = 1.0 - (0.3 * distance).clamp(0.0, 0.3);
    final double finalScale = pageScale * _pressScale;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: finalScale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutBack,
        child: Container(
          width: 220,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white24,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/tutorials/tutorial_${widget.index}.png',
                  fit: BoxFit.cover,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: inAppForegroundColor.withOpacity(0.5),
                  ),
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
                                shadows: [
                                  Shadow(color: Colors.black, blurRadius: 3),
                                ],
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
        ),
      ),
    );
  }
}
