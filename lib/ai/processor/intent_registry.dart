import 'package:optima/ai/processor/intent.dart';

class IntentRegistry {
  static final List<Intent> allIntents = [
    // move through the screens
    Intent(
      id: "navigate/dashboard",
      triggers: ["open", "go to", "enter", "show", "launch", "access", "navigate to", "go back to"],
      targets: ["dashboard", "main screen", "home"],
    ),
    Intent(
      id: "navigate/settings",
      triggers: ["open", "go to", "enter", "launch", "access", "navigate to", "go back to"],
      targets: ["settings", "preferences", "configuration", "config", "options",],
    ),
    Intent(
      id: "navigate/events",
      triggers: ["open", "go to", "enter", "launch", "access", "navigate to", "check", "go back to"],
      targets: ["event", "outreach list", "planning"],
    ),
    Intent(
      id: "navigate/menu",
      triggers: ["open", "go to", "enter", "launch", "access", "navigate to", "check", "go back to"],
      targets: ["menu", "main menu", "selection screen"]
    ),



    // settings
    Intent(
        id: "change_setting/toggle_theme",
        triggers: ["switch", "toggle"],
        targets: ["theme"]
    ),
    Intent(
        id: "change_setting/change_theme",
        triggers: ["change", "switch"],
        targets: ["dark", "light", "system"]
    ),

    Intent(
        id: "change_setting/disable_jamie",
        triggers: ["turn", "disable", "shut", "stop"],
        targets: ["Jamie", "assistant", "AI", "yourself", "down", "off"]
    ),

    Intent(
        id: "change_setting/toggle_notifications",
        triggers: ["turn on", "turn off", "enable", "disable"],
        targets: ["notifications", "alerts"]
    ),

    Intent(
        id: "change_setting/toggle_location",
        triggers: ["turn on", "turn off", "enable", "disable"],
        targets: ["location", "tracking"]
    ),



    // open widgets
    Intent(
      id: "tap_widget/events/add_event",
      triggers: ["add", "create", "start", "begin"],
      targets: ["event", "new event", "an event", "outreach"],
    ),

    Intent(
      id: "tap_widget/settings/show_credits",
      triggers: ["show", "open", "see", "check"],
      targets: ["credits", "my credits", "credit count"],
    ),

    Intent(
      id: "tap_widget/settings/show_sessions",
      triggers: ["show", "open", "see", "manage", "check"],
      targets: ["sessions", "devices", "active logins", "logged in"],
    ),

    Intent(
      id: "tap_widget/dashboard/show_notifications",
      triggers: ["show", "open", "check"],
      targets: ["notifications", "alerts"],
    ),

  ];
}
