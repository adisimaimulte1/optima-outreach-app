import 'dart:convert';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/details/member_avatar.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:optima/screens/inApp/widgets/settings/buttons/text_button.dart';
import 'package:optima/screens/inApp/widgets/users/members_chat/event_avatar.dart';
import 'package:optima/screens/inApp/widgets/users/members_chat/member_card.dart';
import 'package:optima/services/cache/local_cache.dart';
import 'package:optima/services/livesync/event_live_sync.dart';
import 'package:optima/services/storage/cloud_storage_service.dart';
import 'package:permission_handler/permission_handler.dart';

class EventGroupInfoDialog extends StatefulWidget {
  final EventData event;
  final bool hasPermission;

  const EventGroupInfoDialog({
    super.key,
    required this.event,
    required this.hasPermission,
  });

  @override
  State<EventGroupInfoDialog> createState() => _EventGroupInfoDialogState();
}

class _EventGroupInfoDialogState extends State<EventGroupInfoDialog> {
  List<Member> _resolvedMembers = [];
  bool? _hasPermission;

  @override
  void initState() {
    super.initState();
    _hasPermission = widget.hasPermission;
    _loadResolvedMembers(widget.event);
  }

  Future<void> _loadResolvedMembers(EventData eventData) async {
    final rawMembers = eventData.eventMembers;
    final creatorEmail = eventData.createdBy.toLowerCase();
    final rawManagers = eventData.eventManagers;
    _hasPermission = eventData.hasPermission(FirebaseAuth.instance.currentUser!.email!);

    final List<Member> resolved = [];

    // Creator first
    final creatorPhoto = await LocalCache().getCachedMemberPhoto(creatorEmail);
    resolved.add(Member(
      id: creatorEmail,
      displayName: emailToNameMap![creatorEmail] ?? creatorEmail,
      resolvedPhoto: creatorPhoto,
      isPending: false,
    ));

    // Managers (excluding creator)
    for (final m in rawManagers) {
      if (m.toLowerCase() == creatorEmail) continue;
      final photo = await LocalCache().getCachedMemberPhoto(m);
      resolved.add(Member(
        id: m,
        displayName: emailToNameMap![m] ?? m,
        resolvedPhoto: photo,
        isPending: false,
      ));
    }

    // Members (may include pending)
    for (final m in rawMembers) {
      final email = (m['email'] ?? '').toLowerCase();
      final status = m['status'] ?? 'pending';
      final photo = await LocalCache().getCachedMemberPhoto(email);

      resolved.add(Member(
        id: email,
        displayName: emailToNameMap![email] ?? email,
        resolvedPhoto: photo,
        isPending: status != 'accepted',
      ));
    }

    resolved.sort((a, b) {
      if (a.isPending == b.isPending) return 0;
      return a.isPending ? 1 : -1; // pending last
    });

    // Apply immediately
    if (mounted) setState(() => _resolvedMembers = resolved);

    // Re-cache their statuses
    for (final m in rawMembers) {
      final email = m['email'];
      if (email != null) {
        await LocalCache().recacheMemberStatus(email, eventData.id!);
      }
    }

    // Refresh `isPending` status based on live global data
    if (mounted) {
      setState(() {
        _resolvedMembers = _resolvedMembers.map((member) {
          final isPending = getGlobalMemberStatus(member.id, eventData.id!) == 'pending';
          final isCreator = member.id.toLowerCase() == creatorEmail;

          return member.isPending == isPending
              ? member
              : Member(
            id: member.id,
            displayName: member.displayName,
            resolvedPhoto: member.resolvedPhoto,
            isPending: isCreator ? false : isPending,
          );
        }).toList();
      });
    }
  }

  String getGlobalMemberStatus(String email, String eventId) {
    final event = EventLiveSyncService().getNotifier(eventId)!.value;

    final managerStatus = event.eventManagers.contains(email);

    if (managerStatus) return 'accepted';

    final member = event.eventMembers.firstWhere(
          (m) => (m['email'] as String?)?.toLowerCase() == email.toLowerCase(),
      orElse: () => {'status': 'pending'},
    );

    return (member['status'] ?? 'pending').toString().toLowerCase();
  }




  @override
  Widget build(BuildContext context) {
    final notifier = EventLiveSyncService().getNotifier(widget.event.id!)!;
    return ValueListenableBuilder<EventData>(
      valueListenable: notifier,
      builder: (context, liveEvent, _) => _buildDialog(context, liveEvent),
    );
  }

  Widget _buildDialog(BuildContext context, EventData liveEvent) {
    final currentKeys = _resolvedMembers.map((m) {
      final status = getGlobalMemberStatus(m.id, liveEvent.id!);
      return "${m.id.toLowerCase()}|$status";
    }).toSet();

    final updatedKeys = liveEvent.eventMembers.map((m) {
      final email = (m['email'] ?? '').toLowerCase();
      final status = (m['status'] ?? 'pending').toLowerCase();
      return "$email|$status";
    }).toSet();

    if (currentKeys.length != updatedKeys.length || !currentKeys.containsAll(updatedKeys)) {
      _loadResolvedMembers(liveEvent);
    }

    final borderColor = _hasPermission! ? textHighlightedColor : textSecondaryHighlightedColor;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 50),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildDialogContent(liveEvent),
          _buildAvatar(liveEvent, borderColor),
        ],
      ),
    );
  }

  Widget _buildDialogContent(EventData liveEvent) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 420),
      child: Container(
        height: 400,
        margin: const EdgeInsets.only(top: 50),
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
        decoration: BoxDecoration(
          color: inAppForegroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                liveEvent.eventName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              height: 3,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: ListView.builder(
                  itemCount: _resolvedMembers.length,
                  itemBuilder: (context, index) {
                    final member = _resolvedMembers[index];
                    final isCreator = member.id.toLowerCase() == liveEvent.createdBy.toLowerCase();
                    final isTargetCreator = isCreator;

                    final currentUser = FirebaseAuth.instance.currentUser?.email?.toLowerCase();
                    final isCurrentUserCreator = currentUser == liveEvent.createdBy.toLowerCase();

                    final isCurrentManager = _hasPermission!;
                    final isTargetManager = liveEvent.eventManagers
                        .map((e) => e.toLowerCase())
                        .contains(member.id.toLowerCase());

                    final canManage = (isCurrentUserCreator || (isCurrentManager && !isTargetManager)) && !isTargetCreator;

                    return MemberCard(
                      member: member,
                      isCreator: isCreator,
                      isManager: isTargetManager,
                      onManage: canManage ? () => _showMemberActionsDialog(member, liveEvent) : null,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(EventData event, Color borderColor) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: inAppForegroundColor,
                shape: BoxShape.circle,
              ),
            ),
            EventAvatar(
              name: event.eventName,
              imageUrl: event.chatImage,
              size: 100,
              borderColor: borderColor,
              showEditIcon: _hasPermission!,
              onEditTap: () => _pickAndCropImage(),
            ),
          ],
        ),
      ),
    );
  }



  Future<void> _pickAndCropImage() async {
    final ImagePicker picker = ImagePicker();
    final CropController cropController = CropController();

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
                "To change this event’s avatar, allow gallery access in your device settings.",
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
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();

      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showCropDialog(bytes as Uint8List, cropController);
        }
      });
    } catch (e) {
      debugPrint("❌ Error picking image: $e");
    }
  }

  void _showCropDialog(Uint8List imageBytes, CropController controller) {
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
                    controller: controller,
                    image: imageBytes,
                    withCircleUi: true,
                    baseColor: inAppForegroundColor,
                    maskColor: inAppForegroundColor.withOpacity(0.5),
                    radius: 150,
                    onCropped: (cropped) async {
                      if (isDone) return;
                      isDone = true;

                      widget.event.chatImage = base64Encode(cropped);
                      final index = events.indexWhere((e) => e.id == widget.event.id);
                      if (index != -1) {
                        events[index] = events[index].copyWith(chatImage: widget.event.chatImage);

                        SchedulerBinding.instance.addPostFrameCallback((_) { setState(() {}); });
                      }

                      CloudStorageService().saveEvent(widget.event);

                      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
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
                      controller.crop();
                    } catch (e) {
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

  void _showMemberActionsDialog(Member member, EventData event) {
    final isTargetCreator = member.id.toLowerCase() == event.createdBy.toLowerCase();
    if (isTargetCreator) return; // 🚫 Creator can't be managed — just bail

    popupStackCount.value++;

    final isTargetManager = event.eventManagers
        .map((e) => e.toLowerCase())
        .contains(member.id.toLowerCase());
    final promoteLabel = isTargetManager ? "Demote" : "Promote";

    showModalBottomSheet(
      context: context,
      backgroundColor: inAppForegroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  member.displayName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  member.id,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButtonWithoutIcon(
                      label: promoteLabel,
                      onPressed: () {
                        Navigator.pop(context);
                        if (isTargetManager) {
                          _removeUserFromManagers(member.id, event.id!);
                        } else {
                          _promoteUserToManager(member.id, event.id!);
                        }
                      },
                      backgroundColor: textHighlightedColor,
                      foregroundColor: inAppForegroundColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      fontSize: 18,
                    ),
                    const SizedBox(width: 16),
                    TextButtonWithoutIcon(
                      label: "Remove",
                      onPressed: () {
                        Navigator.pop(context);
                        _removeUserFromEvent(member.id, event.id!);
                      },
                      backgroundColor: Colors.red,
                      foregroundColor: inAppForegroundColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      fontSize: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() => popupStackCount.value--);
  }



  Future<void> _removeUserFromEvent(String userEmail, String eventId) async {
    final loweredEmail = userEmail.toLowerCase();
    final eventIndex = events.indexWhere((e) => e.id == eventId);
    if (eventIndex == -1) return;

    final oldEvent = events[eventIndex];
    final isManager = oldEvent.eventManagers
        .map((e) => e.toLowerCase())
        .contains(loweredEmail);

    EventData newEvent;

    if (isManager) {
      final updatedManagers = List<String>.from(oldEvent.eventManagers)
        ..removeWhere((m) => m.toLowerCase() == loweredEmail);

      newEvent = oldEvent.copyWith(eventManagers: updatedManagers);
      await CloudStorageService().saveEvent(newEvent);
    } else {
      final updatedMembers = List<Map<String, dynamic>>.from(oldEvent.eventMembers)
        ..removeWhere((m) => (m['email'] as String?)?.toLowerCase() == loweredEmail);

      newEvent = oldEvent.copyWith(eventMembers: updatedMembers);
      await CloudStorageService().removeMemberFromEvent(event: newEvent, email: loweredEmail);
    }

    events[eventIndex] = newEvent;

    if (mounted) {
      setState(() {
        _resolvedMembers.removeWhere((m) => m.id.toLowerCase() == loweredEmail);
      });
    }
  }

  Future<void> _promoteUserToManager(String userEmail, String eventId) async {
    final eventIndex = events.indexWhere((e) => e.id == eventId);
    if (eventIndex == -1) return;

    final oldEvent = events[eventIndex];
    final loweredEmail = userEmail.toLowerCase();

    // Add to managers
    final updatedManagers = Set<String>.from(oldEvent.eventManagers)..add(loweredEmail);

    // Remove from members
    final updatedMembers = List<Map<String, dynamic>>.from(oldEvent.eventMembers)
      ..removeWhere((m) => (m['email'] as String?)?.toLowerCase() == loweredEmail);

    // Save new event
    final newEvent = oldEvent.copyWith(
      eventManagers: updatedManagers.toList(),
      eventMembers: updatedMembers,
    );

    events[eventIndex] = newEvent;

    if (mounted) {
      setState(() {
        _resolvedMembers.removeWhere((m) => m.id.toLowerCase() == loweredEmail);
      });
    }

    await CloudStorageService().removeMemberFromEvent(event: newEvent, email: loweredEmail);
    await CloudStorageService().saveEvent(newEvent);

    events[eventIndex] = newEvent;
  }

  Future<void> _removeUserFromManagers(String userEmail, String eventId) async {
    debugPrint("Removing $userEmail from managers of $eventId");

    final eventIndex = events.indexWhere((e) => e.id == eventId);
    if (eventIndex == -1) return;

    debugPrint("eventIndex: $eventIndex");
    final oldEvent = events[eventIndex];
    final loweredEmail = userEmail.toLowerCase();

    final updatedManagers = List<String>.from(oldEvent.eventManagers)
      ..removeWhere((m) => m.toLowerCase() == loweredEmail);

    final updatedMembers = List<Map<String, dynamic>>.from(oldEvent.eventMembers)
      ..add({'email': loweredEmail, 'status': 'accepted'});

    final newEvent = oldEvent.copyWith(
      eventManagers: updatedManagers,
      eventMembers: updatedMembers,
    );

    await CloudStorageService().saveEvent(newEvent);
    events[eventIndex] = newEvent;

    if (mounted) {
      final event = EventLiveSyncService().getNotifier(eventId)!.value;
      _loadResolvedMembers(event);
    }

  }
}
