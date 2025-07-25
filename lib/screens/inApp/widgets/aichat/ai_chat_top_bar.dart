import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/aichat/buttons/menu_button.dart';
import 'package:optima/screens/inApp/widgets/aichat/buttons/round_icon_button.dart';
import 'package:optima/screens/inApp/widgets/aichat/ai_chat_controller.dart';
import 'package:provider/provider.dart';

class AiChatTopBar extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const AiChatTopBar({super.key, required this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    return Consumer<AiChatController>(
      builder: (context, chat, _) {
        final event = chat.currentEvent;
        final isSearchActive = chat.isSearchBarVisible.value;

        return Padding(
          padding: const EdgeInsets.only(top: 24, left: 20, right: 20, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MenuButton(
                    onPressed: () {
                      if (chat.isSearchBarVisible.value) {
                        chat.toggleSearchBar(false);
                      }
                      scaffoldKey.currentState?.openDrawer();
                    },
                  ),

                  const Spacer(),
                  if (event != null) ...[
                    ValueListenableBuilder<bool>(
                      valueListenable: chat.showPinnedOnly,
                      builder: (context, isPinned, _) {
                        return RoundIconButton(
                          icon: Icons.push_pin_outlined,
                          iconSize: 35,
                          isActive: isPinned,
                          enableActiveStyle: true,
                          onTap: () {
                            chat.showPinnedOnly.value = !isPinned;
                            chat.isSearchBarVisible.value = false;
                            chat.toggleSearchBar(false);
                            chat.resetScrollController();
                            chat.closeMessageOptions();
                            },
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    RoundIconButton(
                      icon: Icons.search,
                      iconSize: 40,
                      isActive: isSearchActive,
                      enableActiveStyle: true,
                      onTap: () {
                        final controller = chat.searchTextController;
                        controller.text = chat.searchQuery.value;
                        controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: controller.text.length),
                        );
                        chat.toggleSearchBar(true);
                        chat.updateSearchQuery(controller.text);
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              if (event != null)
                Text(
                  event.eventName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              const SizedBox(height: 4),
              Divider(color: textDimColor, thickness: 1),
            ],
          ),
        );
      },
    );
  }
}
