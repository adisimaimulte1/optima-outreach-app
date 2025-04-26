import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/abstract_screen.dart';
import 'package:optima/screens/inApp/widgets/dashboard/buttons/new_event_button.dart';
import 'package:optima/screens/inApp/widgets/events/add_event_form.dart';
import 'package:optima/screens/inApp/widgets/events/buttons/filter_button.dart';
import 'package:optima/screens/inApp/widgets/events/card.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String selectedFilter = 'All';
  bool _disableScroll = false;


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
        if ((_disableScroll && scale >= 0.99) || (!_disableScroll && scale < 0.99)) {
          _disableScroll = scale < 0.99;
        }

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
            children: [
              Icon(LucideIcons.calendarDays, color: textColor, size: 28),
              SizedBox(width: 8),
              Text(
                "Events",
                style: TextStyle(
                  color: textColor,
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
                onTap: () { showAddEventForm(context); },
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
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Divider(color: textDimColor, thickness: 1),
    );
  }

  Widget _buildEventList(List<Map<String, String>> filteredData) {
    return Expanded(
      child: ListView.builder(
        physics: _disableScroll
            ? const NeverScrollableScrollPhysics()
            : const BouncingScrollPhysics(),
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



  void showAddEventForm(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 150),
        reverseTransitionDuration: const Duration(milliseconds: 150),
        pageBuilder: (_, __, ___) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                // Static black overlay background (not scaling)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
                // Centered form scales in
                Center(
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                      CurvedAnimation(
                        parent: __,
                        curve: Curves.easeOutBack,
                      ),
                    ),
                    child: const AddEventForm(),
                  ),
                ),
              ],
            ),
          );
        },
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }
}
