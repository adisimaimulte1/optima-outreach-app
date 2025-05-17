import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/abstract_screen.dart';
import 'package:optima/screens/inApp/widgets/dashboard/buttons/new_event_button.dart';
import 'package:optima/screens/inApp/widgets/events/add_event_form.dart';
import 'package:optima/screens/inApp/widgets/events/buttons/filter_button.dart';
import 'package:optima/screens/inApp/widgets/events/event_card.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:optima/services/storage/cloud_storage_service.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String selectedFilter = 'All';
  bool _disableScroll = false;


  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (showAddEventOnLaunch) {
        showAddEventForm(context);
        showAddEventOnLaunch = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredEvents = selectedFilter == 'All'
        ? events
        : events.where((e) => e.status == selectedFilter).toList();

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
              _buildEventList(filteredEvents),
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

  String _friendlyFilterLabel(String filter) {
    switch (filter) {
      case 'UPCOMING':
        return "upcoming events";
      case 'COMPLETED':
        return "completed events";
      case 'CANCELLED':
        return "cancelled events";
      default:
        return "events";
    }
  }

  Widget _buildEventList(List<EventData> filteredEvents) {
    if (filteredEvents.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            "no ${_friendlyFilterLabel(selectedFilter)}",
            style: TextStyle(
              color: Colors.white30,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: ReorderableListView.builder(
        physics: _disableScroll
            ? const NeverScrollableScrollPhysics()
            : const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        itemCount: filteredEvents.length,
        buildDefaultDragHandles: false,
        proxyDecorator: (child, index, animation) {
          final event = filteredEvents[index];
          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            child: EventCard(
              eventData: event,
              onDelete: (eventToDelete) {
                setState(() {
                  CloudStorageService().deleteEvent(eventToDelete);
                  events.removeWhere((e) => e.id == eventToDelete.id);
                });
              },
              onEdit: (eventToEdit) async {
                final updatedEvent = await showEventFormOverlay(context, initial: eventToEdit);

                if (updatedEvent != null) {
                  setState(() {
                    final index = events.indexOf(eventToEdit);
                    if (index != -1) {
                      events[index] = updatedEvent;
                    }
                  });
                }
              },
              onReplace: (oldEvent, newEvent) {
                setState(() {
                  final oldIndex = events.indexOf(oldEvent);
                  if (oldIndex != -1) {
                    events.removeAt(oldIndex);
                    events.insert(oldIndex, newEvent);
                  }
                });
              },
            ),

          );
        },
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex -= 1;
            final item = filteredEvents.removeAt(oldIndex);
            filteredEvents.insert(newIndex, item);
          });
        },
        itemBuilder: (context, index) {
          final event = filteredEvents[index];
          return ReorderableDragStartListener(
            key: ValueKey(event.id ?? event.eventName),
            index: index,
            child: EventCard(
              eventData: event,
              onDelete: (eventToDelete) {
                setState(() {
                  CloudStorageService().deleteEvent(eventToDelete);
                  events.removeWhere((e) => e.id == eventToDelete.id);
                });
              },
              onEdit: (eventToEdit) async {
                final updatedEvent = await showEventFormOverlay(context, initial: eventToEdit);

                if (updatedEvent != null) {
                  setState(() {
                    final index = events.indexOf(eventToEdit);
                    if (index != -1) {
                      events[index] = updatedEvent;
                    }
                  });
                }
              },
              onReplace: (oldEvent, newEvent) {
                setState(() {
                  final oldIndex = events.indexOf(oldEvent);
                  if (oldIndex != -1) {
                    events.removeAt(oldIndex);
                    events.insert(oldIndex, newEvent);
                  }
                });
              },
            ),
          );
        },
      ),
    );
  }




  void showAddEventForm(BuildContext context) async {
    final result = await Navigator.of(context).push<EventData>(
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
                Positioned.fill(
                  child: Container(color: Colors.black.withOpacity(0.5)),
                ),
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
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    if (result != null) {
      setState(() {
        events.insert(0, result);
      });
    }
  }

  Future<EventData?> showEventFormOverlay(BuildContext context, {EventData? initial}) {
    return Navigator.of(context).push<EventData>(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (_, __, ___) => Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Positioned.fill(
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
              Center(
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                    CurvedAnimation(parent: __, curve: Curves.easeOutBack),
                  ),
                  child: AddEventForm(initialData: initial),
                ),
              ),
            ],
          ),
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }


}
