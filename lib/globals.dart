import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:optima/ai/ai_assistant.dart';
import 'package:optima/ai/ai_status_dots.dart';
import 'package:optima/screens/inApp/menu.dart';

import 'package:optima/screens/inApp/widgets/dashboard/cards/reminder.dart';
import 'package:optima/screens/inApp/widgets/dashboard/cards/upcoming_event.dart';


final GlobalKey<ReminderStatusCardState> reminderCardKey = GlobalKey<ReminderStatusCardState>();
final GlobalKey<UpcomingEventCardState> upcomingCardKey = GlobalKey<UpcomingEventCardState>();




enum JamieState {
  idle,
  listening,
  thinking,
  speaking,
  done,
}

enum ScreenType {
  dashboard,
  calendar,
  users,
  contact,
  brain,
  settings,
}


final AIStatusDots aiAssistant = AIStatusDots();
final AIVoiceAssistant aiVoice = AIVoiceAssistant();
final appMenu = Menu();


final user = FirebaseAuth.instance.currentUser;


final ValueNotifier<double> screenScaleNotifier = ValueNotifier(1.0);

final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(false);
final ValueNotifier<bool> isMenuOpenNotifier = ValueNotifier(false);

final ValueNotifier<ScreenType> selectedScreenNotifier = ValueNotifier(ScreenType.dashboard);
final ValueNotifier<JamieState> assistantState = ValueNotifier(JamieState.idle);

final ValueNotifier<String> transcribedText = ValueNotifier('');



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

Widget responsiveText(
    BuildContext context,
    String text, {
      required double maxWidthFraction,
      required TextStyle style,
      TextAlign align = TextAlign.center,
    }) {
  final screenWidth = MediaQuery.of(context).size.width;
  return SizedBox(
    width: screenWidth * maxWidthFraction,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        style: style,
        textAlign: align,
      ),
    ),
  );
}




