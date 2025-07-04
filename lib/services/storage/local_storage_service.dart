import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:optima/globals.dart';
import 'package:optima/services/storage/cloud_storage_service.dart';
import 'package:optima/services/notifications/push_notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  late Box _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _settingsBox = await Hive.openBox('settings');
    await initSettings();
  }

  Future<void> initSettings() async {
    await setThemeMode(getThemeMode(), update: false);
    await setLocationAccess(getLocationAccess(), update: false);
    await setIsGoogleUser(getIsGoogleUser(), update: false);
  }



  ThemeMode getThemeMode() {
    final index = _settingsBox.get('theme_mode', defaultValue: 0);
    return ThemeMode.values[index];
  }

  bool getNotificationsEnabled() {
    return _settingsBox.get('notifications_enabled', defaultValue: true);
  }

  bool getLocationAccess()  {
    return _settingsBox.get('location_access', defaultValue: false);
  }

  bool getIsGoogleUser() {
    return _settingsBox.get('is_google_user', defaultValue: false);
  }



  Future<void> setThemeMode(ThemeMode mode, {bool update = true}) async {
    selectedTheme = mode;

    appReloadKey.value = UniqueKey();
    selectedThemeNotifier.value = mode;
    setIsDarkModeNotifier(SchedulerBinding.instance.window.platformBrightness == Brightness.dark);

    if (update) await _settingsBox.put('theme_mode', mode.index);
  }

  Future<void> setNotificationsEnabled(bool enabled, {bool update = true}) async {
    notifications = enabled;
    notificationsPermissionNotifier.value = enabled;
    if (update) await _settingsBox.put('notifications_enabled', enabled);
  }

  Future<void> setLocationAccess(bool enabled, {bool update = true}) async {
    locationAccess = enabled;
    locationPermissionNotifier.value = enabled;
    if (update) return _settingsBox.put('location_access', enabled);
  }

  Future<void> setIsGoogleUser(bool enabled, {bool update = true}) async {
    isGoogleUser = enabled;
    if (update) return _settingsBox.put('is_google_user', enabled);
  }



  Future<void> checkAndRequestPermissionsOnce() async {
    final alreadyAsked = await LocalStorageService().hasAskedPermissions();
    if (alreadyAsked) return;
    assistantState.value = JamieState.thinking;

    // notifications
    final settings = await FirebaseMessaging.instance.requestPermission();
    final notifGranted = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (notifGranted) {
      await PushNotificationService.initialize(onHardDenied: () async {});
      await LocalStorageService().setNotificationsEnabled(true);
    } else { await LocalStorageService().setNotificationsEnabled(false); }

    await Future.delayed(Duration(milliseconds: 300));


    // mic
    final micStatus = await Permission.microphone.request();
    final micGranted = micStatus == PermissionStatus.granted;

    if (!micGranted && jamieEnabled) {
      await CloudStorageService().saveUserSetting('jamieEnabled', false);
      jamieEnabledNotifier.value = false;
      jamieEnabled = false;
    }


    // mark permissions as asked
    await LocalStorageService().setAskedPermissions();
  }




  Future<bool> hasAskedPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('asked_permissions') ?? false;
  }

  Future<void> setAskedPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('asked_permissions', true);
  }

  Future<bool> hasSeenTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hasSeenTutorial') ?? true;
  }

  Future<void> setSeenTutorial(bool seen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenTutorial', seen);
  }






  Future<void> setSessionId(String sessionId) async {
    await _settingsBox.put('session_id', sessionId);
  }

  Future<String?> getSessionId() async {
    return _settingsBox.get('session_id');
  }

  Future<void> removeSessionId() async {
    await _settingsBox.delete('session_id');
  }

  Future<void> setSessionData(Map<String, dynamic> data) async {
    final cleanedData = data.map((key, value) {
      if (value is Timestamp) {
        return MapEntry(key, value.toDate()); // convert to DateTime
      }
      return MapEntry(key, value);
    });

    await _settingsBox.put('session_data', cleanedData);
  }


  Map<String, dynamic>? getSessionData() {
    return _settingsBox.get('session_data');
  }

  Future<void> removeSessionData() async {
    await _settingsBox.delete('session_data');
  }

}
