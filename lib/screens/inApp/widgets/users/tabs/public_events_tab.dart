import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/event_card.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:optima/screens/inApp/widgets/users/join_event_confirmation_dialog.dart';
import 'package:optima/services/notifications/local_notification_service.dart';

class PublicEventsTab extends StatefulWidget {
  const PublicEventsTab({super.key});

  @override
  State<PublicEventsTab> createState() => _PublicEventsTabState();
}

class _PublicEventsTabState extends State<PublicEventsTab> {
  final TextEditingController _searchController = TextEditingController();
  bool _hasUnfocused = false;

  String _selectedTag = 'All';
  List<EventData> get filteredEvents {
    final query = _searchController.text.toLowerCase();
    return upcomingPublicEvents.where((event) {
      final name = event.eventName.toLowerCase();
      final location = (event.locationAddress ?? '').toLowerCase();
      final tags = event.tags ?? [];

      final matchesSearch = name.contains(query) || location.contains(query);
      final matchesTag = _selectedTag == 'All' || tags.contains(_selectedTag);

      return matchesSearch && matchesTag;
    }).toList()..shuffle();
  }




  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        _buildTagFilterBar(), // already implemented
        _buildSearchBar(),
        const SizedBox(height: 10),
        Expanded(child: _buildEventList()),
      ],
    );
  }



  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: inAppForegroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            const Icon(Icons.search, color: Colors.white60, size: 35),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                cursorColor: textHighlightedColor,
                decoration: const InputDecoration(
                  hintText: 'Search by name or location',
                  hintStyle: TextStyle(color: Colors.white30),
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventList() {
    if (filteredEvents.isEmpty) {
      return Center(
        child: Text(
          "no events",
          style: TextStyle(
            color: Colors.white24,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    return ValueListenableBuilder<double>(
      valueListenable: screenScaleNotifier,
      builder: (context, scale, _) {
        if (scale < 0.99 && !_hasUnfocused) {
          _hasUnfocused = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) FocusScope.of(context).unfocus();
          });
        } else if (scale >= 0.99 && _hasUnfocused) {
          _hasUnfocused = false;
        }


        return ListView.builder(
          controller: usersController.publicEventsScrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredEvents.length,
          physics: scale < 0.99
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final event = filteredEvents[index];
            return EventCard(
              eventId: event.id!,
              publicDisplay: true,
              onJoin: _handleJoin,
            );
          },
        );
      },
    );
  }

  Widget _buildTagFilterBar() {
    final tags = ['All', 'Charity', 'Local', 'Tech', 'Sports'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tags.map((tag) {
          final selected = _selectedTag == tag;
          return GestureDetector(
            onTap: () => setState(() => _selectedTag = tag),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? textHighlightedColor : inAppForegroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? textHighlightedColor : Colors.white24,
                  width: 2,
                ),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? inAppBackgroundColor : Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _handleJoin(EventData event) async {
    JoinEventConfirmationDialog.show(context, event.eventName, () async {
      final userEmail = FirebaseAuth.instance.currentUser?.email;
      if (userEmail == null) return;

      // Update Firestore: mark user as pending
      final memberData = {
        'email': userEmail,
        'status': 'pending',
      };

      // Update UI
      setState(() {
        final index = upcomingPublicEvents.indexWhere((e) => e.id == event.id);
        if (index != -1) {
          final original = upcomingPublicEvents[index];
          final updated = original.copyWith(
            eventMembers: List.from(original.eventMembers)..add({
              'email': userEmail,
              'status': 'pending',
            }),
          );
          upcomingPublicEvents[index] = updated;
        }
      });

      final user = FirebaseAuth.instance.currentUser!;
      final memberRef = FirebaseFirestore.instance
          .collection('events')
          .doc(event.id)
          .collection('members')
          .doc(user.uid);

      await memberRef.set(memberData);


      // Notify all managers
      for (final email in event.eventManagers) {
        final query = await FirebaseFirestore.instance
            .collection('public_data')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          await LocalNotificationService().addNotification(
            userId: query.docs.first.id,
            message: 'A user requested to join "${event.eventName}".',
            eventId: event.id!,
            sender: userEmail,
            type: 'event_join_request',
          );
        }
      }
    });
  }
}
