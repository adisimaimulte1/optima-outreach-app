import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:optima/globals.dart';

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
    await setNotificationsEnabled(getNotificationsEnabled(), update: false);
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
    setIsDarkModeNotifier(SchedulerBinding.instance.window.platformBrightness == Brightness.dark);
    if (update) await _settingsBox.put('theme_mode', mode.index);
  }

  Future<void> setNotificationsEnabled(bool enabled, {bool update = true}) async {
    notifications = enabled;
    if (update) await _settingsBox.put('notifications_enabled', enabled);
  }

  Future<void> setLocationAccess(bool enabled, {bool update = true}) async {
    locationAccess = enabled;
    if (update) return _settingsBox.put('location_access', enabled);
  }

  Future<void> setIsGoogleUser(bool enabled, {bool update = true}) async {
    isGoogleUser = enabled;
    if (update) return _settingsBox.put('is_google_user', enabled);
  }

}
