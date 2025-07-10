import 'package:flutter/material.dart';
import 'package:optima/ai/navigator/ai_navigator.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:optima/screens/inApp/widgets/users/dialogs/members_chat_dialog.dart';
import 'package:optima/screens/inApp/widgets/users/members_chat/event_chat_preview_card.dart';

class EventsChatTab extends StatefulWidget {
  const EventsChatTab({super.key});

  @override
  State<EventsChatTab> createState() => EventsChatTabState();
}

class EventsChatTabState extends State<EventsChatTab>  implements Triggerable {
  bool _hasUnfocused = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (showEventChatOnLaunch.key && showEventChatOnLaunch.value != null) {
        final event = showEventChatOnLaunch.value!;
        showEventChatOnLaunch = const MapEntry(false, null);

        showDialog(
          context: context,
          barrierColor: Colors.black.withOpacity(0.6),
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: MembersChatDialog(event: event),
            ),
          ),
        ).whenComplete(() => popupStackCount.value--);

        popupStackCount.value++;
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Center(
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
          controller: usersController.eventsChatScrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          physics: scale < 0.99
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return EventChatPreviewCard(
              event: event,
              onTap: () {
                popupStackCount.value++;
                showDialog(
                  context: context,
                  barrierColor: Colors.black.withOpacity(0.6),
                  builder: (_) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: MembersChatDialog(event: event),
                    ),
                  ),
                ).whenComplete(() => popupStackCount.value--);
              },

            );
          },
        );
      },
    );
  }

  @override
  Future<void> triggerFromAI() async {
    if (screenScaleNotifier.value < 0.99) {
      debugPrint("🔒 Screen not ready, ignoring AI trigger");
      return;
    }

    final currentIndex = usersController.tabController.index;

    if (currentIndex != 0) {
      usersController.tabController.animateTo(0);
      await Future.delayed(const Duration(milliseconds: 600));
    }
  }


  void openEventChat(EventData event) {
    popupStackCount.value++;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: MembersChatDialog(event: event),
        ),
      ),
    ).whenComplete(() => popupStackCount.value--);
  }


}
