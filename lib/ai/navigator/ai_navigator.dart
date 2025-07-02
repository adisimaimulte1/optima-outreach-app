import 'package:flutter/material.dart';
import 'package:optima/ai/navigator/scroll_registry.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/util/dashboard.dart';
import 'package:optima/screens/inApp/widgets/menu/menu_controller.dart' as custom_menu;
import 'package:optima/services/storage/local_storage_service.dart';

abstract class Triggerable {
  void triggerFromAI();
}

class AiNavigator {
  static Future<void> navigateToScreen(BuildContext context, String intentId) async {
    isTouchActive.value = false;

    final target = screenFromIntent(intentId);
    if (selectedScreenNotifier.value == target || target == null) {
      if (selectedScreenNotifier.value == target && screenScaleNotifier.value > 0.99) {
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

      isTouchActive.value = true;
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
      isTouchActive.value = true;
      return;
    }

    // simulate the icon tap for the correct target screen
    if (menuGlobalKey.currentState != null) {
      menuGlobalKey.currentState!.simulateTap(target);
    } else {
      debugPrint("❌ Menu key not attached. Cannot simulate navigation.");
      isTouchActive.value = true;
      return;
    }

    await Future.delayed(const Duration(milliseconds: 1000)); // let the beam animation play


    if (screenScaleNotifier.value == 0.4) {
      screenScaleNotifier.value = 1.0;
      await Future.delayed(const Duration(milliseconds: 500));
      menuGlobalKey.currentState!.clearBeams();
      pinchAnimationTime = 300;
    }

    isTouchActive.value = true;
    debugPrint("🧠 Jamie navigated to $target");
  }

  static Future<void> navigateToWidget({
    required BuildContext context,
    required String intentId,

    bool shouldScroll = false,
    bool shouldScrollToPage = false,
    ScrollData scrollData = const ScrollData(offset: 0.0),
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
    isTouchActive.value = false;
    await Future.delayed(const Duration(milliseconds: 300));



    if (shouldScroll) {
      await scrollTo(scrollData: scrollData);
      await Future.delayed(const Duration(milliseconds: 200));
    } else if (shouldScrollToPage) {
      await scrollToPage(scrollData: scrollData);
      await Future.delayed(const Duration(milliseconds: 200));
    }



    final state = targetKey.currentState;
    if (state != null && state is Triggerable) {
      debugPrint("✅ Found Triggerable widget for $intentId");
      (state as Triggerable).triggerFromAI();
      isTouchActive.value = true;
      return;
    }

    isTouchActive.value = true;
  }

  static Future<void> scrollTo({required ScrollData scrollData}) async {
    final screen = selectedScreenNotifier.value;
    final controller = ScrollRegistry.get(screen);

    if (controller == null || scrollData.offset == null) { return; }

    try {
      await controller.animateTo(
        scrollData.offset!,
        duration: scrollData.duration,
        curve: scrollData.curve,
      );
    } catch (e) {}
  }

  static Future<void> scrollToPage({required ScrollData scrollData}) async {
    final screen = selectedScreenNotifier.value;
    final controller = PageRegistry.get(screen);

    if (controller == null || scrollData.index == null) { return; }

    try {
      await controller.animateToPage(
          scrollData.index!,
          duration: scrollData.duration,
          curve: scrollData.curve);
    } catch (e) {}
  }




  static Future<void> showTutorial(BuildContext context, int tutorialNumber) async {
    switch (tutorialNumber) {
      case 1:
        await tutorial1(context);
        break;
      default:
        break;
    }
  }

  static Future<void> tutorial1(BuildContext context) async {
    custom_menu.MenuController.instance.selectSource(DashboardScreen);
    isTouchActive.value = false;

    // Step 1: Show Dashboard and wait 5 seconds
    await Future.delayed(const Duration(seconds: 16));

    // Step 2: Enter menu and stay 4 seconds
    await navigateToScreen(context, "navigate/menu");
    isTouchActive.value = false;

    await Future.delayed(const Duration(seconds: 10));

    // Step 3: Go to Settings
    await navigateToScreen(context, "navigate/settings");
    isTouchActive.value = false;


    // Modify some settings because why not
    await Future.delayed(const Duration(seconds: 3));
    jamieRemindersNotifier.value = !jamieReminders;
    jamieReminders = !jamieReminders;

    await Future.delayed(const Duration(milliseconds: 600));
    wakeWordEnabledNotifier.value = !wakeWordEnabled;
    wakeWordEnabled = !wakeWordEnabled;

    await Future.delayed(const Duration(milliseconds: 200));
    LocalStorageService().setThemeMode(ThemeMode.light);

    await Future.delayed(const Duration(milliseconds: 700));
    jamieRemindersNotifier.value = !jamieReminders;
    jamieReminders = !jamieReminders;

    await Future.delayed(const Duration(milliseconds: 600));
    LocalStorageService().setThemeMode(ThemeMode.dark);

    await Future.delayed(const Duration(milliseconds: 300));
    wakeWordEnabledNotifier.value = !wakeWordEnabled;
    wakeWordEnabled = !wakeWordEnabled;

    await Future.delayed(const Duration(milliseconds: 400));
    LocalStorageService().setThemeMode(ThemeMode.system);

    await Future.delayed(const Duration(seconds: 1));

    // Step 4: Navigate to Events
    isTouchActive.value = false;
    await navigateToScreen(context, "navigate/events");
    isTouchActive.value = false;
    await Future.delayed(const Duration(milliseconds: 7400));

    // Step 5: Open Add Event form
    await navigateToWidget(context: context, intentId: "tap_widget/events/add_event");
    isTouchActive.value = false;

    // Wait a bit to simulate form usage
    await Future.delayed(const Duration(milliseconds: 4400));

    // Step 6: Return to Dashboard
    await navigateToWidget(context: context, intentId: "tap_widget/dashboard/show_notifications");
    isTouchActive.value = false;
    await Future.delayed(const Duration(milliseconds: 5600));

    await navigateToScreen(context, "navigate/dashboard");

    isTouchActive.value = true;
    debugPrint("🎬 Jamie walkthrough complete");
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
    if (intentId.endsWith("/show_upcoming_event")) return showUpcomingEventCardKey;

    if (intentId.endsWith("/contact/phone")) return phoneTriggerKey;
    if (intentId.endsWith("/contact/email")) return emailTriggerKey;
    if (intentId.endsWith("/contact/website")) return websiteTriggerKey;

    if (intentId.startsWith("tap_widget/contact/tutorial_")) {
      final index = int.tryParse(intentId.split("_").last);
      if (index != null && index >= 1 && index <= tutorialCardKeys.length) {
        return tutorialCardKeys[index - 1];
      }
    }


    return null;
  }

}
