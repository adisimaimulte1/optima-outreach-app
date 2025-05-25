import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/details/collaborators_block.dart';
import 'package:optima/screens/inApp/widgets/events/details/member_avatar.dart';
import 'package:optima/screens/inApp/widgets/events/details/location_block.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:optima/services/cache/local_cache.dart';
import 'package:optima/services/storage/cloud_storage_service.dart';

class EventDetails extends StatefulWidget {
  final EventData eventData;
  final void Function(EventData newEvent)? onStatusChange;

  const EventDetails({super.key, required this.eventData, this.onStatusChange});

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
    selectedStatus = widget.eventData.status;
    _loadResolvedMembers();
  }




  Future<void> _loadResolvedMembers() async {
    final rawMembers = widget.eventData.eventMembers;
    final creatorEmail = widget.eventData.createdBy.toLowerCase();

    final List<Member> initial = [];

    // Add creator explicitly first
    if (creatorEmail.isNotEmpty) {
      final photo = await LocalCache().getCachedMemberPhoto(creatorEmail);
      initial.add(Member(
        id: creatorEmail,
        displayName: creatorEmail,
        resolvedPhoto: photo,
        isPending: false,
      ));
    }

    // Build initial members with full opacity (assume accepted)
    for (final member in rawMembers) {
      final email = member['email'] ?? '';
      final photo = await LocalCache().getCachedMemberPhoto(email);

      initial.add(Member(
        id: email,
        displayName: email,
        resolvedPhoto: photo,
        isPending: false,
      ));
    }

    // Set them immediately to render full opacity first
    if (mounted) setState(() => _resolvedMembers = initial);

    // Recache statuses (this will also update global events)
    for (final member in rawMembers) {
      final email = member['email'];
      if (email != null) {
        await LocalCache().recacheMemberStatus(email, widget.eventData.id!);
      }
    }

    // Update the isPending flag *only* on the existing members
    if (mounted) {
      setState(() {
        _resolvedMembers = _resolvedMembers.map((member) {
          final status = getGlobalMemberStatus(member.id, widget.eventData.id!);
          final isCreator = member.id.toLowerCase() == creatorEmail;
          final isPending = isCreator ? false : status == 'pending';

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
    final event = events.firstWhere(
          (e) => e.id == eventId,
    );

    final member = event.eventMembers.firstWhere(
          (m) => (m['email'] as String?)?.toLowerCase() == email.toLowerCase(),
      orElse: () => {'status': 'pending'},
    );

    return (member['status'] ?? 'pending').toString().toLowerCase();
  }





  @override
  Widget build(BuildContext context) {
    hasPermission = widget.eventData.hasPermission(FirebaseAuth.instance.currentUser!.email!);
    color = hasPermission ? textSecondaryHighlightedColor : textHighlightedColor;

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
          _buildStatusSelector(context),
          const SizedBox(height: 16),
          _buildTitleBlock(context),
          LocationBlock(
              address: widget.eventData.locationAddress!,
              color: color),
          CollaboratorsBlock(members: _resolvedMembers, creatorId: widget.eventData.createdBy),
          _buildGoalsBlock(),
          _buildVisibilityAudienceBlock(),
          const Spacer(),
        ],
      ),
    );
  }



  Widget _buildStatusSelector(BuildContext context) {
    final statusList = ["UPCOMING", "COMPLETED", "CANCELLED"];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: statusList.map((status) {
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
            : Colors.white.withOpacity(0.2);

        final Color textColor = isSelected
            ? (isCompleted ? inAppForegroundColor : color)
            : Colors.white.withOpacity(isCancelled ? 0.4 : 0.5);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: GestureDetector(
            onTap: !hasPermission
                ? null
                : () async {
              if (selectedStatus == status) return;

              setState(() => selectedStatus = status);
              widget.eventData.status = status;

              CloudStorageService().saveEvent(widget.eventData);

              widget.onStatusChange?.call(widget.eventData);
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

  Widget _buildTitleBlock(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final title = widget.eventData.eventName;
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
              formatDate(widget.eventData.selectedDate!),
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
              formatTime(widget.eventData.selectedTime!),
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

  Widget _buildGoalsBlock() {
    final goals = widget.eventData.eventGoals;
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

  Widget _buildVisibilityAudienceBlock() {
    final isPublic = widget.eventData.isPublic;
    final isPaid = widget.eventData.isPaid;
    final tags = widget.eventData.audienceTags;

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
                                "${widget.eventData.eventPrice?.toStringAsFixed(2) ?? '?'} ${widget.eventData.eventCurrency ?? ''}",
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
                            widget.eventData.organizationType == "Custom"
                                ? widget.eventData.customOrg
                                : widget.eventData.organizationType,
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
                      children: [
                        const Icon(Icons.smart_toy_outlined, color: Colors.white70, size: 20),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 200), // set desired max width
                          child: Text(
                            "Utilize AI help",
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
                        const SizedBox(width: 6),
                        Switch(
                          value: hasPermission
                          ? (credits > 0 ? widget.eventData.jamieEnabled : false)
                          : widget.eventData.jamieEnabled,
                          onChanged: (value) {
                            setState(() {
                              if (!hasPermission) {return;}

                              widget.eventData.jamieEnabled = value;
                              CloudStorageService().saveEvent(widget.eventData);
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
