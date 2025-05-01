import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:optima/screens/beforeApp/choose_screen.dart';
import 'package:optima/screens/inApp/widgets/settings/buttons/text_button.dart';

import 'package:optima/screens/inApp/widgets/settings/profile_avatar.dart';
import 'package:optima/screens/inApp/widgets/abstract_screen.dart';
import 'package:optima/screens/inApp/widgets/settings/tiles.dart';

import 'package:optima/globals.dart';
import 'package:optima/services/cache/local_profile_cache.dart';

import 'package:optima/services/local_storage_service.dart';
import 'package:optima/services/cloud_storage_service.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _name = "";
  String _email = "";
  String? _photoUrl;

  final GlobalKey<ProfileAvatarState> _profileAvatarKey = GlobalKey<ProfileAvatarState>();

  int _versionTapCount = 0;
  int _iconIndex = 0;
  bool _disableScroll = false;
  bool _easterEggMode = false;
  bool _loading = true;

  bool isGoogleUser = false;

  final List<IconData> _easterEggIcons = [
    Icons.egg, Icons.auto_awesome, Icons.nature, Icons.cake,
    Icons.favorite, Icons.star, Icons.wb_sunny, Icons.local_florist, Icons.eco,
  ];

  bool notifications = true;
  bool jamieEnabled = true;
  bool locationAccess = false;
  bool wakeWordEnabled = true;
  bool jamieReminders = true;

  IconData _getNextEasterEggIcon() =>
      _easterEggIcons[_iconIndex++ % _easterEggIcons.length];


  @override
  void initState() {
    super.initState();
    _loadFromCacheThenFirestore();
    _checkIfGoogleUser();
  }

  @override
  void dispose() {
    _profileAvatarKey.currentState?.dispose();
    super.dispose();
  }




  Future<void> _checkIfGoogleUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      isGoogleUser = user.providerData.any((provider) => provider.providerId == 'google.com');
      setState(() {});
    }
  }

  Future<void> _loadUserProfile() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return;

    final cached = await LocalProfileCache.loadProfile();
    String cachedName = cached['name'] ?? '';
    String cachedEmail = cached['email'] ?? '';
    String? cachedPhotoUrl = cached['photoUrl'];

    setState(() {
      _name = cachedName;
      _email = cachedEmail;
      _photoUrl = cachedPhotoUrl;
      _loading = false;
    });

    final profile = await CloudStorageService().getUserProfile();
    if (profile != null) {
      final name = profile['name'] ?? cachedName;
      final email = authUser.email ?? cachedEmail;
      final photoUrl = profile['photoUrl'] ?? cachedPhotoUrl;

      await LocalProfileCache.saveProfile(name: name, email: email, photoUrl: photoUrl);

      if (name != _name || photoUrl != _photoUrl) {
        setState(() {
          _name = name;
          _email = email;
          _photoUrl = photoUrl;
        });
      }
    }
  }

  Future<void> _loadFromCacheThenFirestore() async {
    final cached = await LocalProfileCache.loadProfile();

    setState(() {
      _name = cached['name']!;
      _email = cached['email']!;
      _photoUrl = cached['photoUrl'];
    });

    await _loadUserProfile();
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
            borderColor: textDimColor,
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
            borderColor: textDimColor,
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
            borderColor: textDimColor,
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

          LocalProfileCache.clearProfile();
          FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
          await user.delete();

        } catch (e) {
          throw FirebaseAuthException(message: "Google reauthentication failed.", code: 'google-reauth-failed');
        }
      } else if (password != null && password.isNotEmpty) {
        final credential = EmailAuthProvider.credential(email: user.email!, password: password);
        await user.reauthenticateWithCredential(credential);

        LocalProfileCache.clearProfile();
        FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
        await user.delete();

      } else {
        throw FirebaseAuthException(message: "Password is required.", code: 'password-missing');
      }

      debugPrint("Account deleted successfully.");

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
    final controller = TextEditingController(text: _name);
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
              setState(() => _name = newName);
              CloudStorageService().saveUserProfile(name: newName, email: _email);
              LocalProfileCache.saveProfile(name: newName, email: _email, photoUrl: _photoUrl);

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
      builder: (_) => AlertDialog(
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
                  if (_loading)
                    const CircularProgressIndicator()
                  else
                    ProfileAvatar(
                        key: _profileAvatarKey,
                        name: _name,
                        email: _email,
                        photoUrl: _photoUrl, onImageChanged: (file) async {
                          final uploadedUrl = await uploadProfileImage(file);

                          if (uploadedUrl != null) {
                            setState(() => _photoUrl = uploadedUrl);

                            await CloudStorageService().saveUserProfile(
                              name: _name,
                              email: _email,
                              photoUrl: uploadedUrl,
                            );

                            await LocalProfileCache.saveProfile(
                              name: _name,
                              email: _email,
                              photoUrl: uploadedUrl,
                            );
                        }
                      }
                    ),
                  _buildSettingsContent(),
                  const SizedBox(height: 20),
                  _buildLogoutButton(),
                ],
              ),
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
            onChanged: (val) => setState(() => jamieEnabled = val),
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          ),
          Tiles.switchTile(
            icon: Icons.hearing,
            title: "Wake Word Detection",
            value: wakeWordEnabled,
            onChanged: (val) => setState(() => wakeWordEnabled = val),
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          ),
          Tiles.switchTile(
            icon: Icons.alarm,
            title: "Jamie Reminders",
            value: jamieReminders,
            onChanged: (val) => setState(() => jamieReminders = val),
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          ),
        ]),
        _buildSection("Notifications", [
          Tiles.switchTile(
            icon: Icons.notifications,
            title: "Push Notifications",
            value: notifications,
            onChanged: (val) => setState(() => notifications = val),
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          )
        ]),
        _buildSection("Privacy & Security", [
          Tiles.switchTile(
            icon: Icons.location_on,
            title: "Location Access",
            value: locationAccess,
            onChanged: (val) => setState(() => locationAccess = val),
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          ),
          Tiles.tile(
            context: context,
            icon: Icons.privacy_tip,
            title: "Privacy Settings",
            onTap: () {},
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          ),
          Tiles.tile(
            context: context,
            icon: Icons.devices,
            title: "Session Management",
            onTap: () {},
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          ),
        ]),
        _buildSection("Credits & Billing", [
          Tiles.tile(
            context: context,
            icon: Icons.credit_score,
            title: "My Credits",
            onTap: () {},
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
            onTap: () {},
            easterEggMode: _easterEggMode,
            getNextEasterEggIcon: _getNextEasterEggIcon,
          ),
          Tiles.tile(
            context: context,
            icon: Icons.mail_outline,
            title: "Contact Support",
            onTap: () {},
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
              Container(height: 2, width: double.infinity, color: textDimColor),
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
            await FirebaseAuth.instance.signOut();
            await LocalProfileCache.clearProfile();

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
          backgroundColor: _easterEggMode ? const Color(0xFF570987) : Colors.red,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }



}
