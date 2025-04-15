import 'package:optima/globals.dart';

void updateUI() {
  switch (selectedScreenNotifier.value) {
    case ScreenType.dashboard: {
        updateDashboardUI();
      } break;

    case ScreenType.settings: {
      updateSettingsUI();
    } break;

    case ScreenType.calendar: {
      updateEventsUI();
    } break;

    case ScreenType.users:
      // TODO: Handle this case.
      throw UnimplementedError();
    case ScreenType.contact:
      // TODO: Handle this case.
      throw UnimplementedError();
    case ScreenType.brain:
      // TODO: Handle this case.
      throw UnimplementedError();


    case null:
    // TODO: Handle this case.
      throw UnimplementedError();
  }
}

void updateDashboardUI() {
  reminderCardKey.currentState?.update(
    text: "You're all caught up!",
    hasReminder: false,
  );

  upcomingCardKey.currentState?.update(
    title: "Project Sync",
    day: "Wed,",
    date: "Apr 17",
    time: "2:30 PM",
  );
}

void updateSettingsUI() {}
void updateEventsUI() {}