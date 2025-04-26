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
  }



  ThemeMode getThemeMode() {
    final index = _settingsBox.get('theme_mode', defaultValue: 0);
    return ThemeMode.values[index];
  }

  Future<void> setThemeMode(ThemeMode mode, {bool update = true}) async {
    selectedTheme = mode;
    setIsDarkModeNotifier(SchedulerBinding.instance.window.platformBrightness == Brightness.dark);
    if (update) await _settingsBox.put('theme_mode', mode.index);
  }

  bool getNotificationsEnabled() {
    return _settingsBox.get('notifications_enabled', defaultValue: true);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _settingsBox.put('notifications_enabled', enabled);
  }
}
