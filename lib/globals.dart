import 'package:flutter/material.dart';

enum JamieState {
  idle,
  listening,
  thinking,
  speaking,
  done,
}

final ValueNotifier<double> screenScaleNotifier = ValueNotifier(1.0);

final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(false);
final ValueNotifier<bool> isMenuOpenNotifier = ValueNotifier(false);
final ValueNotifier<Type?> selectedScreenNotifier = ValueNotifier(null);
final ValueNotifier<JamieState> assistantState = ValueNotifier(JamieState.idle);

bool keepAiRunning = true;


void setupGlobalListeners() {
  screenScaleNotifier.addListener(() {
    final scale = screenScaleNotifier.value;
    isMenuOpenNotifier.value = scale < 0.99;
  });
}




