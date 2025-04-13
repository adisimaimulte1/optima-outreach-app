import 'package:flutter/material.dart';
import 'package:optima/screens/inApp/widgets/chart.dart';
import 'package:optima/screens/inApp/widgets/scalable_screen.dart';
import 'package:optima/globals.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final borderColor = isDarkModeNotifier.value ? Colors.white : const Color(0xFF1C2837);
    final highlightColor = isDarkModeNotifier.value ? Colors.white : const Color(0xFFFFC62D);

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
            color: const Color(0xFF1C2837),
            border: dynamicBorderWidth > 0
                ? Border.all(width: dynamicBorderWidth, color: borderColor)
                : null,
            borderRadius: BorderRadius.circular(dynamicCornerRadius),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: aiAssistant,
                ),
                const SizedBox(height: 12),
                Text(
                  "Dashboard",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: highlightColor,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 24),
                const LineChartCard(),
                const SizedBox(height: 20),
              ],
            ),

          ),
        );
      },
    );
  }
}
