import 'dart:io';
import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/abstract_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

enum AppThemeMode { system, light, dark }
AppThemeMode selectedTheme = AppThemeMode.system;



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
    Icons.favorite, Icons.star, Icons.wb_sunny, Icons.local_florist,
    Icons.eco
  ];


  final CropController _cropController = CropController();
  final ImagePicker _picker = ImagePicker();

  File? _profileImage;


  bool darkMode = isDarkModeNotifier.value;
  bool notifications = true;
  bool jamieEnabled = true;
  bool locationAccess = false;
  bool wakeWordEnabled = true;
  bool jamieReminders = true;


  Future<void> _pickImage() async {
    final status = await Permission.photos.request();

    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gallery permission is required.")),
        );
      }
      return;
    }

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // already compressed
        maxWidth: 1024,   // keep dimensions reasonable
        maxHeight: 1024,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (mounted) _showCropDialog(bytes);
    } catch (e) {
      debugPrint("❌ Error picking image: $e");
    }
  }

  void _showCropDialog(Uint8List imageBytes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          bool isCropping = false;

          return AlertDialog(
            backgroundColor: const Color(0xFF24324A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.all(16),
            content: SizedBox(
              width: 300,
              height: 300,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Crop(
                    controller: _cropController,
                    image: imageBytes,
                    withCircleUi: true,
                    baseColor: const Color(0xFF24324A),
                    maskColor: const Color(0xFF24324A).withOpacity(0.5),
                    radius: 150,
                    onCropped: (cropped) async {
                      final dir = await getTemporaryDirectory();
                      final path = '${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
                      final file = await File(path).writeAsBytes(cropped);

                      if (!mounted) return;
                      setState(() => _profileImage = file);
                      Navigator.pop(context);
                    },
                  ),
                  if (isCropping)
                    const CircularProgressIndicator(color: Color(0xFFFFC62D)),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.end,
            actionsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  splashFactory: NoSplash.splashFactory,
                  textStyle: const TextStyle(fontSize: 15),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC62D),
                  foregroundColor: Colors.black,
                  splashFactory: NoSplash.splashFactory,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  try {
                    setDialogState(() => isCropping = true);
                    _cropController.crop();
                  } catch (e) {
                    debugPrint("❌ Crop failed: $e");
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please select a valid crop area.")),
                      );
                      setDialogState(() => isCropping = false);
                    }
                  }
                },
                child: const Text("Crop"),
              ),
            ],
          );
        },
      ),
    );
  }



  void _editName() {
    final controller = TextEditingController(text: _name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF24324A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Edit Name", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: "Name",
            labelStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.black12,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actionsPadding: const EdgeInsets.only(bottom: 8, right: 12),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFFFC62D),
              foregroundColor: Colors.black,
              splashFactory: NoSplash.splashFactory,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              setState(() => _name = controller.text);
              Navigator.pop(context);
              // TODO: Save to Firestore
            },
            child: const Text("Save"),
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
        backgroundColor: const Color(0xFF24324A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Change Password", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Current Password",
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.black12,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "New Password",
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.black12,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.only(bottom: 8, right: 12),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFFFC62D),
              foregroundColor: Colors.black,
              splashFactory: NoSplash.splashFactory,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              // TODO: Re-authenticate & update password
            },
            child: const Text("Change"),
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
              physics: _disableScroll ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30),
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  _buildProfileHeader(),
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


  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 5),
                ),
                child: ClipOval(
                  child: _profileImage != null
                      ? Image.file(
                    _profileImage!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => _fallbackAvatar(),
                  )
                      : _fallbackAvatar(),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC62D),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: const Icon(
                  Icons.edit,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            Text(
              _name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _email,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _fallbackAvatar() {
    return Image.network(
      "https://i.pravatar.cc/150?img=3",
      width: 100,
      height: 100,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) =>
      progress == null ? child : const CircularProgressIndicator(),
      errorBuilder: (_, __, ___) => Container(
        color: Color(0xFFFFC62D),
        width: 100,
        height: 100,
      ),
    );
  }

  Widget _buildSettingsContent() {
    _iconIndex = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection("Account", [
          _tile(Icons.person, "Edit Name", onTap: _editName),
          _tile(Icons.lock_outline, "Change Password", onTap: _changePassword),
          _tile(Icons.delete_outline, "Delete Account", onTap: () {
            // TODO: Handle account deletion
          }),
        ]),
        _buildSection("Appearance", [
          _themeDropdownTile(),
        ]),
        _buildSection("Jamie Assistant", [
          _switchTile(Icons.smart_toy, "Enable Jamie", jamieEnabled, (val) => setState(() => jamieEnabled = val)),
          _switchTile(Icons.hearing, "Wake Word Detection", wakeWordEnabled, (val) => setState(() => wakeWordEnabled = val)),
          _switchTile(Icons.alarm, "Jamie Reminders", jamieReminders, (val) => setState(() => jamieReminders = val)),
        ]),
        _buildSection("Notifications", [
          _switchTile(Icons.notifications, "Push Notifications", notifications, (val) => setState(() => notifications = val)),
        ]),
        _buildSection("Privacy & Security", [
          _switchTile(Icons.location_on, "Location Access", locationAccess, (val) => setState(() => locationAccess = val)),
          _tile(Icons.privacy_tip, "Privacy Settings", onTap: () {}),
          _tile(Icons.devices, "Session Management", onTap: () {}),
        ]),
        _buildSection("Credits & Billing", [
          _tile(Icons.credit_score, "My Credits", onTap: () {}),
          _tile(Icons.subscriptions, "Upgrade Plan", onTap: () {}),
          _tile(Icons.smart_display, "Watch Ads for Credits", onTap: () {}),
        ]),
        _buildSection("Help & About", [
          _tile(Icons.help_outline, "Help & FAQ", onTap: () {}),
          _tile(Icons.mail_outline, "Contact Support", onTap: () {}),
          _tile(Icons.info_outline, "App Version 1.0.0", showArrow: false, onTap: () {
            _versionTapCount++;
            if (_versionTapCount >= 3) {
              setState(() {
                _easterEggMode = !_easterEggMode;
                _versionTapCount = 0;
              });
            }
          }),

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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 2,
                width: double.infinity,
                color: Colors.white12,
              ),
            ],
          ),
        ),
        Column(
          children: tiles.map((tile) => Padding(
            padding: const EdgeInsets.only(bottom: 2), // tighter spacing between buttons
            child: tile,
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () {
          // TODO: Firebase logout
        },
        icon: const Icon(Icons.logout),
        label: const Text("Log Out"),
        style: ElevatedButton.styleFrom(
          backgroundColor: _easterEggMode ? Color(0xFF750F75) : Colors.redAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }





  Widget _tile(IconData icon, String title, {VoidCallback? onTap, bool showArrow = true}) {
    return SizedBox(
      height: 44,
      child: ListTile(
        visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
        dense: true,
        minLeadingWidth: 0,
        horizontalTitleGap: 10,
        leading: Icon(
          _easterEggMode ? _easterEggIcons[_iconIndex++ % _easterEggIcons.length] : icon,
          color: const Color(0xFFFFC62D),
          size: 20,
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
        trailing: showArrow ? const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white70) : null,
        onTap: onTap,
      ),
    );
  }

  Widget _switchTile(IconData icon, String title, bool value, ValueChanged<bool> onChanged) {
    return SizedBox(
      height: 44, // Match tile height
      child: ListTile(
        visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
        dense: true,
        minLeadingWidth: 0,
        horizontalTitleGap: 10,
        leading: Icon(
          _easterEggMode ? _easterEggIcons[_iconIndex++ % _easterEggIcons.length] : icon,
          color: const Color(0xFFFFC62D),
          size: 20,
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFFFFC62D),
          activeTrackColor: Colors.yellow.shade50,
          inactiveThumbColor: Colors.grey,
          inactiveTrackColor: Colors.grey.shade800,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget _themeDropdownTile() {
    const iconColor = Color(0xFFFFC62D);
    const dropdownBgColor = Color(0xFF24324A);

    return SizedBox(
      height: 44,
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
        minLeadingWidth: 0,
        horizontalTitleGap: 10,
        leading: Icon(
          _easterEggMode ? _easterEggIcons[_iconIndex++ % _easterEggIcons.length] : Icons.color_lens,
          color: const Color(0xFFFFC62D),
          size: 20,
        ),
        title: const Text(
          "App Theme",
          style: TextStyle(color: Colors.white, fontSize: 15),
        ),
        trailing: DropdownButtonHideUnderline(
          child: DropdownButton2<AppThemeMode>(
            isExpanded: false,
            value: selectedTheme,
            onChanged: (mode) {
              if (mode != null) {
                setState(() => selectedTheme = mode);
              }
            },
            items: const [
              DropdownMenuItem(
                value: AppThemeMode.system,
                child: Text("System", style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem(
                value: AppThemeMode.light,
                child: Text("Light", style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem(
                value: AppThemeMode.dark,
                child: Text("Dark", style: TextStyle(color: Colors.white)),
              ),
            ],
            buttonStyleData: const ButtonStyleData(
              height: 36,
              padding: EdgeInsets.symmetric(horizontal: 0),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
            iconStyleData: const IconStyleData(
              icon: Icon(Icons.arrow_drop_down, color: Colors.white70),
            ),
            dropdownStyleData: DropdownStyleData(
              maxHeight: 150,
              decoration: BoxDecoration(
                color: dropdownBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
