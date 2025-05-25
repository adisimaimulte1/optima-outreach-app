import 'package:flutter/cupertino.dart';
import 'package:optima/globals.dart';


abstract class Triggerable {
  void triggerFromAI();
}

class AiNavigator {
  static Future<void> navigateToScreen(BuildContext context, String intentId) async {
    final target = screenFromIntent(intentId);
    if (selectedScreenNotifier.value == target || target == null) {
      if (selectedScreenNotifier.value == target && screenScaleNotifier.value < 0.99) {
        while (popupStackCount.value > 0) {
          Navigator.of(context).pop();
          await Future.delayed(const Duration(milliseconds: 200));
        }

        if (screenScaleNotifier.value == 0.4) {
            pinchAnimationTime = 600;
            screenScaleNotifier.value = 1.0;
            await Future.delayed(const Duration(milliseconds: 500));
            menuGlobalKey.currentState!.clearBeams();
            pinchAnimationTime = 300;
          }
        }

      return;
    }

    while (popupStackCount.value > 0) {
      Navigator.of(context).pop();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    await Future.delayed(const Duration(milliseconds: 400));

    if (screenScaleNotifier.value >= 0.99) {
      pinchAnimationTime = 600;
      screenScaleNotifier.value = 0.4;
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    // exit early to go to the menu
    if (target == ScreenType.menu) {
      pinchAnimationTime = 300;
      return;
    }

    // Simulate the icon tap for the correct target screen
    if (menuGlobalKey.currentState != null) {
      menuGlobalKey.currentState!.simulateTap(target);
    } else {
      debugPrint("❌ Menu key not attached. Cannot simulate navigation.");
      return;
    }

    await Future.delayed(const Duration(milliseconds: 1000)); // Let the beam animation play


    if (screenScaleNotifier.value == 0.4) {
      screenScaleNotifier.value = 1.0;
      await Future.delayed(const Duration(milliseconds: 500));
      menuGlobalKey.currentState!.clearBeams();
      pinchAnimationTime = 300;
    }

    debugPrint("🧠 Jamie navigated to $target");
  }

  static Future<void> navigateToWidget({
    required BuildContext context,
    required String intentId,
    bool shouldScroll = false,
    ScrollController? scrollController,
    Duration scrollDelay = const Duration(milliseconds: 400),
    double scrollOffset = 0,
  }) async
  {
    final screen = screenFromIntent(intentId);
    if (screen == null) {
      debugPrint("❌ No ScreenType mapped for $intentId");
      return;
    }

    final targetKey = keyFromIntent(intentId);
    if (targetKey == null) {
      debugPrint("❌ No widget key mapped for $intentId");
      return;
    }

    await navigateToScreen(context, intentId);
    await Future.delayed(const Duration(milliseconds: 300));

    if (shouldScroll && scrollController != null) {
      scrollController.animateTo(
        scrollOffset,
        duration: scrollDelay,
        curve: Curves.easeInOut,
      );
      await Future.delayed(scrollDelay + const Duration(milliseconds: 200));
    }

    final state = targetKey.currentState;
    if (state != null && state is Triggerable) {
      debugPrint("✅ Found Triggerable widget for $intentId");
      (state as Triggerable).triggerFromAI();
      return;
    }
  }




  static ScreenType? screenFromIntent(String intentId) {
    if (intentId.contains("events")) return ScreenType.events;
    if (intentId.contains("settings")) return ScreenType.settings;
    if (intentId.contains("dashboard")) return ScreenType.dashboard;
    if (intentId.contains("chat")) return ScreenType.chat;
    if (intentId.contains("users")) return ScreenType.users;
    if (intentId.contains("contact")) return ScreenType.contact;
    if (intentId.contains("menu")) return ScreenType.menu;
    return null;
  }

  static GlobalKey? keyFromIntent(String intentId) {
    if (intentId.endsWith("/add_event")) return createEventButtonKey;
    if (intentId.endsWith("/show_credits")) return showCreditsTileKey;
    if (intentId.endsWith("/show_sessions")) return showSessionsTileKey;
    if (intentId.endsWith("/show_notifications")) return showNotificationsKey;
    return null;
  }

}
