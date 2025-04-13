import 'package:flutter/material.dart';
import 'package:optima/ai/ai_assistant.dart';
import 'package:optima/ai/ai_status_dots.dart';

enum JamieState {
  idle,
  listening,
  thinking,
  speaking,
  done,
}

final AIStatusDots aiAssistant = AIStatusDots();
final AIVoiceAssistant aiVoice = AIVoiceAssistant();

final ValueNotifier<double> screenScaleNotifier = ValueNotifier(1.0);

final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(false);
final ValueNotifier<bool> isMenuOpenNotifier = ValueNotifier(false);
final ValueNotifier<Type?> selectedScreenNotifier = ValueNotifier(null);
final ValueNotifier<JamieState> assistantState = ValueNotifier(JamieState.idle);

ValueNotifier<String> transcribedText = ValueNotifier('');

bool wakeWordDetected = false;
bool isListeningForWake = false;
bool keepAiRunning = true;
bool appPaused = false;

AppLifecycleState? currentAppState;

void setupGlobalListeners() {
  screenScaleNotifier.addListener(() {
    final scale = screenScaleNotifier.value;
    isMenuOpenNotifier.value = scale < 0.99;
  });
}




