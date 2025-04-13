import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:optima/screens/inApp/widgets/scalable_screen.dart';
import 'package:optima/globals.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _dotsController;
  late AnimationController _transitionController;
  late Animation<double> _transitionValue;

  late Animation<double> _dot1Opacity;
  late Animation<double> _dot2Opacity;
  late Animation<double> _dot3Opacity;

  Color borderColor = Colors.white;
  Color highlightColor = Colors.white;

  JamieState _currentState = JamieState.idle;
  JamieState _fromState = JamieState.idle;

  _DotStyle _fromStyle = const _DotStyle(
    color: Colors.grey,
    opacity: 0.3,
    size: 15,
    shouldBounce: false,
    shouldDeform: false,
  );

  _DotStyle _toStyle = const _DotStyle(
    color: Colors.grey,
    opacity: 0.3,
    size: 15,
    shouldBounce: false,
    shouldDeform: false,
  );

  @override
  void initState() {
    super.initState();

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _transitionValue = CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeInOut,
    );

    _dot1Opacity = _buildDotOpacity(0.0, 0.33);
    _dot2Opacity = _buildDotOpacity(0.33, 0.66);
    _dot3Opacity = _buildDotOpacity(0.66, 1.0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      aiAssistant.startLoop();
    });
  }

  @override
  void dispose() {
    _dotsController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  Animation<double> _buildDotOpacity(double start, double end) {
    return TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.3), weight: 2),
    ]).animate(
      CurvedAnimation(
        parent: _dotsController,
        curve: Interval(start, end, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    borderColor = isDarkModeNotifier.value ? Colors.white : const Color(0xFF1C2837);
    highlightColor = isDarkModeNotifier.value ? Colors.white : const Color(0xFFFFC62D);

    return ScalableScreenWrapper(
      sourceType: DashboardScreen,
      builder: (context, isMinimized, scale) {
        const double maxCornerRadius = 120.0;
        const double maxBorderWidth = 30;
        final double dynamicCornerRadius = maxCornerRadius * (1 - scale);
        final double dynamicBorderWidth = maxBorderWidth * (1 - scale);

        return Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            color: const Color(0xFF1C2837),
            border: dynamicBorderWidth > 0
                ? Border.all(width: dynamicBorderWidth, color: borderColor)
                : null,
            borderRadius: BorderRadius.circular(dynamicCornerRadius),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 30),
                ValueListenableBuilder<JamieState>(
                  valueListenable: assistantState,
                  builder: (context, state, _) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _handleDotAnimationState(state);
                    });

                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _buildAnimatedDots(),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildTitle(),
                const SizedBox(height: 40),
                _buildPlaceholderContent(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleDotAnimationState(JamieState newState) {
    if (_currentState == newState) return;

    _fromState = _currentState;
    _fromStyle = _toStyle;
    _toStyle = _getDotStyleFromState(newState);
    _currentState = newState;

    _transitionController.reset();
    _transitionController.forward();
  }

  Widget _buildAnimatedDots() {
    final flickerAnimations = [_dot1Opacity, _dot2Opacity, _dot3Opacity];

    return AnimatedBuilder(
      animation: Listenable.merge([_dotsController, _transitionController]),
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final flicker = flickerAnimations[index].value;
            final blend = _transitionValue.value;

            final fromFlickerOpacity = flicker * _fromStyle.opacity;
            final toFlickerOpacity = flicker * _toStyle.opacity;

            final fromFlickerScale = 0.8 + (flicker * 0.2);
            final toFlickerScale = 0.8 + (flicker * 0.2);

            final baseWave = sin((_dotsController.value * 2 * pi) + (index * pi / 1.5)) * 6;

            final fromWave = _fromState == JamieState.thinking ? baseWave : 0.0;
            final toWave = _currentState == JamieState.thinking ? baseWave : 0.0;

            final offsetY = lerpDouble(fromWave, toWave, blend)!;

            final opacity = lerpDouble(fromFlickerOpacity, toFlickerOpacity, blend)!;
            final scale = lerpDouble(fromFlickerScale, toFlickerScale, blend)!;
            final color = Color.lerp(_fromStyle.color, _toStyle.color, blend)!;
            final size = lerpDouble(_fromStyle.size, _toStyle.size, blend)!;

            return Transform.translate(
              offset: Offset(0, -offsetY),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: size,
                    height: size,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildTitle() {
    return Text(
      "Dashboard",
      style: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.bold,
        color: highlightColor,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildPlaceholderContent() {
    return Expanded(
      child: Center(
        child: Text(
          "Build UI here...",
          style: TextStyle(color: Colors.white.withOpacity(0.6)),
        ),
      ),
    );
  }

  _DotStyle _getDotStyleFromState(JamieState state) {
    switch (state) {
      case JamieState.listening:
        return _DotStyle(color: Colors.orange, opacity: 0.7, size: 15, shouldBounce: false, shouldDeform: false);
      case JamieState.thinking:
        return _DotStyle(color: Colors.teal, opacity: 1.0, size: 15, shouldBounce: false, shouldDeform: false);
      case JamieState.speaking:
        return _DotStyle(color: Colors.deepPurpleAccent, opacity: 1.0, size: 15, shouldBounce: false, shouldDeform: true);
      case JamieState.idle:
      default:
        return _DotStyle(color: Colors.grey, opacity: 0.3, size: 15, shouldBounce: false, shouldDeform: false);
    }
  }
}

class _DotStyle {
  final Color color;
  final double opacity;
  final double size;
  final bool shouldBounce;
  final bool shouldDeform;

  const _DotStyle({
    required this.color,
    required this.opacity,
    required this.size,
    required this.shouldBounce,
    required this.shouldDeform,
  });
}
