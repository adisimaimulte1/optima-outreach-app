import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/screen_wrapper.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScalableScreenWrapper(
      sourceType: SettingsScreen,
      builder: (context, isMinimized, scale) {
        final double cornerRadius = 120.0 * (1 - scale);
        final double borderWidth = 30.0 * (1 - scale);
        final borderColor = isDarkModeNotifier.value ? Colors.white : const Color(0xFF1C2837);

        return Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            color: const Color(0xFF1C2837),
            borderRadius: BorderRadius.circular(cornerRadius),
            border: borderWidth > 0 ? Border.all(width: borderWidth, color: borderColor) : null,
          ),
          child: const SafeArea(
            child: Center(
              child: Text(
                "Settings Screen",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
