import 'package:flutter/material.dart';
import 'package:optima/globals.dart';

class ScalableScreenContainer extends StatelessWidget {
  final Widget child;
  final double scale;

  const ScalableScreenContainer({
    super.key,
    required this.child,
    required this.scale,
  });

  double get _cornerRadius => 120.0 * (1 - scale);
  double get _borderWidth => 30.0 * (1 - scale);

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkModeNotifier.value;

    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: const Color(0xFF1C2837),
        borderRadius: BorderRadius.circular(_cornerRadius),
        border: _borderWidth > 0
            ? Border.all(
          width: _borderWidth,
          color: isDark ? Colors.white : const Color(0xFF1C2837),
        )
            : null,
      ),
      child: SafeArea(child: child),
    );
  }
}

