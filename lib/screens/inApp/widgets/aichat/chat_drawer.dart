import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:optima/screens/inApp/widgets/aichat/chat_controller.dart';
import 'package:provider/provider.dart';

class ChatDrawer extends StatelessWidget {
  final Function(EventData) onSelect;

  const ChatDrawer({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(topRight: Radius.circular(24)),
        child: Column(
          children: [
            Container(
              height: 90,
              width: double.infinity,
              color: inAppBackgroundColor,
              child: SafeArea(
                bottom: false,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Text(
                      'Events',
                      style: TextStyle(
                        color: textHighlightedColor,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Divider(color: textDimColor, thickness: 4, height: 0),
            Expanded(
              child: Container(
                color: inAppForegroundColor,
                child: Consumer<ChatController>(
                  builder: (context, chat, _) {
                    return ListView.separated(
                        padding: const EdgeInsets.only(top: 0, bottom: 6),
                        itemCount: events.length,
                      separatorBuilder: (_, __) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(
                          color: textDimColor.withOpacity(0.3),
                          thickness: 0.8,
                          height: 6,
                        ),
                      ),
                        itemBuilder: (context, index) {
                          final e = events[index];
                          final selected = e == chat.currentEvent;
                          final selectedColor = chat.hasPermission ? textSecondaryHighlightedColor : textHighlightedColor;

                          return InkWell(
                            onTap: () async {
                              onSelect(e);
                              Navigator.of(context).pop();
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      e.eventName,
                                      style: TextStyle(
                                        color: selected ? selectedColor : textColor,
                                        fontSize: 16,
                                        fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      Future.delayed(const Duration(milliseconds: 100), () {
                                        selectedScreenNotifier.value = ScreenType.events;
                                        showCardOnLaunch = MapEntry(true, MapEntry(e, 'ALL'));
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.open_in_new,
                                        size: 22,
                                        color: selected ? selectedColor : textColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
