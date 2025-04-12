import 'package:flutter/material.dart';
import 'package:optima/screens/beforeApp/choose_first_screen.dart';
import 'package:optima/screens/inApp/widgets/scalable_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:optima/globals.dart';
import 'package:optima/ai/ai_assistant.dart'; // <-- Import your AI assistant

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AIVoiceAssistant ai = AIVoiceAssistant();

  @override
  void initState() {
    super.initState();
    _startJamie();
  }

  void _startJamie() {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        ai.runAssistant(userId: userId);
      }
    } catch (e) {
      debugPrint("❌ Jamie startup error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
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
            color: isDarkModeNotifier.value ? Colors.black : Colors.white,
            border: dynamicBorderWidth > 0
                ? Border.all(
              width: dynamicBorderWidth,
              color: isDarkModeNotifier.value
                  ? Colors.white
                  : const Color(0xFF1C2837),
            )
                : null,
            borderRadius: BorderRadius.circular(dynamicCornerRadius),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: ValueListenableBuilder<String>(
                        valueListenable: transcribedText, // optional global or assistant state
                        builder: (context, text, _) => Text(
                          text.isNotEmpty
                              ? text
                              : "Jamie is waiting for you to say 'Hey Jamie'...",
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                  ),
                ),
                _buildJamieStatusUI(),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text("Log Out"),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (!context.mounted) return;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const ChooseFirstScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildJamieStatusUI() {
    final isDark = isDarkModeNotifier.value;
    final bgColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);
    final borderColor = isDark ? Colors.white38 : Colors.black12;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.white10 : Colors.black12,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ValueListenableBuilder<JamieState>(
          valueListenable: assistantState,
          builder: (context, state, _) {
            String label;
            Color color;
            IconData icon;

            switch (state) {
              case JamieState.listening:
                label = "Listening...";
                color = Colors.orange;
                icon = Icons.hearing;
                break;
              case JamieState.thinking:
                label = "Thinking...";
                color = Colors.teal;
                icon = Icons.sync;
                break;
              case JamieState.speaking:
                label = "Jamie is speaking...";
                color = Colors.deepPurple;
                icon = Icons.volume_up;
                break;
              case JamieState.idle:
              default:
                label = "Idle";
                color = Colors.grey;
                icon = Icons.mic_none;
            }

            return Row(
              children: [
                Icon(icon, size: 22, color: color),
                const SizedBox(width: 10),
                Text(label, style: TextStyle(color: color, fontSize: 16)),
              ],
            );
          },
        ),
      ),
    );
  }
}
