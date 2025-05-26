import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:optima/ai/ai_recordings.dart';
import 'package:optima/ai/navigator/ai_navigator.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/tutorial/animated_volume.dart';
import 'package:optima/services/storage/local_storage_service.dart';
import 'package:optima/screens/inApp/widgets/settings/buttons/text_button.dart';

class TutorialOverlayScreen extends StatelessWidget {
  const TutorialOverlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                Text(
                  "Welcome to Optima",
                  style: TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  "let's walk through the main features\nJamie will guide you with voice and visuals\nturn your volume up to hear Jamie",
                  style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextButtonWithoutIcon(
                        label: "Skip",
                        onPressed: () async {
                          await LocalStorageService().setSeenTutorial(true);
                          assistantState.value = JamieState.idle;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            Navigator.of(context).pop();
                          });
                        },
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
                        onPressed: () async {
                          await LocalStorageService().setSeenTutorial(true);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            Navigator.of(context).pop();
                          });

                          final bytes = await rootBundle.load(await AiRecordings.getWalkThroughTutorial());

                          final delayMs = 400 + Random().nextInt(100);
                          await Future.delayed(Duration(milliseconds: delayMs));

                          AiNavigator.walkthroughTour(aiAssistantState.context);
                          await aiVoice.playResponseFile(bytes.buffer.asUint8List());

                          assistantState.value = JamieState.idle;
                        },
                        backgroundColor: textHighlightedColor,
                        foregroundColor: Colors.black,
                        fontSize: 17,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
