import 'package:flutter/material.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';

class EventDetailsScreen extends StatelessWidget {
  final EventData eventData;

  const EventDetailsScreen({super.key, required this.eventData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(eventData.eventName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section("Organization", "${eventData.organizationType}${eventData.organizationType == 'Other' ? ' (${eventData.customOrg})' : ''}"),
            _section("Date", eventData.selectedDate?.toLocal().toString().split(' ')[0] ?? 'N/A'),
            _section("Time", eventData.selectedTime?.format(context) ?? 'N/A'),
            _section("Location", eventData.locationAddress ?? 'N/A'),
            _section("Members", eventData.eventMembers.join(', ')),
            _section("Goals", eventData.eventGoals.join(', ')),
            _section("Audience", eventData.audienceTags.join(', ')),
            _section("Visibility", eventData.isPublic ? "Public" : "Private"),
            _section("Payment", eventData.isPaid ? "${eventData.eventPrice} ${eventData.eventCurrency}" : "Free"),
            _section("AI Optimization", eventData.jamieEnabled ? "Enabled" : "Disabled"),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                fontSize: 16,
              )),
        ],
      ),
    );
  }
}
