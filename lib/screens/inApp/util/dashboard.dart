import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:optima/ai/ai_recordings.dart';
import 'package:optima/ai/navigator/key_registry.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/tutorial/tutorial_screen.dart';
import 'package:optima/screens/inApp/widgets/dashboard/cards/credits_left.dart';

import 'package:optima/screens/inApp/widgets/dashboard/chart.dart';
import 'package:optima/screens/inApp/widgets/dashboard/buttons/new_event_button.dart';
import 'package:optima/screens/inApp/widgets/dashboard/buttons/reminder_bell_button.dart';
import 'package:optima/screens/inApp/widgets/dashboard/cards/upcoming_event.dart';
import 'package:optima/screens/inApp/widgets/dashboard/cards/reminder.dart';
import 'package:optima/screens/inApp/widgets/abstract_screen.dart';
import 'package:optima/screens/inApp/widgets/dashboard/event_action_selector.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:optima/services/livesync/event_live_sync.dart';
import 'package:optima/services/location/location_processor.dart';
import 'package:optima/services/notifications/notification_popup.dart';
import 'package:optima/services/storage/local_storage_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {

  @override
  void initState() {
    super.initState();
    _handleFirstLaunch();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScreenRegistry.register<DashboardScreenState>(ScreenType.dashboard, widget.key as GlobalKey<DashboardScreenState>);

      final nextEvent = events
          .where((e) =>
      e.selectedDate != null &&
          e.selectedDate!.isAfter(DateTime.now()) &&
          e.status == "UPCOMING")
          .toList()
        ..sort((a, b) => a.selectedDate!.compareTo(b.selectedDate!));

      if (nextEvent.isNotEmpty) {
        final notifier = EventLiveSyncService().getNotifier(nextEvent.first.id!);
        if (notifier != null) {
          notifier.value = notifier.value; // force rebuild manually
        }
      }
    });

  }

  @override
  void dispose() {
    ScreenRegistry.unregister(ScreenType.dashboard);
    super.dispose();
  }



  void _handleFirstLaunch() async {
    debugPrint("isFirstDashboardLaunch: $isFirstDashboardLaunch");

    if (isFirstDashboardLaunch) {
      await LocalStorageService().checkAndRequestPermissionsOnce();

      if (!(await LocalStorageService().hasSeenTutorial())) {
        isFirstDashboardLaunch = false;

        showGeneralDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withOpacity(0.9),
          transitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (context, _, __) => const TutorialOverlayScreen(),
        );

        await LocationProcessor.updateUserCountryCode();
        return;
      }

      if (notifications) {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .update({'fcmToken': token});
        }
      }

      final chance = Random().nextInt(5);
      if (jamieReminders && chance == 3) {
        assistantState.value = JamieState.thinking;
        await Future.delayed(Duration(milliseconds: 300 + Random().nextInt(30)));
        await AiRecordings.playRandomIntro();
      }

      await LocationProcessor.updateUserCountryCode();
      assistantState.value = JamieState.idle;
      isFirstDashboardLaunch = false;
    }
  }



  @override
  Widget build(BuildContext context) {
    return AbsScreen(
      sourceType: DashboardScreen,
      builder: (context, isMinimized, scale) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final content = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 60),
                _buildHeader(context),
                const SizedBox(height: 20),
                const LineChartCard(),
                const SizedBox(height: 30),
                _buildLine(context),
                const SizedBox(height: 30),
                _buildDashboardRow(context),
                const SizedBox(height: 10),
                const EventActionSelectorWheel(),
                const SizedBox(height: 10),
                CreditsLeftCard(),
                const SizedBox(height: 30),
                _buildLine(context),
              ],
            );

            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Center(
                child: SingleChildScrollView(
                  physics: contentHeight(content) < constraints.maxHeight
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(child: content),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLine(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: textDimColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Builder(
          builder: (context) {
            return responsiveText(
              context,
              "Dashboard",
              maxWidthFraction: 0.6,
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: 1.2,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDashboardRow(BuildContext context) {
    final double buttonSize = MediaQuery.of(context).size.width * 0.17;
    const double cardHeight = 150.0;
    const double spacing = 10.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 20),
        _buildUpcomingEventCard(cardHeight),
        const SizedBox(width: spacing),
        _buildButtonsAndReminderColumn(buttonSize, spacing, cardHeight),
        const SizedBox(width: 20),
      ],
    );
  }

  Widget _buildUpcomingEventCard(double height) {
    return Expanded(
      flex: 6,
      child: SizedBox(
        height: height,
        child: Builder(
          builder: (context) {
            final nextEvent = events
                .where((e) =>
            e.selectedDate != null &&
                e.selectedDate!.isAfter(DateTime.now()) &&
                e.status == "UPCOMING")
                .toList()
              ..sort((a, b) => a.selectedDate!.compareTo(b.selectedDate!));

            if (nextEvent.isEmpty) return UpcomingEventCard(key: showUpcomingEventCardKey); // fallback

            final eventId = nextEvent.first.id!;
            final notifier = EventLiveSyncService().getNotifier(eventId);

            if (notifier == null) return UpcomingEventCard(key: showUpcomingEventCardKey);

            return ValueListenableBuilder<EventData>(
              valueListenable: notifier,
              builder: (context, liveEvent, _) {
                return UpcomingEventCard(key: showUpcomingEventCardKey);
              },
            );
          },
        ),

      ),
    );
  }

  Widget _buildButtonsAndReminderColumn(
      double buttonSize,
      double spacing,
      double totalHeight,
      ) {
    return Expanded(
      flex: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: buttonSize,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: NewEventButton(
                    onTap: () {
                      showAddEventOnLaunch = true;
                      selectedScreenNotifier.value = ScreenType.events;
                    },
                    width: buttonSize,
                    height: buttonSize,
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: ReminderBellButton(
                    key: showNotificationsKey,
                    width: buttonSize,
                    height: buttonSize,
                    onTap: () {
                      popupStackCount.value++;
                      showDialog(
                        context: context,
                        builder: (_) => NotificationPopup(
                          userId: FirebaseAuth.instance.currentUser!.uid,
                        ),
                      ).whenComplete(() => popupStackCount.value--);
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: spacing),
          SizedBox(
            height: totalHeight - buttonSize - spacing,
            child: ReminderStatusCard(),
          ),

        ],
      ),
    );
  }


  double contentHeight(Widget widget) {
    final renderBox = widget.key != null && widget.key is GlobalKey
        ? (widget.key as GlobalKey).currentContext?.findRenderObject() as RenderBox?
        : null;

    return renderBox?.size.height ?? 0;
  }
}
