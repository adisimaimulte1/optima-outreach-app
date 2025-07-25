import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:optima/ai/ai_assistant.dart';
import 'package:optima/ai/ai_status_dots.dart';
import 'package:optima/ai/navigator/trigger_proxy.dart';
import 'package:optima/screens/inApp/menu.dart';
import 'package:optima/screens/inApp/util/aichat.dart';
import 'package:optima/screens/inApp/util/contact.dart';
import 'package:optima/screens/inApp/util/dashboard.dart';
import 'package:optima/screens/inApp/util/events.dart';
import 'package:optima/screens/inApp/util/settings.dart';
import 'package:optima/screens/inApp/util/users.dart';
import 'package:optima/screens/inApp/widgets/aichat/ai_chat_controller.dart';
import 'package:optima/screens/inApp/widgets/aichat/ai_chat_message.dart';
import 'package:optima/screens/inApp/widgets/contact/tutorial_card_item.dart';
import 'package:optima/screens/inApp/widgets/dashboard/buttons/new_event_button.dart';
import 'package:optima/screens/inApp/widgets/dashboard/buttons/reminder_bell_button.dart';
import 'package:optima/screens/inApp/widgets/dashboard/cards/upcoming_event.dart';
import 'package:optima/screens/inApp/widgets/dashboard/chart.dart';
import 'package:optima/screens/inApp/widgets/dashboard/event_action_selector.dart';
import 'package:optima/screens/inApp/widgets/events/add_event_form.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:optima/screens/inApp/widgets/users/members_chat/members_chat_message.dart';
import 'package:optima/screens/inApp/widgets/users/tabs/events_chat_tab.dart';
import 'package:optima/screens/inApp/widgets/users/tabs/public_events_tab.dart';
import 'package:optima/screens/inApp/widgets/users/users_controller.dart';
import 'package:optima/services/ads/ad_service.dart';
import 'package:optima/services/credits/credit_notifier.dart';
import 'package:optima/services/credits/plan_notifier.dart';
import 'package:optima/services/credits/sub_credit_notifier.dart';
import 'package:optima/services/livesync/combined_listenable.dart';
import 'package:optima/services/livesync/credit_history_live_sync.dart';
import 'package:optima/services/livesync/event_live_sync.dart';
import 'package:optima/services/storage/local_storage_service.dart';



enum JamieState {
  idle,
  listening,
  thinking,
  speaking,
  done,
}

enum ScreenType {
  dashboard,
  events,
  users,
  contact,
  chat,
  settings,
  menu,
}

enum UserState {
  authenticated,
  unverified,
  unauthenticated,
}


// keys
GlobalKey<MenuState> menuGlobalKey = GlobalKey<MenuState>();
final GlobalKey<NewEventButtonState> createEventButtonKey = GlobalKey<NewEventButtonState>();
final GlobalKey<ReminderBellButtonState> showNotificationsKey = GlobalKey<ReminderBellButtonState>();
final GlobalKey<UpcomingEventCardState> showUpcomingEventCardKey = GlobalKey<UpcomingEventCardState>();

final GlobalKey<AddEventFormState> addEventKey = GlobalKey<AddEventFormState>();

final List<GlobalKey<TutorialCardItemState>> tutorialCardKeys = List.generate(5, (_) => GlobalKey<TutorialCardItemState>());

final GlobalKey<TriggerProxyState> showCreditsTileKey = GlobalKey<TriggerProxyState>();
final GlobalKey<TriggerProxyState> showSessionsTileKey = GlobalKey<TriggerProxyState>();

final GlobalKey<TriggerProxyState> phoneTriggerKey = GlobalKey<TriggerProxyState>();
final GlobalKey<TriggerProxyState> emailTriggerKey = GlobalKey<TriggerProxyState>();
final GlobalKey<TriggerProxyState> websiteTriggerKey = GlobalKey<TriggerProxyState>();

GlobalKey<ScaffoldState> aiChatScaffoldKey = GlobalKey<ScaffoldState>();

final GlobalKey<EventsChatTabState> eventsChatTabKey = GlobalKey<EventsChatTabState>();
final GlobalKey<PublicEventsTabState> publicEventsTabKey = GlobalKey<PublicEventsTabState>();

final GlobalKey<LineChartCardState> chartCardKey = GlobalKey<LineChartCardState>();
final GlobalKey<EventActionSelectorWheelState> eventActionSelectorKey = GlobalKey<EventActionSelectorWheelState>();



GlobalKey<SettingsScreenState> settingsKey = GlobalKey<SettingsScreenState>();
GlobalKey<DashboardScreenState> dashboardKey = GlobalKey<DashboardScreenState>();
GlobalKey<EventsScreenState> eventsKey = GlobalKey<EventsScreenState>();
GlobalKey<ContactScreenState> contactKey = GlobalKey<ContactScreenState>();
GlobalKey<ChatScreenState> chatKey = GlobalKey<ChatScreenState>();
GlobalKey<UsersScreenState> usersKey = GlobalKey<UsersScreenState>();





final ValueNotifier<UniqueKey> appReloadKey = ValueNotifier(UniqueKey());
final ValueNotifier<int> popupStackCount = ValueNotifier(0);

final ValueNotifier<bool> isTouchActive = ValueNotifier(true);
final ValueNotifier<bool> isTutorialActive = ValueNotifier(false);
final ValueNotifier<bool> tutorialCancelled = ValueNotifier(false);





int pinchAnimationTime = 300;




const Map<String, IconData> reactions = {
  'like': Icons.thumb_up_alt_outlined,
  'love': Icons.favorite_border,
  'laugh': Icons.emoji_emotions_outlined,
  'fire': Icons.whatshot_outlined,
  'sad': Icons.sentiment_dissatisfied_outlined,
};





// local storage data
ThemeMode selectedTheme = ThemeMode.system;
ValueNotifier<ThemeMode> selectedThemeNotifier = ValueNotifier(selectedTheme);
bool notifications = LocalStorageService().getNotificationsEnabled();
bool locationAccess = LocalStorageService().getLocationAccess();
bool isGoogleUser = false;


// cloud storage data
bool jamieEnabled = true;
bool wakeWordEnabled = true;
bool jamieReminders = true;
String name = "";
String email = "";
String? photoUrl;
int credits = 0; // teapa ca daca schimbi asta nu primesti credite in plus
String plan = ""; // teapa ca daca schimbi asta nu ai alt plan ;)
double subCredits = 0;


List<EventData> upcomingPublicEvents = [];
List<EventData> events = [];
final Map<String, ValueNotifier<EventData>> eventNotifiers = {};
final CombinedListenable combinedEventsListenable = CombinedListenable();


double currentTutorialPage = 2.0;
AiChatController chatController = AiChatController();
bool hasResetAiChat = true;

UsersController usersController = UsersController();




bool preloadTutorialEvent = false;
EventData tutorialEventData = EventData(
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
  eventManagers: [''],
  status: 'UPCOMING',
  createdBy: '',
  eventPrice: null,
  eventCurrency: 'RON',
  chatImage: null,
)..id = 'tutorial';
final tutorialNotifier = ValueNotifier(tutorialEventData);




final GlobalKey<AIStatusDotsState> aiDotsKey = GlobalKey<AIStatusDotsState>();
final Widget aiAssistant = AIStatusDots(key: aiDotsKey);
late AIStatusDotsState aiAssistantState;


final AIVoiceAssistant aiVoice = AIVoiceAssistant();
final appMenu = Menu(key: menuGlobalKey);


bool isFirstDashboardLaunch = true;
bool isInitialLaunch = true;
User? get user => FirebaseAuth.instance.currentUser;


ValueNotifier<Map<String, CreditHistory>> creditHistoryMap = ValueNotifier({});


final ValueNotifier<double> screenScaleNotifier = ValueNotifier(1.0);

ValueNotifier<bool> jamieEnabledNotifier = ValueNotifier(true);
ValueNotifier<bool> wakeWordEnabledNotifier = ValueNotifier(true);
ValueNotifier<bool> jamieRemindersNotifier = ValueNotifier(true);
ValueNotifier<bool> notificationsPermissionNotifier = ValueNotifier(notifications);
ValueNotifier<bool> locationPermissionNotifier = ValueNotifier(locationAccess);


final ValueNotifier<bool> isMenuOpenNotifier = ValueNotifier(false);
final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(false);

final ValueNotifier<ScreenType> selectedScreenNotifier = ValueNotifier(ScreenType.dashboard);
final ValueNotifier<JamieState> assistantState = ValueNotifier(JamieState.idle);

final ValueNotifier<String> transcribedText = ValueNotifier('');


SubCreditNotifier subCreditNotifier = SubCreditNotifier();
CreditNotifier creditNotifier = CreditNotifier();
PlanNotifier selectedPlan = PlanNotifier();

final adService = AdService();



bool showAddEventOnLaunch = false;
MapEntry<bool, MapEntry<EventData?, String?>> showCardOnLaunch = MapEntry(false, MapEntry(null, null));
MapEntry<bool, EventData?> showEventChatOnLaunch = MapEntry(false, null);



final int tutorialImagesCount = 5;




bool updateSettingsAfterAppResume = false;
bool wakeWordDetected = false;
bool isListeningForWake = false;
bool appPaused = false;
bool lastCredit = false;





AppLifecycleState? currentAppState;




// colors

Color lightColorPrimary = const Color(0xFFFFC62D);
Color lightColorSecondary = const Color(0xFFFFE8A7);

Color darkColorPrimary = const Color(0xFF973BBA);
Color darkColorSecondary = const Color(0xFFDD88FF);

Color inAppBackgroundColor = const Color(0xFF1C2837);
Color inAppForegroundColor = const Color(0xFF24324A);
Color borderColor = Colors.white12;

Color textColor = Colors.white;
Color textDimColor = Colors.white12;
Color textHighlightedColor = isDarkModeNotifier.value ? darkColorSecondary : lightColorPrimary;
Color textSecondaryHighlightedColor = isDarkModeNotifier.value ? darkColorPrimary: lightColorSecondary;

Color black = Colors.black;



final List<String> charityKeys = [
  "charity", "donation", "fundraise", "help", "volunteer",
  "support", "aid", "relief", "nonprofit", "give", "humanitarian",
  "benefit", "drive", "good cause", "community service",
  "fund raise"
];
final List<String> techKeys = [
  "tech", "robot", "ai", "machine learning", "ml", "coding", "robotics",
  "programming", "developer", "software", "hardware",
  "innovation", "startup", "iot", "cloud", "cyber", "blockchain", "engineering",
  "flutter", "python", "arduino", "electronics", "hack", "code"
];
final List<String> sportsKeys = [
  "sport", "football", "soccer", "basketball", "volleyball", "tennis", "cricket",
  "athletics", "race", "run", "marathon", "tournament", "league", "competition",
  "match", "game", "fitness", "gym", "training", "track", "field", "swimming"
];



final Set<String> cachedPhotosForEmail = {};
Map<String, dynamic>? emailToNameMap;
QuerySnapshot<Map<String, dynamic>>? allPublicData;



void removeTutorialEvent() {
  if (events.any((e) => e.id == tutorialEventData.id)) {
    EventLiveSyncService().stopListeningToEvent(tutorialEventData.id!);
    eventNotifiers.remove(tutorialEventData.id);
    combinedEventsListenable.remove(tutorialNotifier);

    final index = events.indexWhere((e) => e.id == tutorialEventData.id);
    if (index != -1) {
      events.removeAt(index);
    }
    rebuildUI();
  }
}

void addTutorialEvent() {
  initTutorialEvent();

  if (!events.any((e) => e.id == tutorialEventData.id)) {
    // Insert tutorial event locally
    events.insert(0, tutorialEventData);

    // Add notifiers
    eventNotifiers[tutorialEventData.id!] = tutorialNotifier;
    combinedEventsListenable.add(tutorialNotifier);
    EventLiveSyncService().fakeListener(tutorialEventData.id!);

    rebuildUI();
  }
}

void initTutorialEvent() {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  email = FirebaseAuth.instance.currentUser!.email!;

  tutorialEventData
    ..createdBy = email
    ..eventManagers = [email]
    ..membersChatMessages = [
      MembersChatMessage(
        id: 'msg1',
        senderId: 'optimatestid',
        content: 'This is how a message from **other** users looks like!',
        timestamp: DateTime.now(),
        reactions: {
          'laugh': [uid],
        },
      ),
      MembersChatMessage(
        id: 'msg2',
        senderId: uid,
        content: 'And this is how **your** messages looks like! Keep in mind, only *managers can write*.',
        timestamp: DateTime.now().add(const Duration(seconds: 4)),
      ),
      MembersChatMessage(
        id: 'msg3',
        senderId: uid,
        content: "But you can react to both your messages and other users'",
        timestamp: DateTime.now().add(const Duration(seconds: 8)),
        reactions: {
          'love': ['optimatestid'],
          'fire': [uid],
        },
      ),
    ]
    ..aiChatMessages = [
      AiChatMessage(
        id: 'aiMsg1',
        content: 'Hey Jamie, can you please tell me what are the goals of the event and how to reach them?',
        timestamp: DateTime.now(),
        role: 'user',
      ),
      AiChatMessage(
        id: 'aiMsg2',
        content: "# Event Goals\n- **Recruit 10 members**\n- **Promote STEM**\n# How to Accomplish Them\n- **Recruit 10 members**: promote the event on social media, invite friends personally, and showcase what makes your organization exciting.\n- **Promote STEM**: organize fun hands-on activities, interactive demos, and short talks about tech and science to spark curiosity.",
        timestamp: DateTime.now().add(const Duration(seconds: 4)),
        isPinned: true,
        role: 'assistant',
      ),
    ];

  tutorialNotifier.value = tutorialEventData;
}

void rebuildUI() {
  SchedulerBinding.instance.addPostFrameCallback((_) {
    final old = screenScaleNotifier.value;
    screenScaleNotifier.value = old == 1.0 ? 0.999 : 1.0;
    Future.delayed(Duration(milliseconds: 10), () {
      screenScaleNotifier.value = old;
    });
  });
}

void setupGlobalListeners() {
  screenScaleNotifier.addListener(() {
    final scale = screenScaleNotifier.value;
    isMenuOpenNotifier.value = scale < 0.99;
  });
}

void setIsDarkModeNotifier(bool isDarkSystem) {
  if (selectedTheme == ThemeMode.system) { isDarkModeNotifier.value = isDarkSystem; }
  else if (selectedTheme == ThemeMode.dark) { isDarkModeNotifier.value = true; }
  else { isDarkModeNotifier.value = false; }

  textHighlightedColor = isDarkModeNotifier.value ? darkColorPrimary : lightColorPrimary;
  textSecondaryHighlightedColor = isDarkModeNotifier.value ? darkColorSecondary : lightColorSecondary;
}

bool isEventNearby(Position userPos, LatLng eventPos, {double radiusKm = 50}) {
  final distance = Geolocator.distanceBetween(
    userPos.latitude, userPos.longitude,
    eventPos.latitude, eventPos.longitude,
  );
  return distance <= radiusKm * 1000;
}




Widget responsiveText(
    BuildContext context,
    String text, {
      required double maxWidthFraction,
      required TextStyle style,
      TextAlign align = TextAlign.center,
    }) {
  final screenWidth = MediaQuery.of(context).size.width;
  return SizedBox(
    width: screenWidth * maxWidthFraction,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        style: style,
        textAlign: align,
      ),
    ),
  );
}

InputDecoration standardInputDecoration({
  required String hint,
  String? label,
  Color? fillColor,
  Color? hintColor,
  Color? labelColor,
  Color? borderColor,
}) {
  return InputDecoration(
    hintText: hint,
    labelText: label,
    hintStyle: TextStyle(
        color: hintColor ?? Colors.white54),
    labelStyle: TextStyle(
      color: labelColor ?? Colors.white70, // <-- use labelColor if provided
    ),
    filled: true,
    fillColor: fillColor ?? Colors.white.withOpacity(0.06),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(
          color: borderColor ?? Colors.white.withOpacity(0.2)),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(
          color: borderColor ?? Colors.white.withOpacity(0.5)),
      borderRadius: BorderRadius.circular(12),
    ),
  );
}



Future<String> convertImageUrlToBase64(String url) async {
  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return base64Encode(response.bodyBytes);
    }
  } catch (e) {
    debugPrint('Failed to download or encode image: $e');
  }
  return '';
}

Future<Position?> getCurrentLocation() async {
  final permission = await Geolocator.requestPermission();
  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    return null;
  }

  return await Geolocator.getCurrentPosition();
}

Future<LatLng?> getEventCoordinates(String address) async {
  try {
    final locations = await locationFromAddress(address);
    if (locations.isNotEmpty) {
      final loc = locations.first;
      return LatLng(loc.latitude, loc.longitude);
    }
  } catch (_) {}
  return null;
}

Future<void> getPublicData() async {
  allPublicData = await FirebaseFirestore.instance
      .collection('public_data')
      .get();

  emailToNameMap = {
    for (var doc in allPublicData!.docs)
      doc.data()['email'].toString().toLowerCase(): doc.data()['name'],
  };

}


Future<List<String>> getTagsForEvent(EventData event, Position? userLocation) async {
  final tags = <String>[];

  final name = event.eventName.toLowerCase();
  final goals = event.eventGoals.map((g) => g.toLowerCase()).toList();

  bool match(List<String> keys) => keys.any(
        (k) => name.contains(k) || goals.any((g) => g.contains(k)),
  );

  if (match(charityKeys)) tags.add("Charity");
  if (match(techKeys)) tags.add("Tech");
  if (match(sportsKeys)) tags.add("Sports");

  if (userLocation != null) {
    final eventCoords = await getEventCoordinates(event.locationAddress ?? '');
    if (eventCoords != null && isEventNearby(userLocation, eventCoords)) {
      tags.add("Local");
    }
  }

  return tags;
}



String formatDate(DateTime date) {
  const monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final day = date.day;
  final month = monthNames[date.month - 1];
  final year = date.year;
  return '$month $day, $year';
}

String formatTime(TimeOfDay time) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
}







