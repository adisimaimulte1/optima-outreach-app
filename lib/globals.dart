import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
import 'package:optima/screens/inApp/widgets/aichat/chat_controller.dart';
import 'package:optima/screens/inApp/widgets/contact/tutorial_card_item.dart';
import 'package:optima/screens/inApp/widgets/dashboard/buttons/new_event_button.dart';
import 'package:optima/screens/inApp/widgets/dashboard/buttons/reminder_bell_button.dart';
import 'package:optima/screens/inApp/widgets/dashboard/cards/upcoming_event.dart';
import 'package:optima/screens/inApp/widgets/events/add_event_form.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:optima/services/ads/ad_service.dart';
import 'package:optima/services/credits/credit_notifier.dart';
import 'package:optima/services/credits/plan_notifier.dart';
import 'package:optima/services/credits/sub_credit_notifier.dart';
import 'package:optima/services/livesync/credit_history_live_sync.dart';
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
final GlobalKey<MenuState> menuGlobalKey = GlobalKey<MenuState>();
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


GlobalKey<SettingsScreenState> settingsKey = GlobalKey<SettingsScreenState>();
GlobalKey<DashboardScreenState> dashboardKey = GlobalKey<DashboardScreenState>();
GlobalKey<EventsScreenState> eventsKey = GlobalKey<EventsScreenState>();
GlobalKey<ContactScreenState> contactKey = GlobalKey<ContactScreenState>();
GlobalKey<ChatScreenState> chatKey = GlobalKey<ChatScreenState>();
GlobalKey<UsersScreenState> usersKey = GlobalKey<UsersScreenState>();





final ValueNotifier<UniqueKey> appReloadKey = ValueNotifier(UniqueKey());
final ValueNotifier<int> popupStackCount = ValueNotifier(0);

final ValueNotifier<bool> isTouchActive = ValueNotifier(true);
final ValueNotifier<bool> tutorialCancelled = ValueNotifier(false);





int pinchAnimationTime = 300;




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

List<EventData> events = [];
final Map<String, ValueNotifier<EventData>> eventNotifiers = {};



double currentTutorialPage = 2.0;
ChatController chatController = ChatController();
bool hasResetAiChat = true;



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
  eventManagers: [email],
  status: 'UPCOMING',
  createdBy: email,
  eventPrice: null,
  eventCurrency: 'RON',
);



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







