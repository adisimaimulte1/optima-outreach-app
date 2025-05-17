import 'package:flutter/material.dart';
import 'package:optima/screens/inApp/widgets/settings/buttons/text_button.dart';
import 'package:optima/globals.dart';

class EventAIStep extends StatelessWidget {
  final bool jamieEnabled;
  final ValueChanged<bool> onChanged;

  const EventAIStep({
    super.key,
    required this.jamieEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: creditNotifier,
      builder: (context, credits, _) {
        final bool canEnable = credits > 0;

        if (!canEnable && jamieEnabled) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onChanged(false);
          });
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              _title("Use AI assistant"),
              const SizedBox(height: 24),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoItem(
                    icon: Icons.auto_awesome,
                    text: "Jamie helps you plan faster and smarter with AI-generated suggestions.",
                  ),
                  _infoItem(
                    icon: Icons.access_time_outlined,
                    text: "Get reminders and last-minute improvements before the event starts.",
                  ),
                  _infoItem(
                    icon: Icons.show_chart,
                    text: "Track engagement and let Jamie update data in real time.",
                  ),
                  _infoItem(
                    icon: Icons.explore_outlined,
                    text: "Jamie can suggest strategies by analyzing similar events held nearby.",
                  ),
                  const SizedBox(height: 10),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                    child: Text(
                      canEnable
                          ? "You can change this setting later inside the event's information."
                          : "You don't have any credits left. You can enable Jamie later from Settings.",
                      key: ValueKey<bool>(canEnable),
                      style: TextStyle(
                        color: textColor.withOpacity(0.6),
                        fontSize: 13.5,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButtonWithoutIcon(
                    label: "Enable",
                    isEnabled: canEnable,
                    onPressed: () {
                      if (canEnable) onChanged(true);
                    },
                    foregroundColor: jamieEnabled
                        ? inAppForegroundColor
                        : textColor.withOpacity(canEnable ? 1 : 0.4),
                    backgroundColor: jamieEnabled
                        ? textHighlightedColor
                        : Colors.transparent,
                    borderColor: textHighlightedColor.withOpacity(canEnable ? 1 : 0.3),
                    borderWidth: jamieEnabled ? 0 : 1.2,
                    fontSize: 16,
                  ),
                  const SizedBox(width: 16),
                  TextButtonWithoutIcon(
                    label: "Disable",
                    onPressed: () => onChanged(false),
                    foregroundColor: !jamieEnabled
                        ? inAppForegroundColor
                        : textColor,
                    backgroundColor: !jamieEnabled
                        ? textHighlightedColor
                        : Colors.transparent,
                    borderColor: textHighlightedColor,
                    borderWidth: !jamieEnabled ? 0 : 1.2,
                    fontSize: 16,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _title(String t) => Column(
    children: [
      Text(
        t,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 6),
      Container(height: 2, width: 170, color: Colors.white24),
    ],
  );

  Widget _infoItem({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: textHighlightedColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: textColor, fontSize: 13.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
