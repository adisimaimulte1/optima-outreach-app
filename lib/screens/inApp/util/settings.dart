import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';

import 'package:optima/screens/beforeApp/choose_screen.dart';
import 'package:optima/screens/inApp/widgets/settings/buttons/text_button.dart';

import 'package:optima/screens/inApp/widgets/settings/profile_avatar.dart';
import 'package:optima/screens/inApp/widgets/abstract_screen.dart';
import 'package:optima/screens/inApp/widgets/settings/tiles.dart';

import 'package:optima/globals.dart';
import 'package:optima/services/cache/local_cache.dart';

import 'package:optima/services/local_storage_service.dart';
import 'package:optima/services/cloud_storage_service.dart';
import 'package:optima/services/notifications/push_notification_service.dart';
import 'package:optima/services/sessions/session_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';


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

  void _updatePermissions() {
    setState(() {});
  }





  Future<String?> uploadProfileImage(File file) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return null;
      }

      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'photoUrl': base64Image,
      }, SetOptions(merge: true));

      return base64Image;
    } catch (e) { return null; }
  }




  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    // Show the confirmation dialog for account deletion
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: inAppForegroundColor,
        title: Text(
          "Delete Account",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center, // Center the title
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min, // Make the column take only the needed space
          children: [
            Text(
              "Deleting your account will remove all your data.",
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                height: 1.5, // Increase line height for better readability
              ),
              textAlign: TextAlign.center, // Center align the content text
            ),
          ],
        ),
        actions: [
          // Cancel Button
          TextButtonWithoutIcon(
            label: "Cancel",
            onPressed: () {
              Navigator.pop(context, false); // Cancel
            },
            foregroundColor: Colors.white70,
            fontSize: 17,
            borderColor: Colors.white70,
            borderWidth: 1.2,
          ),
          // Delete Button
          TextButtonWithoutIcon(
            label: "Delete",
            onPressed: () {
              Navigator.pop(context, true); // Confirm delete
            },
            backgroundColor: Colors.red,
            foregroundColor: inAppForegroundColor,
            fontSize: 17,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      if (isGoogleUser) {
        await _promptGoogleConfirmation(context);
      } else {
        await _promptForPassword(context);
      }
    }
  }

  Future<void> _promptForPassword(BuildContext context) async {
    final passwordController = TextEditingController();
    String? password;

    await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: inAppForegroundColor,
        title: Text(
          "Enter your password to confirm.",
          style: TextStyle(color: textColor),
        ),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          style: TextStyle(color: textColor),
          decoration: standardInputDecoration(hint: "", label: "Password"),
        ),
        actions: [
          // Cancel Button
          TextButtonWithoutIcon(
            label: "Cancel",
            onPressed: () {
              Navigator.pop(context);  // Close dialog without submitting
            },
            foregroundColor: Colors.white70,
            fontSize: 17,
            borderColor: Colors.white70,
            borderWidth: 1.2,
          ),
          // Submit Button
          TextButtonWithoutIcon(
            label: "Submit",
            onPressed: () async {
              password = passwordController.text.trim();
              if (password != null && password!.isNotEmpty) {
                await _deleteAccount(password!, context);
              } else {
                // Show snackbar if password is empty
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: textHighlightedColor,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    elevation: 6,
                    duration: const Duration(seconds: 1),
                    content: Center(
                      child: Text(
                        "Password cannot be empty.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: inAppForegroundColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                );
              }
              Navigator.pop(context);  // Close the dialog after submitting
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

  Future<void> _promptGoogleConfirmation(BuildContext context) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: inAppForegroundColor,
        title: Text(
          "Are you sure you want to delete your account?",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center, // Center the title
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            "This action is irreversible.",
            style: TextStyle(color: textColor, fontSize: 16, height: 1.5),
            textAlign: TextAlign.center, // Center align the content text
          ),
        ),
        actions: [
          TextButtonWithoutIcon(
            label: "Cancel",
            onPressed: () {
              Navigator.pop(context);
            },
            foregroundColor: Colors.white70,
            fontSize: 17,
            borderColor: Colors.white70,
            borderWidth: 1.2,
          ),
          TextButtonWithoutIcon(
            label: "Delete",
            onPressed: () async {
              _deleteAccount('', context);
            },
            backgroundColor: Colors.red,
            foregroundColor: inAppForegroundColor,
            fontSize: 17,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(String? password, BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw FirebaseAuthException(message: "No user is logged in.", code: 'user-not-found');
      }

      if (isGoogleUser) {
        try {
          final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
          final googleAuth = await googleUser?.authentication;

          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth?.accessToken,
            idToken: googleAuth?.idToken,
          );

          await user.reauthenticateWithCredential(credential!);
          LocalCache().deleteAll();

        } catch (e) {
          throw FirebaseAuthException(message: "Google reauthentication failed.", code: 'google-reauth-failed');
        }
      } else if (password != null && password.isNotEmpty) {
        final credential = EmailAuthProvider.credential(email: user.email!, password: password);

        await user.reauthenticateWithCredential(credential);
        LocalCache().deleteAll();

      } else {
        throw FirebaseAuthException(message: "Password is required.", code: 'password-missing');
      }

      await Future.delayed(Duration(milliseconds: 100));

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
    } on FirebaseAuthException catch (e) {
      // Handle error and show the error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 6,
          duration: const Duration(seconds: 2),
          content: Center(
            child: Text(
              "Error: ${e.message}",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: inAppForegroundColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        elevation: 6,
        duration: const Duration(seconds: 2),
        content: Center(
          child: Text(
            "Account deleted successfully.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: inAppForegroundColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }






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

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;

    if (isGoogleUser) {
      _showGoogleSignInPopUp();
    } else {
      _showChangePasswordDialog(user!);
    }
  }

  void _showGoogleSignInPopUp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: inAppForegroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Change Password",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            "You cannot change the password because you signed in using Google. Please manage your password directly through Google.",
            style: TextStyle(color: textColor, fontSize: 16, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          TextButtonWithoutIcon(
            label: "OK",
            onPressed: () {
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

  void _showChangePasswordDialog(User user) {
    final oldController = TextEditingController();
    final newController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
        backgroundColor: inAppForegroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Change Password", style: TextStyle(color: textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldController,
              obscureText: true,
              style: TextStyle(color: textColor),
              decoration: standardInputDecoration(hint: "", label: "Current Password"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newController,
              obscureText: true,
              style: TextStyle(color: textColor),
              decoration: standardInputDecoration(hint: "", label: "New Password"),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.only(bottom: 8, right: 12),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: textHighlightedColor,
              foregroundColor: inAppForegroundColor,
              splashFactory: NoSplash.splashFactory,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final oldPassword = oldController.text.trim();
              final newPassword = newController.text.trim();

              if (oldPassword.isEmpty || newPassword.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: textHighlightedColor,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    elevation: 6,
                    duration: const Duration(seconds: 1),
                    content: Center(
                      child: Text(
                        "Both fields are required.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: inAppForegroundColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                );
                return;
              }

              try {
                final credential = EmailAuthProvider.credential(
                  email: user.email!,
                  password: oldPassword,
                );

                await user.reauthenticateWithCredential(credential);
                await user.updatePassword(newPassword);
                await user.reload();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    elevation: 6,
                    duration: const Duration(seconds: 1),
                    content: Center(
                      child: Text(
                        "Password changed successfully!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: inAppForegroundColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                );
              } on FirebaseAuthException catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    elevation: 6,
                    duration: const Duration(seconds: 1),
                    content: Center(
                      child: Text(
                        "Error: ${e.message}",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: inAppForegroundColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                );
              }
            },
            child: const Text(
              "Change",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
            onTap: _changePassword,
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          ),
          Tiles.tile(
            context: context,
            icon: Icons.delete_outline,
            title: "Delete Account",
            onTap: () async {
              await _showDeleteConfirmationDialog(context);
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
              }
            },
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          ),
          Tiles.tile(
            context: context,
            icon: Icons.privacy_tip,
            title: "Privacy Settings",
            onTap: _showPrivacySettingsDialog,
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          ),
          Tiles.tile(
            context: context,
            icon: Icons.devices,
            title: "Session Management",
            onTap: _showSessionManagementDialog,
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          ),
        ]),
        _buildSection("Credits & Billing", [
          Tiles.tile(
            context: context,
            icon: Icons.credit_score,
            title: "My Credits",
            onTap: _showCreditBalanceDialog,
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          ),
          Tiles.tile(
            context: context,
            icon: Icons.subscriptions,
            title: "Upgrade Plan",
            onTap: () {},
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          ),
          Tiles.tile(
            context: context,
            icon: Icons.smart_display,
            title: "Watch Ads for Credits",
            onTap: () {},
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          ),
        ]),
        _buildSection("Help & About", [
          Tiles.tile(
            context: context,
            icon: Icons.help_outline,
            title: "Help & FAQ",
            onTap: _showHelpDialog,
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          ),
          Tiles.tile(
            context: context,
            icon: Icons.mail_outline,
            title: "Contact Support",
            onTap: _contactSupport,
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          ),
          Tiles.tile(
            context: context,
            icon: Icons.info_outline,
            title: "App Version 1.0.0",
            showArrow: false,
            onTap: () {
              _versionTapCount++;
              if (_versionTapCount >= 3) {
                setState(() {
                  _easterEggMode = !_easterEggMode;
                  _versionTapCount = 0;
                });
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



  String _formatDateTime(DateTime time) {
    final date = "${_monthName(time.month)} ${time.day}";
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$date, $hour:$minute";
  }

  String _monthName(int month) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month - 1];
  }

  Widget _privacyItem({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: textHighlightedColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: textColor, fontSize: 14.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }



  void _showPrivacySettingsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: inAppForegroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Privacy Settings",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Container(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Here's how Optima protects your data:",
                style: TextStyle(color: textColor, fontSize: 15.5),
              ),
              const SizedBox(height: 14),

              _privacyItem(
                icon: Icons.lock_outline,
                text: "All your data is encrypted and stored securely in Firebase.",
              ),
              _privacyItem(
                icon: Icons.visibility_off_outlined,
                text: "Only you and other members can view your events and settings. No one else has access.",
              ),
              _privacyItem(
                icon: Icons.place_outlined,
                text: "Location access is optional and used only to optimize event planning.",
              ),
              _privacyItem(
                icon: Icons.mic_none_outlined,
                text: "Your voice is never stored. It's used only as input for your secure AI conversation.",
              ),
              _privacyItem(
                icon: Icons.shield_outlined,
                text: "Crash logs and analytics are only used to improve stability — never for profiling.",
              ),

              const SizedBox(height: 14),
              Center(
                child: Text(
                  "For more details, refer to our full Privacy Policy.",
                  style: TextStyle(
                    color: textColor.withOpacity(0.6),
                    fontSize: 13.5,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButtonWithoutIcon(
            label: "Close",
            onPressed: () => Navigator.pop(context),
            foregroundColor: Colors.white70,
            fontSize: 17,
            borderColor: Colors.white70,
            borderWidth: 1.2,
          ),
        ],
      ),
    );
  }

  void _showSessionManagementDialog() async {
    final sessions = await SessionService().getSessions();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: inAppForegroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Active Sessions",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: 420,
          height: 150,
          child: sessions.isEmpty
              ? Center(
            child: Text(
              "No active sessions found.",
              style: TextStyle(color: textColor),
              textAlign: TextAlign.center,
            ),
          )
              : ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (_, index) {
              final session = sessions[index];
              final Timestamp last = session['lastActive'];
              final formattedTime = _formatDateTime(
                DateTime.fromMillisecondsSinceEpoch(last.millisecondsSinceEpoch),
              );
              final isCurrent = session['isCurrent'];

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: isCurrent ? inAppForegroundColor : Colors.transparent,
                  border: Border.all(
                    color: isCurrent ? textHighlightedColor : Colors.white70,
                    width: 1.4,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child:
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Device name (takes full remaining width)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session['device'],
                            style: TextStyle(
                              color: isCurrent ? textColor : Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Last active: $formattedTime",
                            style: TextStyle(
                              color: isCurrent ? textColor : Colors.white54,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          if (isCurrent)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "This device",
                                style: TextStyle(
                                  color: textHighlightedColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Logout button
                    if (!isCurrent)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 8),
                        child: IconButton(
                          icon: const Icon(Icons.logout, color: Colors.red),
                          onPressed: () async {
                            await SessionService().deleteSession(session['id']);
                            Navigator.pop(context);
                            _showSessionManagementDialog();
                          },
                          style: ButtonStyle(
                            overlayColor: MaterialStateProperty.all(Colors.transparent),
                            splashFactory: NoSplash.splashFactory,
                            padding: MaterialStateProperty.all(EdgeInsets.zero),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                  ],
                ),

              );
            },
          ),
        ),
        actions: [
          if (sessions.length > 1)
            TextButtonWithoutIcon(
              label: "Log Out Others",
              onPressed: () async {
                await SessionService().deleteAllOtherSessions();
                Navigator.pop(context);
                _showSessionManagementDialog(); // Refresh
              },
              backgroundColor: Colors.red,
              foregroundColor: inAppForegroundColor,
              fontSize: 17,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          TextButtonWithoutIcon(
            label: "Close",
            onPressed: () => Navigator.pop(context),
            foregroundColor: Colors.white70,
            fontSize: 17,
            borderColor: Colors.white70,
            borderWidth: 1.2,
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: inAppForegroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Help & FAQ",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: 420,
          height: 400,
          child: Scrollbar(
            thumbVisibility: true,
            thickness: 4,
            radius: const Radius.circular(6),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white70, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _HelpItem(
                      question: "How do I create an event?",
                      answer: "Tap the '+' button on the dashboard, then follow the guided form.",
                    ),
                    _HelpItem(
                      question: "What is Jamie?",
                      answer: "Jamie is your built-in outreach assistant that can help plan and optimize events using AI.",
                    ),
                    _HelpItem(
                      question: "Can I access Optima on multiple devices?",
                      answer: "Yes. Each session is tracked and manageable under Privacy & Security.",
                    ),
                    _HelpItem(
                      question: "Where is my data stored?",
                      answer: "All data is encrypted and stored securely in Firebase, managed by your account.",
                    ),
                    _HelpItem(
                      question: "What is an Optima credit?",
                      answer: "Credits let you use advanced AI features. You can earn them by watching ads or upgrading.",
                    ),
                    _HelpItem(
                      question: "How do I enable Jamie reminders?",
                      answer: "In Settings > Jamie Assistant, toggle the 'Jamie Reminders' switch.",
                    ),
                    _HelpItem(
                      question: "Is my data private?",
                      answer: "Yes. Only you can access your account data. Optima does not sell or share user data.",
                    ),
                    _HelpItem(
                      question: "How do I contact support?",
                      answer: "Use the 'Contact Support' button in Settings to email us directly.",
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButtonWithoutIcon(
            label: "Close",
            onPressed: () => Navigator.pop(context),
            foregroundColor: Colors.white70,
            fontSize: 17,
            borderColor: Colors.white70,
            borderWidth: 1.2,
          ),
        ],
      ),
    );
  }

  void _contactSupport() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: inAppForegroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Contact Support",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          "This will open your email app to send a message to our support team. ",
          style: TextStyle(color: textColor, fontSize: 15.5, height: 1.4),
          textAlign: TextAlign.center,
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
            label: "Continue",
            onPressed: () async {
              Navigator.pop(context); // Close the dialog

              final uriString =
                  'mailto:adrian.c.contras@gmail.com?subject=Optima%20Support&body=Hi%20Optima team,%0A%0A';
              await launchUrl(Uri.parse(uriString), mode: LaunchMode.externalApplication);
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



  void _showCreditBalanceDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => ValueListenableBuilder<int>(
        valueListenable: creditNotifier,
        builder: (context, currentCredits, _) {
          return AlertDialog(
            backgroundColor: inAppForegroundColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            titlePadding: const EdgeInsets.only(top: 24),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            title: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: Icon(
                    credits == 1203 ? Icons.auto_awesome : (currentCredits == 0 ? Icons.credit_card_off : Icons.credit_score),
                    key: ValueKey(
                      currentCredits == 1203
                          ? 'easterEgg'
                          : (currentCredits == 0 ? 'zero' : 'normal'),
                    ),
                    size: 48,
                    color: currentCredits == 0 ? Colors.red : textHighlightedColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Your Balance",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 260, maxWidth: 420),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                switchInCurve: Curves.easeOutExpo,
                switchOutCurve: Curves.easeInExpo,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: Text(
                  "$currentCredits Credits",
                  key: ValueKey(currentCredits),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              TextButtonWithoutIcon(
                label: "Close",
                onPressed: () => Navigator.pop(context),
                foregroundColor: Colors.white70,
                borderColor: Colors.white70,
                fontSize: 16,
                borderWidth: 1,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              ),
              TextButtonWithoutIcon(
                label: "Get More",
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Navigate to Upgrade Plan or Watch Ads screen
                },
                backgroundColor: textHighlightedColor,
                foregroundColor: inAppForegroundColor,
                fontSize: 16,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              ),
            ],
          );
        },
      ),
    );
  }
}



class _HelpItem extends StatelessWidget {
  final String question;
  final String answer;
  const _HelpItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: TextStyle(
              fontSize: 14.5,
              color: textColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

