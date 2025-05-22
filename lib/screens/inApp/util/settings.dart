import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/material.dart';

import 'package:optima/screens/choose_screen.dart';
import 'package:optima/screens/inApp/widgets/settings/buttons/text_button.dart';
import 'package:optima/screens/inApp/widgets/settings/dialogs/account_delete_dialogs.dart';
import 'package:optima/screens/inApp/widgets/settings/dialogs/change_password_dialog.dart';
import 'package:optima/screens/inApp/widgets/settings/dialogs/support_dialog.dart';
import 'package:optima/screens/inApp/widgets/settings/dialogs/credit_dialog.dart';
import 'package:optima/screens/inApp/widgets/settings/dialogs/help_dialog.dart';
import 'package:optima/screens/inApp/widgets/settings/dialogs/privacy_settings_dialog.dart';
import 'package:optima/screens/inApp/widgets/settings/dialogs/session_management_dialog.dart';
import 'package:optima/screens/inApp/widgets/settings/dialogs/update_plan_dialog.dart';
import 'package:optima/screens/inApp/widgets/settings/dialogs/watch_ad_dialog.dart';

import 'package:optima/screens/inApp/widgets/settings/profile_avatar.dart';
import 'package:optima/screens/inApp/widgets/abstract_screen.dart';
import 'package:optima/screens/inApp/widgets/settings/tiles.dart';

import 'package:optima/globals.dart';
import 'package:optima/services/cache/local_cache.dart';
import 'package:optima/services/notifications/local_notification_service.dart';

import 'package:optima/services/storage/local_storage_service.dart';
import 'package:optima/services/storage/cloud_storage_service.dart';
import 'package:optima/services/location/location_processor.dart';
import 'package:optima/services/notifications/push_notification_service.dart';
import 'package:optima/services/sessions/session_service.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GlobalKey<ProfileAvatarState> _profileAvatarKey = GlobalKey<ProfileAvatarState>();

  int _versionTapCount = 0;
  int _iconIndex = 0;
  bool _disableScroll = false;
  bool _easterEggMode = false;

  final List<IconData> _easterEggIcons = [
    Icons.egg, Icons.auto_awesome, Icons.nature, Icons.cake,
    Icons.favorite, Icons.star, Icons.wb_sunny, Icons.local_florist, Icons.eco,
  ];



  IconData _getNextEasterEggIcon() =>
      _easterEggIcons[_iconIndex++ % _easterEggIcons.length];



  @override
  void dispose() {
    _profileAvatarKey.currentState?.dispose();

    notificationsPermissionNotifier.removeListener(_updatePermissions);
    locationPermissionNotifier.removeListener(_updatePermissions);
    jamieEnabledNotifier.removeListener(_updatePermissions);

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    notificationsPermissionNotifier.addListener(_updatePermissions);
    locationPermissionNotifier.addListener(_updatePermissions);
    jamieEnabledNotifier.addListener(_updatePermissions);
  }




  Future<String?> uploadProfileImage(File file) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return null;
      }

      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      CloudStorageService().saveUserProfileIndividual('photo', base64Image);

      return base64Image;
    } catch (e) { return null; }
  }

  void _updatePermissions() {setState(() {});}

  void _editName() {
    final controller = TextEditingController(text: name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: inAppForegroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Edit Name", style: TextStyle(color: textColor)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: textColor),
          decoration: standardInputDecoration(hint: "Your name", label: "Name"),
        ),
        actionsPadding: const EdgeInsets.only(bottom: 8, right: 12),
        actions: [
          TextButtonWithoutIcon(
            label: "Save",
            onPressed: () {
              final newName = controller.text.trim();
              setState(() => name = newName);
              CloudStorageService().saveUserProfileIndividual("name", newName);

              Navigator.pop(context);
            },
            backgroundColor: textHighlightedColor,
            foregroundColor: inAppForegroundColor,
            fontSize: 17,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ],
      ),
    );
  }




  @override
  Widget build(BuildContext context) {
    return AbsScreen(
      sourceType: SettingsScreen,
      builder: (context, isMinimized, scale) {
        if ((_disableScroll && scale >= 0.99) || (!_disableScroll && scale < 0.99)) {
          _disableScroll = scale < 0.99;
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SingleChildScrollView(
                physics: _disableScroll
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30),
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    ProfileAvatar(key: _profileAvatarKey),
                    _buildSettingsContent(),
                    const SizedBox(height: 20),
                    _buildLogoutButton(),
                  ],
                )
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsContent() {
    _iconIndex = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection("Account", [
          Tiles.tile(
            context: context,
            icon: Icons.person,
            title: "Edit Name",
            onTap: _editName,
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          ),
          Tiles.tile(
            context: context,
            icon: Icons.lock_outline,
            title: "Change Password",
            onTap: () => ChangePasswordDialog.show(context),
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          ),
          Tiles.tile(
            context: context,
            icon: Icons.delete_outline,
            title: "Delete Account",
            onTap: () async {
              await AccountDeleteDialogs.showDeleteConfirmationDialog(context);
            },
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          ),
        ]),
        _buildSection("Appearance", [
          Tiles.themeDropdownTile(
            selectedTheme: selectedTheme,
            onChanged: (mode) async {
              setState(() { selectedTheme = mode; });
              await LocalStorageService().setThemeMode(mode);
            },
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          )
        ]),
        _buildSection("Jamie Assistant", [
          Tiles.switchTile(
            icon: Icons.smart_toy,
            title: "Enable Jamie",
            value: jamieEnabled,
            onChanged: (val) async {
              if (val) {
                final status = await Permission.microphone.request();

                if (status.isGranted) {
                  setState(() {
                    jamieEnabled = true;
                    jamieEnabledNotifier.value = true;
                  });
                  await CloudStorageService().saveUserSetting('jamieEnabled', true);
                } else {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: inAppForegroundColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text(
                        "Microphone Permission Required",
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      content: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "To enable Jamie, please allow microphone access in your device settings.",
                          style: TextStyle(color: textColor, fontSize: 16, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      actions: [
                        TextButtonWithoutIcon(
                          label: "Cancel",
                          onPressed: () => Navigator.pop(context),
                          foregroundColor: Colors.white70,
                          fontSize: 17,
                          borderColor: Colors.white70,
                          borderWidth: 1.2,
                        ),
                        TextButtonWithoutIcon(
                          label: "Open Settings",
                          onPressed: () async {
                            updateSettingsAfterAppResume = true;
                            Navigator.pop(context);
                            await openAppSettings();
                          },
                          backgroundColor: textHighlightedColor,
                          foregroundColor: inAppForegroundColor,
                          fontSize: 17,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                      ],
                    ),
                  );

                  setState(() => jamieEnabled = false);
                }
              } else {
                setState(() {
                  jamieEnabled = false;
                  jamieEnabledNotifier.value = false;
                });
                await CloudStorageService().saveUserSetting('jamieEnabled', false);
              }
            },
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          ),
          Tiles.switchTile(
            icon: Icons.hearing,
            title: "Wake Word Detection",
            value: wakeWordEnabled,
            onChanged: (val) {
              setState(() {
                wakeWordEnabled = val;
                wakeWordEnabledNotifier.value = val;
              });
              CloudStorageService().saveUserSetting('wakeWordEnabled', val);
            },
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          ),
          Tiles.switchTile(
            icon: Icons.alarm,
            title: "Jamie Reminders",
            value: jamieReminders,
            onChanged: (val) {
              setState(() => jamieReminders = val);
              CloudStorageService().saveUserSetting('jamieReminders', val);
              },
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          ),
        ]),
        _buildSection("Notifications", [
          Tiles.switchTile(
            icon: Icons.notifications,
            title: "Push Notifications",
            value: notifications,
            onChanged: (val) async {
              if (val) {
                final settings = await FirebaseMessaging.instance.getNotificationSettings();
                final alreadyGranted = settings.authorizationStatus == AuthorizationStatus.authorized;
                var success = true;

                if (!alreadyGranted) {
                  success = await PushNotificationService.initialize(
                      onHardDenied: () {
                        showDialog(
                          context: context,
                          builder: (_) =>
                              AlertDialog(
                                backgroundColor: inAppForegroundColor,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                title: Text(
                                  "Notifications Disabled",
                                  style: TextStyle(color: textColor,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                content: Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    "To enable push notifications, allow them in your device settings.",
                                    style: TextStyle(color: textColor,
                                        fontSize: 16,
                                        height: 1.5),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                actions: [
                                  TextButtonWithoutIcon(
                                    label: "Cancel",
                                    onPressed: () => Navigator.pop(context),
                                    foregroundColor: Colors.white70,
                                    fontSize: 17,
                                    borderColor: Colors.white70,
                                    borderWidth: 1.2,
                                  ),
                                  TextButtonWithoutIcon(
                                    label: "Open Settings",
                                    onPressed: () {
                                      updateSettingsAfterAppResume = true;
                                      Navigator.pop(context);
                                      PushNotificationService.openSettings();
                                    },
                                    backgroundColor: textHighlightedColor,
                                    foregroundColor: inAppForegroundColor,
                                    fontSize: 17,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                  ),
                                ],
                              ),
                        );
                      }
                  );

                  setState(() => notifications = success);
                  notificationsPermissionNotifier.value = success;
                  await LocalStorageService().setNotificationsEnabled(success);
                } else {
                  setState(() => notifications = success);
                  notificationsPermissionNotifier.value = success;
                  await LocalStorageService().setNotificationsEnabled(success);

                  final token = await FirebaseMessaging.instance.getToken();

                  if (token != null) {
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .update({'fcmToken': token});
                  }
                }

              } else {
                setState(() => notifications = false);
                notificationsPermissionNotifier.value = false;
                await LocalStorageService().setNotificationsEnabled(false);

                FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .update({'fcmToken': ''});

                await PushNotificationService.disableNotifications();
              }
            },
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          )
        ]),
        _buildSection("Privacy & Security", [
          Tiles.switchTile(
            icon: Icons.location_on,
            title: "Location Access",
            value: locationAccess,
            onChanged: (val) async {
              if (val) {
                final status = await Permission.location.request();

                if (status.isGranted) {
                  setState(() => locationAccess = true);
                  await LocalStorageService().setLocationAccess(true);
                  await LocationProcessor.updateUserCountryCode();

                } else {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: inAppForegroundColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text(
                        "Location Permission Required",
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      content: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "To enable location features, allow location access in your device settings.",
                          style: TextStyle(color: textColor, fontSize: 16, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      actions: [
                        TextButtonWithoutIcon(
                          label: "Cancel",
                          onPressed: () => Navigator.pop(context),
                          foregroundColor: Colors.white70,
                          fontSize: 17,
                          borderColor: Colors.white70,
                          borderWidth: 1.2,
                        ),
                        TextButtonWithoutIcon(
                          label: "Open Settings",
                          onPressed: () async {
                            updateSettingsAfterAppResume = true;
                            Navigator.pop(context);
                            await openAppSettings();
                          },
                          backgroundColor: textHighlightedColor,
                          foregroundColor: inAppForegroundColor,
                          fontSize: 17,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                      ],
                    ),
                  );
                }
              } else {
                setState(() => locationAccess = false);

                await LocalStorageService().setLocationAccess(false);
                await LocationProcessor.handlePermissionDenied();
              }
            },
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          ),
          Tiles.tile(
            context: context,
            icon: Icons.privacy_tip,
            title: "Privacy Settings",
            onTap: () => PrivacySettingsDialog.show(context),
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          ),
          Tiles.tile(
            context: context,
            icon: Icons.devices,
            title: "Session Management",
            onTap: () => SessionManagementDialog.show(context),
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          ),
        ]),
        _buildSection("Credits & Billing", [
          Tiles.tile(
            context: context,
            icon: Icons.credit_score,
            title: "My Credits",
            onTap: () => CreditDialog.show(context),
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          ),
          Tiles.tile(
            context: context,
            icon: Icons.subscriptions,
            title: "Upgrade Plan",
            onTap: () => UpgradePlanDialog.show(context, selectedPlan),
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          ),
          Tiles.tile(
            context: context,
            icon: Icons.smart_display,
            title: "Watch Ads for Credits",
            onTap: () => WatchAdDialog.show(context),
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          ),
        ]),
        _buildSection("Help & About", [
          Tiles.tile(
            context: context,
            icon: Icons.help_outline,
            title: "Help & FAQ",
            onTap: () => HelpDialog.show(context),
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          ),
          Tiles.tile(
            context: context,
            icon: Icons.mail_outline,
            title: "Contact Support",
            onTap: () => SupportDialog.show(context),
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          ),
          Tiles.tile(
            context: context,
            icon: Icons.info_outline,
            title: "App Version 1.0.0",
            showArrow: false,
            leadingFraction: (_versionTapCount == 1)
                ? 1 / 3
                : (_versionTapCount == 2)
                ? 2 / 3
                : 1.0,
            onTap: () {
              _versionTapCount++;
              if (_versionTapCount >= 3) {
                setState(() {
                  _easterEggMode = !_easterEggMode;
                  _versionTapCount = 0;
                });
              } else {
                setState(() {}); // to trigger icon reveal
              }
            },
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          ),
        ]),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textColor)),
              const SizedBox(height: 4),
              Container(height: 2, width: double.infinity, color: Colors.white70),
            ],
          ),
        ),
        Column(
          children: tiles.map((tile) => Padding(padding: const EdgeInsets.only(bottom: 2), child: tile)).toList(),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return Center(
      child: ElevatedButton.icon(
          onPressed: () async {
            selectedPlan.cancel();
            creditNotifier.cancel();
            subCreditNotifier.cancel();

            await FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .update({'fcmToken': ''});

            creditNotifier.cancel();
            subCreditNotifier.cancel();
            selectedPlan.cancel();

            LocalNotificationService().stopListening();
            await LocalCache().logout();
            await SessionService().deleteCurrentSession();

            Navigator.of(context).pushAndRemoveUntil(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const ChooseScreen(),
                transitionsBuilder: (_, animation, __, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 600),
              ),
                  (route) => false,
            );
          },
        icon: const Icon(Icons.logout),
        label: const Text("Log Out"),
        style: ElevatedButton.styleFrom(
          backgroundColor: _easterEggMode ? darkColorPrimary : Colors.red,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

