import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:optima/screens/beforeApp/choose_screen.dart';
import 'package:optima/screens/inApp/widgets/settings/profile_avatar.dart';
import 'package:optima/screens/inApp/widgets/abstract_screen.dart';
import 'package:optima/screens/inApp/widgets/settings/tiles.dart';
import 'package:optima/globals.dart';
import 'package:optima/services/local_storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _name = "John Doe";
  final String _email = "john.doe@email.com";
  bool _disableScroll = false;
  int _versionTapCount = 0;
  int _iconIndex = 0;
  bool _easterEggMode = false;

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
  void initState() { super.initState(); }

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
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: textHighlightedColor,
              foregroundColor: inAppForegroundColor,
              splashFactory: NoSplash.splashFactory,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              setState(() => _name = controller.text);
              Navigator.pop(context);
              // TODO: Save to Firestore
            },
            child: const Text(
              "Save",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  void _changePassword() {
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
            onPressed: () {
              Navigator.pop(context);
              // TODO: Re-authenticate & update password
            },
            child: const Text(
              "Change",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          )
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
                  ProfileAvatar(
                    name: _name,
                    email: _email,
                    onImageChanged: (file) {
                      // Optional: save file if needed
                    },
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
            onTap: () {},
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
