import 'package:flutter/material.dart';

final ValueNotifier<double> screenScaleNotifier = ValueNotifier(1.0);

final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(false);
final ValueNotifier<bool> isMenuOpenNotifier = ValueNotifier(false);
final ValueNotifier<Type?> selectedScreenNotifier = ValueNotifier(null);




void setupGlobalListeners() {
  screenScaleNotifier.addListener(() {
    final scale = screenScaleNotifier.value;
    isMenuOpenNotifier.value = scale < 0.99;
  });
}




