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
    Intent(
        id: "navigate/aichat",
        triggers: ["open", "go to", "enter", "launch", "access", "navigate to", "check", "go back to"],
        targets: [" ai chat", " ai chart"]
    ),
    Intent(
        id: "navigate/contact",
        triggers: ["open", "go to", "enter", "launch", "access", "navigate to", "check", "go back to"],
        targets: ["contact", "tutorial"]
    ),
    Intent(
        id: "navigate/users",
        triggers: ["open", "go to", "enter", "launch", "access", "navigate to", "check", "go back to"],
        targets: ["users", "members", "chat", "team chat"],
        notContains: [" ai "],
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
        triggers: ["turn yourself", "turn off", "disable", "shut", "stop"],
        targets: ["Jamie", "assistant", "AI", "yourself off", "yourself", "down", "talking"]
    ),

    Intent(
        id: "change_setting/toggle_notifications",
        triggers: ["turn on", "turn off", "enable", "disable", "turn", "stop"],
        targets: ["notifications", "notifications off"]
    ),

    Intent(
        id: "change_setting/toggle_location",
        triggers: ["turn on", "turn off", "enable", "disable", "stop"],
        targets: ["location on", "location off", "location", "tracking"]
    ),

    Intent(
      id: "change_setting/toggle_wakeword",
      triggers: ["turn on", "turn off", "enable", "disable", "turn", "stop", "start"],
      targets: [
        "wake word", "wake word off", "wake word on",
        "hey jamie",
        "activation phrase", "activation phrase off", "activation phrase on",
        "voice activation", "voice activation off", "voice activation on"
      ],
    ),

    Intent(
      id: "change_setting/toggle_reminders",
      triggers: ["turn on", "turn off", "turn", "enable", "disable", "stop", "start"],
      targets: [
        "reminders", "reminders off", "reminders on"],
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
      targets: ["credit", "my credit", "credit count"],
    ),

    Intent(
      id: "tap_widget/settings/show_sessions",
      triggers: ["show", "open", "see", "manage", "check"],
      targets: ["session", "device", "active logins", "logged in"],
    ),

    Intent(
      id: "tap_widget/dashboard/show_notifications",
      triggers: ["show", "open", "check"],
      targets: ["notifications", "alerts"],
    ),

    Intent(
      id: "tap_widget/dashboard/show_upcoming_event",
      triggers: ["show", "open", "check", "what's", "see", "view", "what is"],
      targets: ["next event", "upcoming event"],
    ),

    Intent(
      id: "tap_widget/contact/phone",
      triggers: ["call", "dial", "make"],
      targets: ["a phone call", "number", "a call", "team"],
    ),

    Intent(
      id: "tap_widget/contact/email",
      triggers: ["send", "write", "email", "contact"],
      targets: ["email", "mail", "support", "optima"],
    ),

    Intent(
      id: "tap_widget/contact/website",
      triggers: ["open", "visit", "go to", "check"],
      targets: ["site", "website", "page"],
    ),




    // tutorial cards in Contact screen
    Intent(
      id: "tap_widget/contact/tutorial_1",
      triggers: ["show", "open", "start", "view", "begin", "go through", "walk me through", "run"],
      targets: ["getting started", "how to use", "start tutorial", "basics", "first time", "introduction", "onboarding"],
    ),

    Intent(
      id: "tap_widget/contact/tutorial_2",
      triggers: ["show", "open", "view", "see", "explain", "run", "go through"],
      targets: ["event setup", "create event", "setup", "planning tutorial", "event planning"],
    ),

    Intent(
      id: "tap_widget/contact/tutorial_3",
      triggers: ["show", "open", "view", "see", "explain", "manage", "run"],
      targets: ["team management", "add members", "collaboration", "assign roles", "members tutorial"],
    ),

    Intent(
      id: "tap_widget/contact/tutorial_4",
      triggers: ["show", "open", "view", "explain", "demo", "walkthrough", "run"],
      targets: ["live assist", "jamie help", "ai commands", "ai chat tutorial", "assistant tutorial", "voice commands"],
    ),

    Intent(
      id: "tap_widget/contact/tutorial_5",
      triggers: ["show", "open", "walk me through", "configure", "explain", "run"],
      targets: ["settings tutorial", "app preferences", "configuration", "options tutorial", "toggle settings"],
    ),






    // just talk
    Intent(
      id: "just_talk/joke",
      triggers: ["tell", "say", "come up with"],
      targets: ["joke", "another joke", "other joke"],
    ),

  ];
}
