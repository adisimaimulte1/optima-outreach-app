import 'package:flutter/material.dart';
import 'package:optima/screens/inApp/widgets/abstract_screen.dart';
import 'package:optima/screens/inApp/widgets/dashboard/buttons/new_event_button.dart'; // adjust path if needed

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AbsScreen(
      sourceType: EventsScreen,
      builder: (context, isMinimized, scale) {
        return Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          "My Events",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 52), // reserve space for button
                      ],
                    ),
                  ),

                  // Event List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Event ${index + 1}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "April 30, 2025 – 3:00 PM",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // New Event Button
            Positioned(
              right: 24,
              bottom: 24,
              child: NewEventButton(
                width: 60,
                height: 60,
                onTap: () {
                  // TODO: Navigate to the create event screen
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
