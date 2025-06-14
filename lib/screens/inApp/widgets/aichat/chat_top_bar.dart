import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/aichat/buttons/menu_button.dart';
import 'package:optima/screens/inApp/widgets/aichat/buttons/search_button.dart';
import 'package:optima/screens/inApp/widgets/aichat/chat_controller.dart';
import 'package:provider/provider.dart';

class ChatTopBar extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const ChatTopBar({super.key, required this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, left: 20, right: 20, bottom: 12),
      child: Consumer<ChatController>(
        builder: (context, chat, _) {
          final event = chat.currentEvent;
          final name = event?.eventName ?? 'No Event Selected';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MenuButton(onPressed: () => scaffoldKey.currentState?.openDrawer()),
                  const Spacer(),
                  if (event != null) ...[
                    RoundIconButton(
                      icon: Icons.push_pin_outlined,
                      iconSize: 35,
                      onTap: () {},
                    ),
                    const SizedBox(width: 12),
                    RoundIconButton(
                      icon: Icons.search,
                      iconSize: 40,
                      onTap: () {},
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              Divider(color: textDimColor, thickness: 1),
            ],
          );
        },
      ),
    );
  }
}
