import 'dart:io';
import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/settings/buttons/text_button.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfileAvatar extends StatefulWidget {
  final String name;
  final String email;
  final File? initialImage;
  final void Function(File)? onImageChanged;

  const ProfileAvatar({
    super.key,
    required this.name,
    required this.email,
    this.initialImage,
    this.onImageChanged,
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  final CropController _cropController = CropController();

  @override
  void initState() {
    super.initState();
    _profileImage = widget.initialImage;
  }

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
                      if (isDone) return; // 🚫 Prevent duplicate execution
                      isDone = true;

                      final dir = await getTemporaryDirectory();
                      final path = '${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

                      if (_profileImage != null) {
                        try {
                          await _profileImage!.delete();
                        } catch (e) {
                          debugPrint("Error deleting old image: $e");
                        }
                      }

                      final file = await File(path).writeAsBytes(cropped);
                      if (!mounted) return;

                      setState(() => _profileImage = file);

                      // ✅ Pop safely once
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
                  if (!isDone) Navigator.pop(context); // ensure only one pop
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
                          const SnackBar(content: Text("Please select a valid crop area.")),
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

  @override
  Widget build(BuildContext context) {
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
                  color: textHighlightedColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: textColor, width: 1),
                ),
                child: Icon(Icons.edit, size: 16, color: textColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            Text(widget.name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 2),
            Text(widget.email, style: const TextStyle(fontSize: 14, color: Colors.white70)),
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
      errorBuilder: (_, __, ___) => Container(color: textHighlightedColor, width: 100, height: 100),
    );
  }
}