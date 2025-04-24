import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:optima/screens/inApp/widgets/abstract_screen.dart';
import 'package:optima/screens/inApp/widgets/dashboard/buttons/new_event_button.dart';
import 'package:optima/screens/inApp/widgets/events/buttons/filter_button.dart';
import 'package:optima/screens/inApp/widgets/events/card.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String selectedFilter = 'All';

  final List<Map<String, String>> eventData = [
    {"title": "Red Cross Fundraiser", "date": "Apr 30, 2025", "time": "3:00 PM", "status": "UPCOMING"},
    {"title": "Beach Cleanup", "date": "May 4, 2025", "time": "10:00 AM", "status": "UPCOMING"},
    {"title": "Leadership Workshop", "date": "Mar 12, 2025", "time": "5:00 PM", "status": "COMPLETED"},
    {"title": "Volunteer Coordination", "date": "May 8, 2025", "time": "2:00 PM", "status": "UPCOMING"},
    {"title": "Fundraiser Wrap-Up", "date": "May 12, 2025", "time": "4:00 PM", "status": "COMPLETED"},
    {"title": "Hospital Donation Drive", "date": "May 15, 2025", "time": "11:00 AM", "status": "UPCOMING"},
    {"title": "Blood Drive", "date": "May 20, 2025", "time": "9:00 AM", "status": "UPCOMING"},
    {"title": "Disaster Response Training", "date": "May 22, 2025", "time": "3:30 PM", "status": "COMPLETED"},
    {"title": "Medical Supply Sorting", "date": "May 25, 2025", "time": "1:00 PM", "status": "UPCOMING"},
    {"title": "Community Safety Day", "date": "May 28, 2025", "time": "12:00 PM", "status": "UPCOMING"},
    {"title": "First Aid Workshop", "date": "May 30, 2025", "time": "10:00 AM", "status": "CANCELLED"},
    {"title": "Emergency Prep Drill", "date": "Jun 2, 2025", "time": "6:00 PM", "status": "UPCOMING"},
  ];

  @override
  Widget build(BuildContext context) {
    final filteredData = selectedFilter == 'All'
        ? eventData
        : eventData.where((e) => e['status'] == selectedFilter).toList();

    return AbsScreen(
      sourceType: EventsScreen,
      builder: (context, isMinimized, scale) {
        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              _buildHeader(),
              _buildDivider(),
              _buildEventList(filteredData),
            ],
          ),
        );
      },
    );
  }



  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(LucideIcons.calendarDays, color: Colors.white, size: 28),
              SizedBox(width: 8),
              Text(
                "Events",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildFilterMenu(),
              const SizedBox(width: 12),
              NewEventButton(
                width: 48,
                height: 48,
                onTap: () {
                  // TODO: Navigate to Create Event screen
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterMenu() {
    return FilterButton(
      selectedValue: selectedFilter,
      options: const ['All', 'UPCOMING', 'COMPLETED', 'CANCELLED'],
      onSelected: (value) => setState(() => selectedFilter = value),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Divider(color: Colors.white12, thickness: 1),
    );
  }

  Widget _buildEventList(List<Map<String, String>> filteredData) {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        itemCount: filteredData.length,
        itemBuilder: (context, index) {
          final e = filteredData[index];
          return EventCard(
            title: e["title"]!,
            date: e["date"]!,
            time: e["time"]!,
            status: e["status"]!,
          );
        },
      ),
    );
  }
}
