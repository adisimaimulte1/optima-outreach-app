import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:optima/ai/ai_recordings.dart';
import 'package:optima/ai/navigator/ai_navigator.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/tutorial/animated_volume.dart';
import 'package:optima/screens/inApp/widgets/tutorial/touch_blocker.dart';
import 'package:optima/services/storage/local_storage_service.dart';
import 'package:optima/screens/inApp/widgets/settings/buttons/text_button.dart';

class TutorialOverlayScreen extends StatelessWidget {
  final int tutorialNumber;

  const TutorialOverlayScreen({super.key, this.tutorialNumber = 1});

  static final tutorialTitle = [
    "Welcome to Optima!",
    "Setting up events!",
    "Some team management!",
    "How to use me?",
    "Let's do settings!",
  ];

  static final tutorialSubtitle = [
    "let's walk through the main app features",
    "let's see how can you create an event",
    "let's see how can you manage your team",
    "let's see what commands are available",
    "let's see what each setting does exactly",
  ];

  @override
  Widget build(BuildContext context) {
    bool wasJamieEnabled = false;
    bool wasWakeWordDetected = false;

    _disableJamieTemporarily(() {
      wasJamieEnabled = jamieEnabledNotifier.value;
      wasWakeWordDetected = aiVoice.wakeWordDetected;
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AnimatedVolumeIconWithLabel(),
                const SizedBox(height: 30),
                _buildTitle(),
                const SizedBox(height: 20),
                _buildSubtitle(),
                const SizedBox(height: 40),
                _buildButtons(context, wasJamieEnabled, wasWakeWordDetected),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      tutorialTitle[tutorialNumber - 1],
      style: const TextStyle(
        fontSize: 28,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle() {
    return Text(
      "${tutorialSubtitle[tutorialNumber - 1]}\nJamie will guide you through this tutorial\nhold your finger on the screen to cancel",
      style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildButtons(BuildContext context, bool wasJamieEnabled, bool wasWakeWordDetected) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: TextButtonWithoutIcon(
            label: "Skip",
            onPressed: () => _skipTutorial(context, wasJamieEnabled, wasWakeWordDetected),
            foregroundColor: Colors.white70,
            borderColor: Colors.white70,
            borderWidth: 1.2,
            fontSize: 16,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: TextButtonWithoutIcon(
            label: "Start Tutorial",
            onPressed: () => _startTutorial(context, wasJamieEnabled, wasWakeWordDetected),
            backgroundColor: textHighlightedColor,
            foregroundColor: Colors.black,
            fontSize: 17,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }



  Future<void> _skipTutorial(BuildContext context, bool wasJamieEnabled, bool wasWakeWordDetected) async {
    await LocalStorageService().setSeenTutorial(true);
    _restoreJamie(wasJamieEnabled, wasWakeWordDetected);
    aiVoice.logStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pop();
    });
  }

  Future<void> _startTutorial(BuildContext context, bool wasJamieEnabled, bool wasWakeWordDetected) async {
    assistantState.value = JamieState.thinking;
    await LocalStorageService().setSeenTutorial(true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pop();
    });

    final bytes = await rootBundle.load(await AiRecordings.getTutorialRecording(tutorialNumber));
    final delayMs = 400 + Random().nextInt(100);
    await Future.delayed(Duration(milliseconds: delayMs));


    switch (tutorialNumber) {
      case 1:
        await AiNavigator.navigateToScreen(context, "navigate/dashboard");
        break;
      case 2:
        await AiNavigator.navigateToScreen(context, "navigate/events");
        break;
      case 3:
        await AiNavigator.navigateToScreen(context, "navigate/users");
        break;
      case 4:
        isTouchActive.value = false;
        await Future<void>.delayed(const Duration(seconds: 1));
        break;
      case 5:
        await AiNavigator.navigateToScreen(context, "navigate/settings");
        break;
    }


    AiNavigator.showTutorial(aiAssistantState.context, tutorialNumber).catchError((e) {
      if (e is TutorialCancelledException) {
        debugPrint("🛑 Tutorial was cancelled by user");
      } else {
        debugPrint("⚠️ Unexpected tutorial error: $e");
      }
      aiVoice.cancelPlayback();
    });

    aiVoice.aiSpeaking = true;
    await aiVoice.playResponseFile(bytes.buffer.asUint8List(), 0).catchError((e) {
      debugPrint("⚠️ Unexpected tutorial error: $e");
    });

    debugPrint("it's done");
    _restoreJamie(wasJamieEnabled, wasWakeWordDetected);
    aiVoice.logStatus();
  }



  void _restoreJamie(bool wasEnabled, bool wasWakeDetected) {
    if (wasEnabled) {
      jamieEnabled = true;
      jamieEnabledNotifier.value = true;

      if (wasWakeDetected) {
        assistantState.value = JamieState.listening;
        aiVoice.wakeWordDetected = true;
        aiVoice.startCooldown();
      } else {
        assistantState.value = JamieState.idle;
      }
    } else {
      assistantState.value = JamieState.idle;
    }
  }

  void _disableJamieTemporarily(VoidCallback storePreviousState) {
    storePreviousState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      jamieEnabled = false;
      jamieEnabledNotifier.value = false;

      aiVoice.stopLoop(settingsStop: true);
      aiVoice.wakeWordDetected = false;
      aiVoice.isListening = false;
      aiVoice.aiSpeaking = false;
      aiVoice.cooldownActive = false;
    });
  }
}
