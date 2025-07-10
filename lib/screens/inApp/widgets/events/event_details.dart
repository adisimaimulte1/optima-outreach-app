import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/details/collaborators_block.dart';
import 'package:optima/screens/inApp/widgets/events/details/member_avatar.dart';
import 'package:optima/screens/inApp/widgets/events/details/location_block.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:optima/services/cache/local_cache.dart';
import 'package:optima/services/livesync/event_live_sync.dart';
import 'package:optima/services/storage/cloud_storage_service.dart';

class EventDetails extends StatefulWidget {
  final String eventId;
  final bool publicDisplay;
  final void Function(EventData newEvent)? onStatusChange;

  const EventDetails({
    super.key,
    required this.eventId,
    this.onStatusChange,
    this.publicDisplay = false,
  });

  @override
  State<EventDetails> createState() => _EventDetailsState();
}

class _EventDetailsState extends State<EventDetails> {
  late String selectedStatus;

  List<Member> _resolvedMembers = [];
  bool hasPermission = true;
  Color color = textHighlightedColor;

  @override
  void initState() {
    super.initState();
    popupStackCount.value++;

    EventData eventData;
    if (widget.publicDisplay) {
      eventData = upcomingPublicEvents.firstWhere((e) => e.id == widget.eventId);
    } else { eventData = EventLiveSyncService().getNotifier(widget.eventId)!.value; }

    selectedStatus = eventData.status;
    _loadResolvedMembers(eventData);
  }




  Future<void> _loadResolvedMembers(EventData eventData) async {
    final rawMembers = eventData.eventMembers;
    final rawManagers = eventData.eventManagers;
    final creatorEmail = eventData.createdBy.toLowerCase();

    final List<Member> resolved = [];

    // creator first
    final creatorPhoto = await LocalCache().getCachedMemberPhoto(creatorEmail);
    resolved.add(Member(
      id: creatorEmail,
      displayName: emailToNameMap![creatorEmail] ?? creatorEmail,
      resolvedPhoto: creatorPhoto,
      isPending: false,
    ));

    // managers (excluding creator)
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

    // mebers (may include pending)
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

    if (mounted) setState(() => _resolvedMembers = resolved);

    // Update the isPending flag *only* on the existing members
    if (mounted) {
      setState(() {
        _resolvedMembers = _resolvedMembers.map((member) {
          final status = getGlobalMemberStatus(member.id, widget.eventId);
          final isCreator = member.id.toLowerCase() == creatorEmail;
          final isManager = rawManagers.map((e) => e.toLowerCase()).contains(member.id.toLowerCase());
          final isPending = (isCreator || isManager) ? false : status == 'pending';

          return member.isPending == isPending
              ? member
              : Member(
            id: member.id,
            displayName: member.displayName,
            resolvedPhoto: member.resolvedPhoto,
            isPending: isPending,
          );
        }).toList();
      });
    }

  }

  String getGlobalMemberStatus(String email, String eventId) {
    EventData event;

    if (widget.publicDisplay) { event = upcomingPublicEvents.firstWhere((e) => e.id == eventId); }
    else { event = EventLiveSyncService().getNotifier(eventId)!.value; }

    final member = event.eventMembers.firstWhere(
          (m) => (m['email'] as String?)?.toLowerCase() == email.toLowerCase(),
      orElse: () => {'status': 'pending'},
    );

    return (member['status'] ?? 'pending').toString().toLowerCase();
  }





  @override
  Widget build(BuildContext context) {
    if (widget.publicDisplay) {
      final event = upcomingPublicEvents.firstWhere((e) => e.id == widget.eventId);

      hasPermission = event.hasPermission(FirebaseAuth.instance.currentUser!.email!);
      color = hasPermission ? textHighlightedColor : textSecondaryHighlightedColor;
      selectedStatus = event.status;

      return _buildContent(context, event);
    }


    final notifier = EventLiveSyncService().getNotifier(widget.eventId);

    return ValueListenableBuilder<EventData>(
      valueListenable: notifier!,
      builder: (context, liveEvent, _) {
        hasPermission = liveEvent.hasPermission(FirebaseAuth.instance.currentUser!.email!);
        color = hasPermission ? textHighlightedColor : textSecondaryHighlightedColor;
        selectedStatus = liveEvent.status;

        // update member list live
        final currentKeys = _resolvedMembers.map((m) {
          final status = getGlobalMemberStatus(m.id, widget.eventId);
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


        return _buildContent(context, liveEvent);
      },
    );
  }

  Widget _buildContent(BuildContext context, EventData event) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 700),
      height: 650,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF24324A), Color(0xFF2F445E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusSelector(context, event),
          const SizedBox(height: 16),
          _buildTitleBlock(context, event),
          LocationBlock(address: event.locationAddress!, color: color),
          CollaboratorsBlock(
            members: _resolvedMembers,
            creatorId: event.createdBy,
            managerIds: event.eventManagers,
          ),

          _buildGoalsBlock(event),
          _buildVisibilityAudienceBlock(event),
          const Spacer(),
        ],
      ),
    );
  }





  Widget _buildStatusSelector(BuildContext context, EventData eventData) {
    final statusList = ["UPCOMING", "COMPLETED", "CANCELLED"];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: statusList.map((status) {
        final current = eventData.status;

        final bool isPast = eventData.selectedDate!.isBefore(DateTime.now());
        final isIllegal =
            (current == "UPCOMING" && status == "COMPLETED") ||
                (current == "COMPLETED" && status == "UPCOMING") ||
                (current == "CANCELLED" && status == "UPCOMING" && isPast) ||
                (current == "CANCELLED" && status == "COMPLETED" && !isPast);

        final isSelected = selectedStatus == status;
        final isCancelled = status == "CANCELLED";
        final isUpcoming = status == "UPCOMING";
        final isCompleted = status == "COMPLETED";

        final Color backgroundColor = isSelected
            ? (isCompleted
            ? color
            : isUpcoming
            ? color.withOpacity(0.2)
            : Colors.transparent)
            : Colors.transparent;

        final Color borderColor = isSelected
            ? color
            : isIllegal && hasPermission ? Colors.white.withOpacity(0.2)
            : Colors.white.withOpacity(0.5);

        final Color textColor = isIllegal && hasPermission ?
            Colors.white.withOpacity(0.2)
            : isSelected
            ? (isCompleted ? inAppForegroundColor : color)
            : Colors.white.withOpacity(0.5);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: GestureDetector(
            onTap: !hasPermission || isIllegal
                ? null
                : () async {
              if (selectedStatus == status) return;

              setState(() => selectedStatus = status);
              eventData.status = status;

              CloudStorageService().saveEvent(eventData);
              widget.onStatusChange?.call(eventData);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 2),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );

  }

  Widget _buildTitleBlock(BuildContext context, EventData eventData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final title = eventData.eventName;
            final style = TextStyle(
              color: textColor,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            );

            final textPainter = TextPainter(
              text: TextSpan(text: title, style: style),
              maxLines: 1,
              textDirection: TextDirection.ltr,
            )..layout();

            final underlineWidth = textPainter.width + 10;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Text(title, style: style),
                ),
                const SizedBox(height: 2),
                Container(
                  width: underlineWidth,
                  height: 3,
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              formatDate(eventData.selectedDate!),
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 24),
            Icon(Icons.access_time, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              formatTime(eventData.selectedTime!),
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGoalsBlock(EventData eventData) {
    final goals = eventData.eventGoals;
    if (goals.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Align(
        alignment: Alignment.center,
        child: ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                Colors.black,
                Colors.black,
                Colors.transparent,
              ],
              stops: [0.0, 0.02, 0.98, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: goals.map((goal) {
                return Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color, width: 3),
                  ),
                  child: Text(
                    goal,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisibilityAudienceBlock(EventData eventData) {
    final isPublic = eventData.isPublic;
    final isPaid = eventData.isPaid;
    final tags = eventData.audienceTags;

    final TextStyle selectedStyle = TextStyle(
      color: color,
      fontWeight: FontWeight.w700,
      fontSize: 15,
    );

    final TextStyle unselectedStyle = TextStyle(
      color: textColor.withOpacity(0.5),
      fontWeight: FontWeight.w500,
      fontSize: 15,
    );

    Widget _sectionTitle(String text) {
      final style = TextStyle(
        color: textColor,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      );

      final textPainter = TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();

      final underlineWidth = textPainter.width + 6;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: style),
          const SizedBox(height: 2),
          Container(
            width: underlineWidth,
            height: 3,
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 6),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _sectionTitle("Visibility"),
                      Text("Public", style: isPublic ? selectedStyle : unselectedStyle),
                      Text("Private", style: !isPublic ? selectedStyle : unselectedStyle),
                      const SizedBox(height: 16),
                      _sectionTitle("Cost"),
                      Text("Free", style: !isPaid ? selectedStyle : unselectedStyle),
                      Text("Paid", style: isPaid ? selectedStyle : unselectedStyle),
                      const SizedBox(height: 6),
                      if (isPaid)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: color,
                              width: 3,
                            ),
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 78),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "${eventData.eventPrice?.toStringAsFixed(2) ?? '?'} ${eventData.eventCurrency ?? ''}",
                                style: selectedStyle.copyWith(fontSize: 18),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
              ),


              // Divider
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: 3,
                height: 145,
                color: Colors.white.withOpacity(0.15),
              ),

              // Right Column
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle("Destined to"),

                    // Tags area with min height (approx. 3 rows worth)
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 110), // ~3 rows of tags
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: tags.isEmpty
                            ? Text("Everyone", style: selectedStyle)
                            : Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: tags
                              .where((tag) => tag != "Custom")
                              .map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: color,
                                  width: 2,
                                ),
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 200), // limit width to allow wrapping
                                child: Text(
                                  tag.startsWith("Custom:")
                                      ? tag.replaceFirst("Custom:", "")
                                      : tag,
                                  softWrap: true,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: inAppForegroundColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),

                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 9),

                    Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.group, color: Colors.white70, size: 20),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160), // set desired max width
                          child: Text(
                            eventData.organizationType == "Custom"
                                ? eventData.customOrg
                                : eventData.organizationType,
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.smart_toy_outlined, color: Colors.white70, size: 20),
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 200),
                              child: Text(
                                "AI Help",
                                softWrap: true,
                                overflow: TextOverflow.visible,
                                maxLines: 2,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: hasPermission
                              ? (credits > 0 ? eventData.jamieEnabled : false)
                              : eventData.jamieEnabled,
                          onChanged: (value) {
                            setState(() {
                              if (!hasPermission) return;
                              eventData.jamieEnabled = value;
                              CloudStorageService().saveEvent(eventData);
                            });
                          },
                          activeColor: color,
                          activeTrackColor: isDarkModeNotifier.value
                              ? Colors.purple.shade50
                              : Colors.yellow.shade50,
                          inactiveThumbColor: Colors.grey,
                          inactiveTrackColor: Colors.grey.shade800,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ],
                ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  void dispose() {
    popupStackCount.value--;
    super.dispose();
  }
}
