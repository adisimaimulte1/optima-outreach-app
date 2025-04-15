import 'package:flutter/material.dart';
import 'package:optima/globals.dart';

import 'package:optima/screens/inApp/widgets/dashboard/chart.dart';
import 'package:optima/screens/inApp/widgets/dashboard/buttons/new_event_button.dart';
import 'package:optima/screens/inApp/widgets/dashboard/buttons/reminder_bell_button.dart';
import 'package:optima/screens/inApp/widgets/dashboard/cards/upcoming_event.dart';
import 'package:optima/screens/inApp/widgets/dashboard/cards/reminder.dart';
import 'package:optima/screens/inApp/widgets/menu/scalable_screen.dart';
import 'package:optima/screens/inApp/widgets/screen_wrapper.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScalableScreenWrapper(
      sourceType: DashboardScreen,
      builder: (context, isMinimized, scale) {
        return ScalableScreenContainer(
          scale: scale,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 30),
            child: Column(
              children: [
                const SizedBox(height: 30),
                _buildHeader(),
                const SizedBox(height: 30),
                const LineChartCard(),
                const SizedBox(height: 60),
                _buildDashboardRow(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: aiAssistant,
        ),
        const SizedBox(height: 12),
        Builder(
          builder: (context) {
            return responsiveText(
              context,
              "Dashboard",
              maxWidthFraction: 0.6,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDashboardRow(BuildContext context) {
    final double buttonSize = MediaQuery.of(context).size.width * 0.17;
    const double cardHeight = 150.0;
    const double spacing = 10.0;

    final bool hasReminder = false;
    final String reminderText = hasReminder
        ? "Submit report by Friday"
        : "You're all caught up!";

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 20),
        _buildUpcomingEventCard(cardHeight),
        const SizedBox(width: spacing),
        _buildButtonsAndReminderColumn(buttonSize, spacing, cardHeight, hasReminder, reminderText),
        const SizedBox(width: 20),
      ],
    );
  }

  Widget _buildUpcomingEventCard(double height) {
    return Expanded(
      flex: 6,
      child: SizedBox(
        height: height,
        child: UpcomingEventCard(
          key: upcomingCardKey,
          initialTitle: "Client Meeting",
          initialDay: "Tue,",
          initialDate: "Apr 16",
          initialTime: "10:00 AM",
        ),
      ),
    );
  }

  Widget _buildButtonsAndReminderColumn(
      double buttonSize,
      double spacing,
      double totalHeight,
      bool hasReminder,
      String reminderText,
      ) {
    return Expanded(
      flex: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: buttonSize,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: NewEventButton(
                    onTap: () {
                      debugPrint('New Event tapped');
                    },
                    width: buttonSize,
                    height: buttonSize,
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: ReminderBellButton(
                    feedbackCount: hasReminder ? 1 : 0,
                    width: buttonSize,
                    height: buttonSize,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: spacing),
          SizedBox(
            height: totalHeight - buttonSize - spacing,
            child: ReminderStatusCard(
              hasReminder: hasReminder,
              initialText: reminderText,
            ),
          ),
        ],
      ),
    );
  }
}
