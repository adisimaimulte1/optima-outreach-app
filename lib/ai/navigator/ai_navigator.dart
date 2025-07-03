import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:optima/ai/navigator/key_registry.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/util/contact.dart';
import 'package:optima/screens/inApp/util/dashboard.dart';
import 'package:optima/screens/inApp/util/events.dart';
import 'package:optima/screens/inApp/util/settings.dart';
import 'package:optima/screens/inApp/util/users.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:optima/screens/inApp/widgets/menu/menu_controller.dart' as custom_menu;
import 'package:optima/screens/inApp/widgets/tutorial/touch_blocker.dart';
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
        await exitPopUps(context);

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

    await exitPopUps(context);
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

  static Future<void> exitPopUps(BuildContext context) async {
    while (popupStackCount.value > 0) {
      Navigator.of(context).pop();
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }




  static Future<void> showTutorial(BuildContext context, int tutorialNumber) async {
    switch (tutorialNumber) {
      case 1:
        await tutorial1(context);
      case 2:
        await tutorial2(context);
      case 3:
        await tutorial3(context);
      case 4:
        await tutorial4(context);
      case 5:
        await tutorial5(context);

      default:
        await tutorial1(context);
    }
  }

  static Future<void> tutorial1(BuildContext context) async {
    custom_menu.MenuController.instance.selectSource(DashboardScreen);
    isTouchActive.value = false;

    // Step 1: Show Dashboard and wait
    await cancellableDelay(const Duration(seconds: 16));

    // Step 2: Enter menu and stay seconds
    await navigateToScreen(context, "navigate/menu");
    isTouchActive.value = false;

    await cancellableDelay(const Duration(seconds: 10));

    // Step 3: Go to Settings
    await navigateToScreen(context, "navigate/settings");
    isTouchActive.value = false;


    // Modify some settings because why not
    await cancellableDelay(const Duration(seconds: 3));
    jamieRemindersNotifier.value = !jamieReminders;
    jamieReminders = !jamieReminders;

    await cancellableDelay(const Duration(milliseconds: 600));
    wakeWordEnabledNotifier.value = !wakeWordEnabled;
    wakeWordEnabled = !wakeWordEnabled;

    await cancellableDelay(const Duration(milliseconds: 200));
    LocalStorageService().setThemeMode(selectedThemeNotifier.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);

    await cancellableDelay(const Duration(milliseconds: 700));
    jamieRemindersNotifier.value = !jamieReminders;
    jamieReminders = !jamieReminders;

    await cancellableDelay(const Duration(milliseconds: 900));
    wakeWordEnabledNotifier.value = !wakeWordEnabled;
    wakeWordEnabled = !wakeWordEnabled;

    await cancellableDelay(const Duration(milliseconds: 400));
    LocalStorageService().setThemeMode(selectedThemeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

    await cancellableDelay(const Duration(seconds: 1));

    // Step 4: Navigate to Events
    isTouchActive.value = false;
    await navigateToScreen(context, "navigate/events");
    isTouchActive.value = false;
    await cancellableDelay(const Duration(milliseconds: 7400));

    // Step 5: Open Add Event form
    await navigateToWidget(context: context, intentId: "tap_widget/events/add_event");
    isTouchActive.value = false;

    // Wait a bit to simulate form usage
    await cancellableDelay(const Duration(milliseconds: 4400));

    // Step 6: Return to Dashboard
    await navigateToWidget(context: context, intentId: "tap_widget/dashboard/show_notifications");
    isTouchActive.value = false;
    await cancellableDelay(const Duration(milliseconds: 5600));

    await navigateToScreen(context, "navigate/dashboard");
    isTouchActive.value = false;
    await cancellableDelay(const Duration(milliseconds: 7500));

    isTouchActive.value = true;
    debugPrint("🎬 Jamie tutorial 1 complete");
  }

  static Future<void> tutorial2(BuildContext context) async {
    custom_menu.MenuController.instance.selectSource(EventsScreen);
    isTouchActive.value = false;

    tutorialEventData = EventData(
      eventName: 'Tutorial Event',
      organizationType: 'Custom',
      customOrg: 'Optima Team',
      selectedDate: DateTime.now().add(const Duration(days: 3)),
      selectedTime: const TimeOfDay(hour: 14, minute: 30),
      locationAddress: 'Palatul Copiilor, Bucharest',
      locationLatLng: const LatLng(44.4268, 26.1025),
      eventMembers: [
        {'email': 'adrian.contras@sincaibm.ro', 'status': 'pending', 'invitedAt': DateTime.now().toIso8601String()},
      ],
      eventGoals: ['Recruit 10 members', 'Promote STEM'],
      audienceTags: ['Students', 'Custom:Robotics fans'],
      isPublic: true,
      isPaid: false,
      jamieEnabled: true,
      eventManagers: [email],
      status: 'UPCOMING',
      createdBy: email,
      eventPrice: null,
      eventCurrency: 'RON',
    );
    preloadTutorialEvent = true;

    // step 1
    await cancellableDelay(const Duration(seconds: 11));
    await navigateToWidget(context: context, intentId: "tap_widget/events/add_event");
    isTouchActive.value = false;

    // step 2
    await cancellableDelay(const Duration(seconds: 10));
    addEventKey.currentState?.scrollToStep(1);

    // step 3
    await cancellableDelay(const Duration(seconds: 4));
    addEventKey.currentState?.scrollToStep(2);

    // step 4
    await cancellableDelay(const Duration(seconds: 5));
    addEventKey.currentState?.scrollToStep(3);

    // step 5
    await cancellableDelay(const Duration(seconds: 10));
    addEventKey.currentState?.scrollToStep(4);

    // step 6
    await cancellableDelay(const Duration(seconds: 11));
    addEventKey.currentState?.scrollToStep(5);

    // step 7
    await cancellableDelay(const Duration(seconds: 15));
    addEventKey.currentState?.scrollToStep(6);

    await cancellableDelay(const Duration(seconds: 15));
    await exitPopUps(context);

    await cancellableDelay(const Duration(milliseconds: 4500));

    isTouchActive.value = true;
    debugPrint("🎬 Jamie tutorial 2 complete");
  }

  static Future<void> tutorial3(BuildContext context) async {
    custom_menu.MenuController.instance.selectSource(UsersScreen);
    isTouchActive.value = false;

    await cancellableDelay(const Duration(seconds: 3));

    isTouchActive.value = true;
  }

  static Future<void> tutorial4(BuildContext context) async {
    custom_menu.MenuController.instance.selectSource(ContactScreen);
    isTouchActive.value = false;

    await cancellableDelay(const Duration(seconds: 3));

    isTouchActive.value = true;
  }

  static Future<void> tutorial5(BuildContext context) async {
    custom_menu.MenuController.instance.selectSource(SettingsScreen);
    isTouchActive.value = false;

    // account
    await cancellableDelay(const Duration(seconds: 29));

    // appearance
    await scrollTo(scrollData: const ScrollData(offset: 60));
    ThemeMode themeMode = selectedThemeNotifier.value;
    LocalStorageService().setThemeMode(themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
    await cancellableDelay(const Duration(seconds: 4));
    LocalStorageService().setThemeMode(themeMode == ThemeMode.light ? ThemeMode.light : ThemeMode.dark);
    await cancellableDelay(const Duration(seconds: 4));
    debugPrint(ScrollRegistry.get(ScreenType.settings)?.toString());


    // jamie assistant
    await scrollTo(scrollData: const ScrollData(offset: 200));
    wakeWordEnabledNotifier.value = !wakeWordEnabled;
    wakeWordEnabled = !wakeWordEnabled;
    await cancellableDelay(const Duration(seconds: 7));
    jamieRemindersNotifier.value = !jamieReminders;
    jamieReminders = !jamieReminders;
    await cancellableDelay(const Duration(seconds: 7));
    wakeWordEnabledNotifier.value = !wakeWordEnabled;
    wakeWordEnabled = !wakeWordEnabled;
    jamieRemindersNotifier.value = !jamieReminders;
    jamieReminders = !jamieReminders;


    // notifications
    await scrollTo(scrollData: const ScrollData(offset: 400));
    bool notificationsOn = notificationsPermissionNotifier.value;
    notificationsPermissionNotifier.value = !notificationsOn;
    LocalStorageService().setNotificationsEnabled(!notificationsOn);
    await cancellableDelay(const Duration(seconds: 9));
    notificationsPermissionNotifier.value = notificationsOn;
    LocalStorageService().setNotificationsEnabled(notificationsOn);

    // privacy & security
    await scrollTo(scrollData: const ScrollData(offset: 540));
    LocalStorageService().setLocationAccess(!locationAccess);
    await cancellableDelay(const Duration(seconds: 5));
    navigateToWidget(context: context, intentId: "tap_widget/settings/show_sessions")
        .whenComplete(() async { isTouchActive.value = false; });
    await cancellableDelay(const Duration(seconds: 2));
    LocalStorageService().setLocationAccess(!locationAccess);
    exitPopUps(context);

    // credits & billing
    await scrollTo(scrollData: const ScrollData(offset: 690));
    navigateToWidget(context: context, intentId: "tap_widget/settings/show_credits")
        .whenComplete(() async { isTouchActive.value = false; });
    await cancellableDelay(const Duration(seconds: 7));
    exitPopUps(context);
    await cancellableDelay(const Duration(seconds: 18));
    ScreenRegistry
        .get<SettingsScreenState>(ScreenType.settings)
        ?.currentState
        ?.simulateVersionTap();
    await cancellableDelay(const Duration(seconds: 2));
    ScreenRegistry
        .get<SettingsScreenState>(ScreenType.settings)
        ?.currentState
        ?.reverseVersionTap();
    await cancellableDelay(const Duration(seconds: 6));
    await scrollTo(scrollData: const ScrollData(offset: 0));
    await cancellableDelay(const Duration(milliseconds: 8500));

    isTouchActive.value = true;
    debugPrint("🎬 Jamie tutorial 5 complete");
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



  static Future<void> cancellableDelay(Duration duration) async {
    const interval = Duration(milliseconds: 100);
    int elapsed = 0;

    while (elapsed < duration.inMilliseconds) {
      if (tutorialCancelled.value) {
        tutorialCancelled.value = false;
        aiVoice.pauseImmediately();
        throw TutorialCancelledException();
      }

      await Future.delayed(interval);
      elapsed += interval.inMilliseconds;
    }
  }
}
