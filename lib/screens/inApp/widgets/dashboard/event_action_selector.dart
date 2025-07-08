import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'buttons/go_event_button.dart';

class EventActionSelectorWheel extends StatefulWidget {
  const EventActionSelectorWheel({super.key});

  @override
  State<EventActionSelectorWheel> createState() => _EventActionSelectorWheelState();
}

class _EventActionSelectorWheelState extends State<EventActionSelectorWheel> {
  int selectedEventIndex = 0;
  int selectedActionIndex = 0;

  final List<String> actions = ["Details", "AI Chat", "Members"];
  final FixedExtentScrollController eventScroll = FixedExtentScrollController();
  final FixedExtentScrollController actionScroll = FixedExtentScrollController();

  @override
  void initState() {
    super.initState();
  }



  @override
  Widget build(BuildContext context) => _buildLayout(context);

  Widget _buildLayout(BuildContext context) {
    final cardHeight = MediaQuery.of(context).size.width * 0.17;

    return AnimatedBuilder(
        animation: combinedEventsListenable,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GoEventButton(
                    onTap: _handleGo,
                    size: cardHeight,
                  ),
                ),
                Expanded(child: _buildCard(cardHeight)),
              ],
            ),
          );
          },
    );
  }

  Widget _buildCard(double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: inAppForegroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textDimColor, width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildEventWheel(),
          _buildActionWheel(),
        ],
      ),
    );
  }

  Widget _buildEventWheel() {
    final hasEvents = events.isNotEmpty;

    return _buildWheel(
      title: "Event",
      itemCount: events.isEmpty ? 1 : events.length,
      itemBuilder: (i) => hasEvents
          ? events[i].eventName
          : "no events",
      controller: eventScroll,
      onSelectedItemChanged: (i) {
        if (hasEvents) {
          setState(() => selectedEventIndex = i);
        }
      },
    );
  }


  Widget _buildActionWheel() {
    return _buildWheel(
      title: "Action",
      itemCount: actions.length,
      itemBuilder: (i) => actions[i],
      controller: actionScroll,
      onSelectedItemChanged: (i) => setState(() => selectedActionIndex = i),
    );
  }

  Widget _buildWheel({
    required String title,
    required int itemCount,
    required String Function(int) itemBuilder,
    required FixedExtentScrollController controller,
    required void Function(int) onSelectedItemChanged,
  }) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 36, // Match itemExtent exactly
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: inAppForegroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: textHighlightedColor, width: 3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ListWheelScrollView.useDelegate(
                controller: controller,
                itemExtent: 36,
                physics: const FixedExtentScrollPhysics(),
                perspective: 0.003,
                overAndUnderCenterOpacity: 0.5,
                magnification: 1.1,
                useMagnifier: true,
                onSelectedItemChanged: onSelectedItemChanged,
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, index) {
                    if (index < 0 || index >= itemCount) return null;

                    final itemText = itemBuilder(index);
                    final isPlaceholder = itemText.startsWith("no events");

                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          itemText,
                          maxLines: isPlaceholder ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isPlaceholder ? textDimColor.withOpacity(0.4) : textColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            height: isPlaceholder ? 1.3 : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  void _handleGo() {
    if (events.isEmpty) return;

    final selectedEventIndex = eventScroll.selectedItem;
    final selectedActionIndex = actionScroll.selectedItem;

    final selectedEvent = events[selectedEventIndex];
    final selectedAction = actions[selectedActionIndex];

    switch (selectedAction) {
      case "Details":
        selectedScreenNotifier.value = ScreenType.events;
        showCardOnLaunch = MapEntry(true, MapEntry(selectedEvent, 'ALL'));
        break;
      case "AI Chat":
        selectedScreenNotifier.value = ScreenType.chat;
        chatController.setEvent(selectedEvent);
        break;
      case "Members":
        selectedScreenNotifier.value = ScreenType.users;
        showEventChatOnLaunch = MapEntry(true, selectedEvent);
        break;
    }
  }
}
