import 'package:flutter/material.dart';

import 'package:optima/screens/beforeApp/choose_first_screen.dart';
import 'package:optima/screens/inApp/widgets/scalable_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:optima/globals.dart';


class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
              color: isDarkModeNotifier.value ? Colors.white : const Color(0xFF1C2837),
            )
                : null,
            borderRadius: BorderRadius.circular(dynamicCornerRadius),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Expanded(
                  child: Center(
                    child: Text("Main Content Area", style: TextStyle(fontSize: 22)),
                  ),
                ),
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
}
