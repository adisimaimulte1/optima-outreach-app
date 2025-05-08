import 'dart:math';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/settings/buttons/text_button.dart';
import 'package:optima/screens/inApp/widgets/settings/dialogs/update_plan_dialog.dart';

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

    aiVoice.startLoop();
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

    if (lastCredit) {
      lastCredit = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        showOutOfCreditsDialog(context);
      });
    }

    return ValueListenableBuilder<JamieState>(
      valueListenable: assistantState,
      builder: (context, state, _) {
        if (state != _lastSeenState) {
          if (lastCredit) {
            debugPrint("lastCredit is true");
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {});
            });
          }

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

    return GestureDetector(
        onTap: _handleManualActivation,
        child: AnimatedBuilder(
          animation: Listenable.merge([_dotsController, _transitionController]),
          builder: (context, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                  decoration: BoxDecoration(
                    color: inAppBackgroundColor.withOpacity(0.99),
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
        )
    );
  }

  void _handleManualActivation() async {
    if (!wakeWordEnabledNotifier.value &&
        jamieEnabledNotifier.value &&
        assistantState.value == JamieState.idle &&
        !aiVoice.aiSpeaking &&
        !aiVoice.isListening) {


      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null && credits > 0) {
        debugPrint("🟣 Jamie manually activated via dots");
        aiVoice.aiSpeaking = false;
        aiVoice.isListening = false;

        aiVoice.wakeWordDetected = true;
        assistantState.value = JamieState.listening;
        aiVoice.startCooldown();
      }
    }

    if (credits < 1){ showOutOfCreditsDialog(context); }
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



  void showOutOfCreditsDialog(BuildContext context) {
    showDialog(
      context: context,
        builder: (_) => ValueListenableBuilder<int>(
        valueListenable: creditNotifier,
        builder: (context, credits, __) {
          // Auto-close dialog if credits > 0
          if (credits > 0) {
            Navigator.of(context, rootNavigator: true).pop();
          }

          return AlertDialog(
            backgroundColor: inAppForegroundColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            titlePadding: const EdgeInsets.only(top: 24),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 12),
            title: Column(
              children: [
                Icon(
                    Icons.credit_card_off_rounded, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  "Out of Credits",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: SizedBox(
              width: 250,
              child: Text(
                "Watch ads or upgrade your plan to continue using voice assistance.",
                style: TextStyle(
                  color: textColor,
                  fontSize: 15.5,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              TextButtonWithoutIcon(
                label: "Close",
                onPressed: () => Navigator.pop(context),
                foregroundColor: Colors.white70,
                fontSize: 16,
                borderColor: Colors.white70,
                borderWidth: 1.2,
              ),
              TextButtonWithoutIcon(
                label: "Get More",
                onPressed: () {
                  Navigator.pop(context);
                  UpgradePlanDialog.show(context, selectedPlan);
                },
                backgroundColor: textHighlightedColor,
                foregroundColor: inAppForegroundColor,
                fontSize: 16,
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 10),
              ),
            ],
          );
        }
        ),
    );
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
