import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:optima/globals.dart';

class AIStatusDots extends StatefulWidget {
  const AIStatusDots({super.key});

  @override
  State<AIStatusDots> createState() => AIStatusDotsState();
}

class AIStatusDotsState extends State<AIStatusDots> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin  {
  late AnimationController _dotsController;
  late AnimationController _transitionController;
  late AnimationController _speakingController;

  late Animation<double> _transitionValue;

  late Animation<double> _dot1Opacity;
  late Animation<double> _dot2Opacity;
  late Animation<double> _dot3Opacity;

  JamieState? _lastSeenState;

  JamieState _currentState = JamieState.idle;
  JamieState _fromState = JamieState.idle;

  _DotStyle _fromStyle = const _DotStyle(color: Colors.grey, opacity: 0.3, size: 15);
  _DotStyle _toStyle = const _DotStyle(color: Colors.grey, opacity: 0.3, size: 15);

  Future<void> warmUpAssistant(String userId) async {
    await aiVoice.runAssistant(userId: userId);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _dotsController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat();
    _transitionController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _speakingController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);

    _transitionValue = CurvedAnimation(parent: _transitionController, curve: Curves.easeInOut);

    _dot1Opacity = _buildDotOpacity(0.0, 0.33);
    _dot2Opacity = _buildDotOpacity(0.33, 0.66);
    _dot3Opacity = _buildDotOpacity(0.66, 1.0);

    // TODO: Uncomment this in the main app
    // aiVoice.startLoop();
  }

  @override
  void dispose() {
    _dotsController.dispose();
    _transitionController.dispose();
    _speakingController.dispose();
    super.dispose();
  }

  Animation<double> _buildDotOpacity(double start, double end) {
    return TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.3), weight: 2),
    ]).animate(CurvedAnimation(parent: _dotsController, curve: Interval(start, end, curve: Curves.easeInOut)));
  }

  void _handleDotAnimationState(JamieState newState) {
    if (_currentState == newState) return;

    _fromState = _currentState;
    _fromStyle = _toStyle;
    _toStyle = _getDotStyleFromState(newState);

    if (_currentState != JamieState.speaking && newState == JamieState.speaking) {
      _speakingController.repeat(reverse: true);
    }

    _currentState = newState;
    _transitionController.reset();
    _transitionController.forward();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ValueListenableBuilder<JamieState>(
      valueListenable: assistantState,
      builder: (context, state, _) {
        if (state != _lastSeenState) {
          _lastSeenState = state;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleDotAnimationState(state);
          });
        }
        return _buildAnimatedDots();
      },

    );
  }

  Widget _buildAnimatedDots() {
    final flickerAnimations = [_dot1Opacity, _dot2Opacity, _dot3Opacity];
    final yAmplitudes = [0.5, 0.3, 0.6];
    final xAmplitudes = [0.05, 0.03, 0.07];
    final phaseOffsets = [0.0, pi / 1.5, pi];
    const waveSpeed = 0.4;

    return AnimatedBuilder(
      animation: Listenable.merge([_dotsController, _transitionController]),
      builder: (context, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
              decoration: BoxDecoration(
                color: Color(0xFF1C2837).withOpacity(0.99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
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

                  final wave = sin(_speakingController.value * pi * waveSpeed + phaseOffsets[index]);

                  double speakingBlend = 0.0;
                  if (_fromState == JamieState.speaking || _currentState == JamieState.speaking) {
                    speakingBlend = _currentState == JamieState.speaking ? blend : 1.0 - blend;
                  }

                  final scaleY = 1.0 + yAmplitudes[index] * wave * speakingBlend;
                  final scaleX = 0.95 + xAmplitudes[index] * -wave * speakingBlend;

                  return Transform.translate(
                    offset: Offset(0, -offsetY),
                    child: Transform.scale(
                      scale: scale,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.diagonal3Values(scaleX, scaleY, 1),
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
                    ),
                  );
                }),
              ),
          ),
        );
      },
    );
  }

  _DotStyle _getDotStyleFromState(JamieState state) {
    switch (state) {
      case JamieState.listening:
        return _DotStyle(color: Colors.orange, opacity: 0.7, size: 15);
      case JamieState.thinking:
        return _DotStyle(color: Colors.teal, opacity: 1.0, size: 15);
      case JamieState.speaking:
        return _DotStyle(color: Colors.deepPurpleAccent, opacity: 1.0, size: 15);
      case JamieState.idle:
      default:
        return _DotStyle(color: Colors.grey, opacity: 0.3, size: 15);
    }
  }
}

class _DotStyle {
  final Color color;
  final double opacity;
  final double size;

  const _DotStyle({
    required this.color,
    required this.opacity,
    required this.size,
  });
}
