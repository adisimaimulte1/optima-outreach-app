import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/settings/buttons/text_button.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfileAvatar extends StatefulWidget {
  final VoidCallback? onEditTapped;


  const ProfileAvatar({
    super.key,
    this.onEditTapped,
  });

  @override
  State<ProfileAvatar> createState() => ProfileAvatarState();
}

class ProfileAvatarState extends State<ProfileAvatar> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  final CropController _cropController = CropController();

  Future<void> _pickImage() async {
    var status = await Permission.photos.request();

    if (!status.isGranted) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: inAppForegroundColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              "Gallery Permission Required",
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            content: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "To change your profile picture, allow gallery access in your device settings.",
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
                borderColor: textDimColor,
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
      return;
    }

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showCropDialog(bytes);
      });
    } catch (e) {
      debugPrint("❌ Error picking image: $e");
    }
  }

  void _showCropDialog(Uint8List imageBytes) {
    bool isDone = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: inAppForegroundColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.all(16),
            content: SizedBox(
              width: 290,
              height: 290,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Crop(
                    controller: _cropController,
                    image: imageBytes,
                    withCircleUi: true,
                    baseColor: inAppForegroundColor,
                    maskColor: inAppForegroundColor.withOpacity(0.5),
                    radius: 150,
                    onCropped: (cropped) async {
                      if (isDone) return;
                      isDone = true;

                      final dir = await getTemporaryDirectory();
                      final path = '${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

                      final file = await File(path).writeAsBytes(cropped);
                      if (!mounted) return;

                      setState(() => _profileImage = file);
                      _uploadToFirebase(file);

                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.end,
            actionsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            actions: [
              TextButtonWithoutIcon(
                label: "Cancel",
                onPressed: () {
                  if (!isDone) Navigator.pop(context);
                },
                foregroundColor: Colors.white70,
                fontSize: 17,
                borderColor: textDimColor,
                borderWidth: 1.2,
              ),
              TextButtonWithoutIcon(
                label: "Crop",
                onPressed: () {
                  if (!isDone) {
                    try {
                      _cropController.crop();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: textHighlightedColor,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            elevation: 6,
                            duration: const Duration(seconds: 1),
                            content: Center(
                              child: Text(
                                "Please select a valid crop area.",
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
                    }
                  }
                },
                backgroundColor: textHighlightedColor,
                foregroundColor: inAppForegroundColor,
                fontSize: 17,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _uploadToFirebase(File file) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'photoUrl': base64Image}, SetOptions(merge: true));

      photoUrl = base64Image;
    } catch (e) {
      debugPrint("❌ Failed to upload profile image: $e");
    }
  }



  @override
  Widget build(BuildContext context) {
    super.build(context);

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
                  border: Border.all(color: textColor, width: 5),
                ),
                child: ClipOval(
                  child: _buildAvatarImage(),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: textHighlightedColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: textColor, width: 1),
                ),
                child: const Icon(Icons.edit, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            Text(name.isEmpty ? "Unnamed User" : name,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 2),
            Text(email.isEmpty ? "No Email" : email,
                style: const TextStyle(fontSize: 14, color: Colors.white70)),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildAvatarImage() {
    if (_profileImage != null) {
      return Image.file(
        _profileImage!,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _fallbackAvatar(),
      );
    } else if (photoUrl != null && photoUrl!.isNotEmpty) {
      try {
        final Uint8List imageBytes = base64Decode(photoUrl!);
        return Image.memory(
          imageBytes,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _fallbackAvatar(),
        );
      } catch (_) {
        return _fallbackAvatar();
      }
    } else {
      return _fallbackAvatar();
    }
  }

  Widget _fallbackAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: textHighlightedColor.withOpacity(0.7),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, size: 50, color: Colors.white),
    );
  }
}
