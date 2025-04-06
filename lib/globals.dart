import 'package:flutter/material.dart';

final ValueNotifier<double> dashboardScaleNotifier = ValueNotifier(1.0);

final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(false);
final ValueNotifier<bool> isMenuOpenNotifier = ValueNotifier(false);
final ValueNotifier<Type?> selectedScreenNotifier = ValueNotifier(null);




void setupGlobalListeners() {
  dashboardScaleNotifier.addListener(() {
    final scale = dashboardScaleNotifier.value;
    isMenuOpenNotifier.value = scale < 0.99;
  });
}




