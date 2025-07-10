import 'package:flutter/material.dart';
import 'package:optima/ai/navigator/key_registry.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/util/contact.dart';
import 'package:optima/screens/inApp/util/dashboard.dart';
import 'package:optima/screens/inApp/util/events.dart';
import 'package:optima/screens/inApp/util/settings.dart';
import 'package:optima/screens/inApp/util/users.dart';
import 'package:optima/screens/inApp/widgets/dashboard/chart.dart';
import 'package:optima/screens/inApp/widgets/menu/menu_controller.dart' as custom_menu;
import 'package:optima/screens/inApp/widgets/tutorial/touch_blocker.dart';
import 'package:optima/services/storage/local_storage_service.dart';

abstract class Triggerable {
  Future<void> triggerFromAI();
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

      isTouchActive.value = !isTutorialActive.value;
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
      isTouchActive.value = !isTutorialActive.value;
      return;
    }

    // simulate the icon tap for the correct target screen
    if (menuGlobalKey.currentState != null) {
      menuGlobalKey.currentState!.simulateTap(target);
    } else {
      debugPrint("❌ Menu key not attached. Cannot simulate navigation.");
      isTouchActive.value = !isTutorialActive.value;
      return;
    }

    await Future.delayed(const Duration(milliseconds: 1000)); // let the beam animation play


    if (screenScaleNotifier.value == 0.4) {
      screenScaleNotifier.value = 1.0;
      await Future.delayed(const Duration(milliseconds: 500));
      menuGlobalKey.currentState!.clearBeams();
      pinchAnimationTime = 300;
    }

    isTouchActive.value = !isTutorialActive.value;
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
    debugPrint("screen: $screen");
    debugPrint("intentId: $intentId");
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
    if (!isTutorialActive.value) {
      isTouchActive.value = false;
    }
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
      await (state as Triggerable).triggerFromAI();
      isTouchActive.value = !isTutorialActive.value;
      return;
    }

    isTouchActive.value = !isTutorialActive.value;
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
    isTutorialActive.value = true;

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

    isTutorialActive.value = false;
  }

  static Future<void> tutorial1(BuildContext context) async {
    custom_menu.MenuController.instance.selectSource(DashboardScreen);
    isTouchActive.value = false;



    // show Dashboard
    await cancellableDelay(const Duration(milliseconds: 19000));
    chartCardKey.currentState?.currentMode = ChartMode.eventImpact;
    rebuildUI();

    await cancellableDelay(const Duration(milliseconds: 1800));
    eventActionSelectorKey.currentState?.scrollToActionIndex(3, const Duration(milliseconds: 600));
    await cancellableDelay(const Duration(milliseconds: 600));
    eventActionSelectorKey.currentState?.scrollToActionIndex(0, const Duration(milliseconds: 600));

    await cancellableDelay(const Duration(milliseconds: 6000));
    chartCardKey.currentState?.currentMode = ChartMode.creditUsage;
    rebuildUI();

    await cancellableDelay(const Duration(milliseconds: 1200));
    await navigateToWidget(context: context, intentId: "tap_widget/dashboard/show_notifications");
    await cancellableDelay(const Duration(milliseconds: 1000));
    exitPopUps(context);



    // show the Menu
    await cancellableDelay(const Duration(milliseconds: 500));
    await navigateToScreen(context, "navigate/menu");
    await cancellableDelay(const Duration(seconds: 6));



    // show Events
    await navigateToScreen(context, "navigate/events");
    preloadTutorialEvent = true;
    await cancellableDelay(const Duration(milliseconds: 3400));

    await navigateToWidget(context: context, intentId: "tap_widget/events/add_event");

    // step 2
    await cancellableDelay(const Duration(milliseconds: 700));
    addEventKey.currentState?.scrollToStep(1);

    // step 3
    await cancellableDelay(const Duration(milliseconds: 700));
    addEventKey.currentState?.scrollToStep(2);

    // step 4
    await cancellableDelay(const Duration(milliseconds: 700));
    addEventKey.currentState?.scrollToStep(3);

    // step 5
    await cancellableDelay(const Duration(milliseconds: 1900));
    addEventKey.currentState?.scrollToStep(4);

    // step 6
    await cancellableDelay(const Duration(seconds: 1));
    addEventKey.currentState?.scrollToStep(5);

    // step 7
    await cancellableDelay(const Duration(seconds: 1));
    addEventKey.currentState?.scrollToStep(6);

    await cancellableDelay(const Duration(seconds: 1));
    await exitPopUps(context);
    addTutorialEvent();
    await cancellableDelay(const Duration(milliseconds: 1300));



    // show Users
    await navigateToScreen(context, "navigate/users");
    await cancellableDelay(const Duration(milliseconds: 1200));
    eventsChatTabKey.currentState?.openEventChat(tutorialEventData);

    await cancellableDelay(const Duration(milliseconds: 5000));
    await exitPopUps(context);
    await navigateToWidget(context: context, intentId: "tap_widget/users/public");

    await cancellableDelay(const Duration(milliseconds: 2500));
    publicEventsTabKey.currentState?.selectedTag = "Charity";
    rebuildUI();
    await cancellableDelay(const Duration(milliseconds: 1000));
    publicEventsTabKey.currentState?.selectedTag = "Tech";
    rebuildUI();
    await cancellableDelay(const Duration(milliseconds: 1000));
    publicEventsTabKey.currentState?.selectedTag = "All";
    rebuildUI();
    await cancellableDelay(const Duration(milliseconds: 1500));



    // show Settings
    await navigateToScreen(context, "navigate/settings");
    await cancellableDelay(const Duration(milliseconds: 2000));

    await cancellableDelay(const Duration(seconds: 3));
    await scrollTo(scrollData: const ScrollData(offset: 190));
    await cancellableDelay(const Duration(milliseconds: 5000));

    wakeWordEnabledNotifier.value = !wakeWordEnabled;
    wakeWordEnabled = !wakeWordEnabled;
    await cancellableDelay(const Duration(milliseconds: 1700));
    ThemeMode themeMode = selectedThemeNotifier.value;
    LocalStorageService().setThemeMode(themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

    await navigateToWidget(
        context: context,
        intentId: "tap_widget/settings/show_sessions",
        shouldScroll: true,
        shouldScrollToPage: false,
        scrollData: const ScrollData(offset: 540));

    await cancellableDelay(const Duration(milliseconds: 600));

    await navigateToWidget(
        context: context,
        intentId: "tap_widget/settings/show_credits",
        shouldScroll: true,
        shouldScrollToPage: false,
        scrollData: const ScrollData(offset: 690));

    await cancellableDelay(const Duration(milliseconds: 1000));
    await exitPopUps(context);
    await cancellableDelay(const Duration(seconds: 2));
    await scrollTo(scrollData: const ScrollData(offset: 0));

    LocalStorageService().setThemeMode(themeMode);
    wakeWordEnabledNotifier.value = !wakeWordEnabled;
    wakeWordEnabled = !wakeWordEnabled;

    await cancellableDelay(const Duration(milliseconds: 1500));


    // show AI Chat
    await navigateToScreen(context, "navigate/aichat");
    await cancellableDelay(const Duration(seconds: 12));

    final controller = chatController.searchTextController;
    controller.text = 'social media';
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
    chatController.toggleSearchBar(true);
    chatController.updateSearchQuery(controller.text);

    await cancellableDelay(const Duration(milliseconds: 1500));

    chatController.showPinnedOnly.value = true;
    chatController.isSearchBarVisible.value = false;
    chatController.toggleSearchBar(false);
    chatController.resetScrollController();

    await cancellableDelay(const Duration(milliseconds: 5500));



    // show Contact
    await navigateToScreen(context, "navigate/contact");
    await cancellableDelay(const Duration(milliseconds: 2000));
    await scrollToPage(scrollData: const ScrollData(index: 4));
    await cancellableDelay(const Duration(milliseconds: 1500));
    await scrollToPage(scrollData: const ScrollData(index: 0));
    await cancellableDelay(const Duration(milliseconds: 500));
    await scrollToPage(scrollData: const ScrollData(index: 2));



    // show Dashboard
    await navigateToScreen(context, "navigate/dashboard");
    await cancellableDelay(const Duration(milliseconds: 5300));



    removeTutorialEvent();
    isTouchActive.value = true;
    debugPrint("🎬 Jamie tutorial 1 complete");
  }

  static Future<void> tutorial2(BuildContext context) async {
    custom_menu.MenuController.instance.selectSource(EventsScreen);
    isTouchActive.value = false;
    preloadTutorialEvent = true;

    // step 1
    await cancellableDelay(const Duration(seconds: 11));
    await navigateToWidget(context: context, intentId: "tap_widget/events/add_event");

    // step 2
    await cancellableDelay(const Duration(seconds: 10));
    addEventKey.currentState?.scrollToStep(1);

    // step 3
    await cancellableDelay(const Duration(seconds: 4));
    addEventKey.currentState?.scrollToStep(2);

    // step 4
    await cancellableDelay(const Duration(seconds: 6));
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

    await cancellableDelay(const Duration(seconds: 16));
    await exitPopUps(context);

    await cancellableDelay(const Duration(milliseconds: 4000));

    isTouchActive.value = true;
    debugPrint("🎬 Jamie tutorial 2 complete");
  }

  static Future<void> tutorial3(BuildContext context) async {
    custom_menu.MenuController.instance.selectSource(UsersScreen);
    isTouchActive.value = false;

    await cancellableDelay(const Duration(seconds: 11));
    addTutorialEvent();
    await cancellableDelay(const Duration(seconds: 4));
    await navigateToWidget(context: context, intentId: "tap_widget/users/public");

    await cancellableDelay(const Duration(seconds: 3));
    await navigateToWidget(context: context, intentId: "tap_widget/users/members");

    await cancellableDelay(const Duration(milliseconds: 150));

    eventsChatTabKey.currentState?.openEventChat(tutorialEventData);

    await cancellableDelay(const Duration(milliseconds: 12400));
    await navigateToScreen(context, "tap_widget/aichat");

    await cancellableDelay(const Duration(seconds: 24));

    chatController.showPinnedOnly.value = true;
    chatController.isSearchBarVisible.value = false;
    chatController.resetScrollController();

    await cancellableDelay(const Duration(seconds: 1));


    final controller = chatController.searchTextController;
    controller.text = 'social media';
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
    chatController.toggleSearchBar(true);
    chatController.updateSearchQuery(controller.text);


    await cancellableDelay(const Duration(seconds: 3));

    chatController.showPinnedOnly.value = false;
    chatController.isSearchBarVisible.value = false;
    chatController.resetScrollController();

    await cancellableDelay(const Duration(seconds: 4));
    await navigateToScreen(context, "navigate/contact");



    removeTutorialEvent();
    isTouchActive.value = true;
  }

  static Future<void> tutorial4(BuildContext context) async {
    custom_menu.MenuController.instance.selectSource(ContactScreen);
    isTouchActive.value = false;

    await cancellableDelay(const Duration(milliseconds: 10500));
    await navigateToScreen(context, "navigate/dashboard");

    await cancellableDelay(const Duration(milliseconds: 7100));
    await navigateToScreen(context, "navigate/settings");

    await cancellableDelay(const Duration(seconds: 4));
    await scrollTo(scrollData: const ScrollData(offset: 190));

    await cancellableDelay(const Duration(milliseconds: 2500));
    bool notificationsOn = notificationsPermissionNotifier.value;
    debugPrint("notificationsOn: $notificationsOn");

    notificationsPermissionNotifier.value = !notificationsOn;
    LocalStorageService().setNotificationsEnabled(!notificationsOn);

    await cancellableDelay(const Duration(milliseconds: 1900));
    ThemeMode themeMode = selectedThemeNotifier.value;
    LocalStorageService().setThemeMode(themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

    await cancellableDelay(const Duration(milliseconds: 2000));
    notificationsPermissionNotifier.value = notificationsOn;
    LocalStorageService().setNotificationsEnabled(notificationsOn);
    LocalStorageService().setThemeMode(themeMode);

    await cancellableDelay(const Duration(milliseconds: 4600));
    await scrollTo(scrollData: const ScrollData(offset: 500));
    await cancellableDelay(const Duration(milliseconds: 400));
    await scrollTo(scrollData: const ScrollData(offset: 0));

    await cancellableDelay(const Duration(milliseconds: 8200));
    await navigateToWidget(context: context, intentId: "tap_widget/events/add_event");

    await cancellableDelay(const Duration(milliseconds: 4500));
    await navigateToScreen(context, "navigate/dashboard");

    await cancellableDelay(const Duration(milliseconds: 5900));
    await navigateToWidget(context: context, intentId: "tap_widget/dashboard/show_notifications");

    await cancellableDelay(const Duration(milliseconds: 3400));
    exitPopUps(context);
    await cancellableDelay(const Duration(seconds: 4));
    await navigateToWidget(context: context, intentId: "tap_widget/users/public");
    await cancellableDelay(const Duration(seconds: 6));

    await navigateToWidget(
        context: context,
        intentId: "tap_widget/settings/show_credits",
        shouldScroll: true,
        shouldScrollToPage: false,
        scrollData: const ScrollData(offset: 690));

    await cancellableDelay(const Duration(milliseconds: 5500));
    await navigateToScreen(context, "navigate/contact");

    await cancellableDelay(const Duration(seconds: 9));
    await scrollToPage(scrollData: const ScrollData(index: 3));

    await cancellableDelay(const Duration(milliseconds: 15800));

    isTouchActive.value = true;
  }

  static Future<void> tutorial5(BuildContext context) async {
    custom_menu.MenuController.instance.selectSource(SettingsScreen);
    isTouchActive.value = false;

    // account
    await cancellableDelay(const Duration(seconds: 29));

    // appearance
    ThemeMode themeMode = selectedThemeNotifier.value;
    await scrollTo(scrollData: const ScrollData(offset: 60));

    await cancellableDelay(const Duration(milliseconds: 5000));
    LocalStorageService().setThemeMode(ThemeMode.light);
    await cancellableDelay(const Duration(milliseconds: 600));
    LocalStorageService().setThemeMode(ThemeMode.dark);
    await cancellableDelay(const Duration(milliseconds: 600));
    LocalStorageService().setThemeMode(ThemeMode.system);
    await cancellableDelay(const Duration(milliseconds: 2000));
    LocalStorageService().setThemeMode(themeMode == ThemeMode.light ? ThemeMode.light : ThemeMode.dark);
    debugPrint(ScrollRegistry.get(ScreenType.settings)?.toString());


    // jamie assistant
    await scrollTo(scrollData: const ScrollData(offset: 200));
    await cancellableDelay(const Duration(seconds: 7));
    wakeWordEnabledNotifier.value = !wakeWordEnabled;
    wakeWordEnabled = !wakeWordEnabled;
    await cancellableDelay(const Duration(milliseconds: 5500));
    jamieRemindersNotifier.value = !jamieReminders;
    jamieReminders = !jamieReminders;
    await cancellableDelay(const Duration(milliseconds: 1500));
    wakeWordEnabledNotifier.value = !wakeWordEnabled;
    wakeWordEnabled = !wakeWordEnabled;
    jamieRemindersNotifier.value = !jamieReminders;
    jamieReminders = !jamieReminders;


    // notifications
    await scrollTo(scrollData: const ScrollData(offset: 400));
    await cancellableDelay(const Duration(seconds: 3));
    bool notificationsOn = notificationsPermissionNotifier.value;
    notificationsPermissionNotifier.value = !notificationsOn;
    LocalStorageService().setNotificationsEnabled(!notificationsOn);
    await cancellableDelay(const Duration(seconds: 6));
    notificationsPermissionNotifier.value = notificationsOn;
    LocalStorageService().setNotificationsEnabled(notificationsOn);

    // privacy & security
    await scrollTo(scrollData: const ScrollData(offset: 540));
    await cancellableDelay(const Duration(milliseconds: 2500));
    LocalStorageService().setLocationAccess(!locationAccess);
    await cancellableDelay(const Duration(milliseconds: 2500));
    navigateToWidget(context: context, intentId: "tap_widget/settings/show_sessions");
    await cancellableDelay(const Duration(seconds: 2));
    LocalStorageService().setLocationAccess(!locationAccess);
    exitPopUps(context);

    // credits & billing
    await scrollTo(scrollData: const ScrollData(offset: 690));
    await cancellableDelay(const Duration(milliseconds: 600));
    navigateToWidget(context: context, intentId: "tap_widget/settings/show_credits");
    await cancellableDelay(const Duration(seconds: 2));
    exitPopUps(context);
    await cancellableDelay(const Duration(milliseconds: 4400));
    exitPopUps(context);

    // help & about
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
    await cancellableDelay(const Duration(milliseconds: 9300));

    isTouchActive.value = true;
    debugPrint("🎬 Jamie tutorial 5 complete");
  }



  static ScreenType? screenFromIntent(String intentId) {
    if (intentId.contains("/events")) return ScreenType.events;
    if (intentId.contains("/settings")) return ScreenType.settings;
    if (intentId.contains("/dashboard")) return ScreenType.dashboard;
    if (intentId.contains("/aichat")) return ScreenType.chat;
    if (intentId.contains("/users")) return ScreenType.users;
    if (intentId.contains("/contact")) return ScreenType.contact;
    if (intentId.contains("/menu")) return ScreenType.menu;
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

    if (intentId.endsWith("/users/public")) return publicEventsTabKey;
    if (intentId.endsWith("/users/members")) return eventsChatTabKey;

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
