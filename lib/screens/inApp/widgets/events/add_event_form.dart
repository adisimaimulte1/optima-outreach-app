import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/buttons/close_button.dart';
import 'package:optima/screens/inApp/widgets/events/buttons/navigation_button.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:optima/screens/inApp/widgets/events/steps/event_ai_step.dart';
import 'package:optima/screens/inApp/widgets/events/steps/event_audience_step.dart';
import 'package:optima/screens/inApp/widgets/events/steps/event_goals_step.dart';
import 'package:optima/screens/inApp/widgets/events/steps/event_location_step.dart';
import 'package:optima/screens/inApp/widgets/events/steps/event_members_step.dart';
import 'package:optima/screens/inApp/widgets/events/steps/event_name_step.dart';
import 'package:optima/screens/inApp/widgets/events/steps/event_time_step.dart';
import 'package:optima/services/notifications/local_notification_service.dart';
import 'package:optima/services/storage/cloud_storage_service.dart';

class AddEventForm extends StatefulWidget {
  final EventData? initialData;

  const AddEventForm({super.key, this.initialData});

  @override
  State<AddEventForm> createState() => AddEventFormState();
}


class AddEventFormState extends State<AddEventForm> {
  final PageController _pageController = PageController();

  final GlobalKey<EventMembersStepState> _membersKey = GlobalKey<EventMembersStepState>();
  final GlobalKey<EventGoalsStepState> _goalsKey = GlobalKey<EventGoalsStepState>();
  final GlobalKey<EventAudienceStepState> _audienceKey = GlobalKey<EventAudienceStepState>();


  int _currentStep = 0;
  final int _totalSteps = 7;


  // step 1
  String _eventName = '';
  String _organizationType = 'Personal';
  String _customOrg = '';

  // step 2
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // step 3
  String? _locationAddress;
  LatLng? _locationLatLng;
  LatLng? _initialLatLng;

  // step 4
  List<String> _eventMembers = [];

  // step 5
  List<String> _eventGoals = [];

  // step 6
  List<String> _audienceTags = [];
  bool _isPublic = true;
  bool _isPaid = false;
  double? _eventPrice;
  String? _eventCurrency;

  // step 7
  bool _jamieEnabled = credits > 0;


  @override
  void initState() {
    super.initState();
    popupStackCount.value++;

    if (preloadTutorialEvent) {
      final data = tutorialEventData;

      _eventName = data.eventName;
      _organizationType = data.organizationType;
      _customOrg = data.customOrg;
      _selectedDate = data.selectedDate;
      _selectedTime = data.selectedTime;
      _locationAddress = data.locationAddress;
      _locationLatLng = data.locationLatLng;
      _eventMembers = List<String>.from(
          data.eventMembers.map((m) => m['email'].toString())
      );
      _eventGoals = List.from(data.eventGoals);
      _audienceTags = List.from(data.audienceTags);
      _isPublic = data.isPublic;
      _isPaid = data.isPaid;
      _eventPrice = data.eventPrice;
      _eventCurrency = data.eventCurrency;
      _jamieEnabled = data.jamieEnabled;

      preloadTutorialEvent = false;
    }
    if (widget.initialData != null) {
      final data = widget.initialData!;
      _eventName = data.eventName;
      _organizationType = data.organizationType;
      _customOrg = data.customOrg;
      _selectedDate = data.selectedDate;
      _selectedTime = data.selectedTime;
      _locationAddress = data.locationAddress;
      _locationLatLng = data.locationLatLng;
      _eventMembers = List<String>.from(
          data.eventMembers.map((m) => m['email'].toString())
      );
      _eventGoals = List.from(data.eventGoals);
      _audienceTags = List.from(data.audienceTags);
      _isPublic = data.isPublic;
      _isPaid = data.isPaid;
      _eventPrice = data.eventPrice;
      _eventCurrency = data.eventCurrency;
      _jamieEnabled = data.jamieEnabled;
    }

    _resolveInitialCenter();
  }

  void _resolveInitialCenter() async {
    LatLng fallback = const LatLng(45.7928, 24.1521);

    if (_initialLatLng != null) {
      setState(() => _initialLatLng = _initialLatLng);
      return;
    }

    LatLng? fastLocation;
    if (locationAccess) {
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          fastLocation = LatLng(lastKnown.latitude, lastKnown.longitude);
          setState(() => _initialLatLng = fastLocation);
        }
      } catch (_) {}

      // Regardless of success, start async accurate fetch
      Geolocator.getCurrentPosition().then((position) {
        final accurate = LatLng(position.latitude, position.longitude);
        if (mounted && (_initialLatLng == null || accurate != _initialLatLng)) {
          setState(() {
            _initialLatLng = accurate;
          });
        }
      }).catchError((_) {}); // swallow errors
    }

    if (_initialLatLng == null) {
      setState(() => _initialLatLng = fastLocation ?? fallback);
    }
  }







  final List<IconData> stepIcons = [
    Icons.edit,           // Event Name
    Icons.calendar_today, // Date & Time
    Icons.location_on,    // Location
    Icons.people,         // Audience
    Icons.flag,           // Goals
    Icons.inventory,      // Resources
    Icons.smart_toy,      // AI + Visibility
  ];

  Future<void> _nextStep() async {
    if (_currentStep == 3) {
      FocusScope.of(context).unfocus();
      final added = await _membersKey.currentState?.addIfPendingInput() ?? false;
      if (added) {
        await Future.delayed(const Duration(milliseconds: 400));
      }
    } else if (_currentStep == 4) {
      FocusScope.of(context).unfocus();
      bool? added = await _goalsKey.currentState?.saveIfPendingGoal();
      if (added!) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } else if (_currentStep == 5) {
      FocusScope.of(context).unfocus();
      final added = await _audienceKey.currentState?.saveIfPendingAudienceInput() ?? false;
      if (added) await Future.delayed(const Duration(milliseconds: 400));
    }



    FocusScope.of(context).unfocus();

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      if (widget.initialData != null) {
        _updateExistingEvent(widget.initialData!);
        return;
      }

      await _createNewEvent();
    }
  }

  void _prevStep() {
    FocusScope.of(context).unfocus();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }




  Future<void> _updateExistingEvent(EventData data) async {
    final now = DateTime.now().toIso8601String();

    // fetch existing members from Firestore
    final membersSnap = await FirebaseFirestore.instance
        .collection('events')
        .doc(data.id)
        .collection('members')
        .where(FieldPath.documentId, isNotEqualTo: 'placeholder')
        .get();

    final existingMembersMap = {
      for (final doc in membersSnap.docs)
        (doc.data()['email'] as String).toLowerCase(): doc.data()
    };

    final lowercasedEmails = _eventMembers.map((e) => e.toLowerCase()).toSet();

    // build final member list: preserve existing status/invitedAt
    data
      ..eventName = _eventName
      ..organizationType = _organizationType
      ..customOrg = _customOrg
      ..selectedDate = _selectedDate
      ..selectedTime = _selectedTime
      ..locationAddress = _locationAddress
      ..locationLatLng = _locationLatLng
      ..eventMembers = lowercasedEmails.map((email) {
        final existing = existingMembersMap[email];
        return {
          'email': email,
          'status': existing?['status'] ?? 'pending',
          'invitedAt': existing?['invitedAt'] ?? now,
        };
      }).toList()
      ..eventGoals = _eventGoals
      ..audienceTags = _audienceTags
      ..isPublic = _isPublic
      ..isPaid = _isPaid
      ..eventPrice = _isPaid ? _eventPrice : null
      ..eventCurrency = _isPaid ? _eventCurrency : null
      ..jamieEnabled = _jamieEnabled
      ..createdBy = email;

    Navigator.of(context).pop(data);

    await CloudStorageService().saveEvent(data);


    final Set<String> newEmails = _eventMembers.map((e) => e.toLowerCase()).toSet();
    for (final doc in membersSnap.docs) {
      final memberEmail = (doc.data()['email'] as String?)?.toLowerCase();

      // if not in new list, delete
      if (memberEmail != null && !newEmails.contains(memberEmail)) {
        await doc.reference.delete();
      }
    }



    // send invites to current members
    final memberMap = {
      for (var doc in membersSnap.docs)
        doc.id: doc.data()
    };

    // Build a single public_data query for all emails
    final lwc = _eventMembers.map((e) => e.toLowerCase()).toSet();
    final publicDataQuery = await FirebaseFirestore.instance
        .collection('public_data')
        .where('email', whereIn: lwc.toList())
        .get();

    for (final userDoc in publicDataQuery.docs) {
      final uid = userDoc.id;
      final email = (userDoc.data()['email'] as String?)?.toLowerCase();
      if (email == null) continue;

      final wasManager = data.eventManagers.contains(email);
      final status = (memberMap[uid]?['status'] ?? '').toString().toLowerCase();

      final alreadyInEvent = wasManager || status == 'pending' || status == 'accepted';

      if (!alreadyInEvent) {
        await LocalNotificationService().addNotification(
          userId: uid,
          message: 'You were invited to join "$_eventName".',
          eventId: data.id!,
          sender: data.createdBy,
        );
      }
    }
  }

  Future<void> _createNewEvent() async {
    final eventData = EventData(
      eventName: _eventName,
      organizationType: _organizationType,
      customOrg: _customOrg,
      selectedDate: _selectedDate,
      selectedTime: _selectedTime,
      locationAddress: _locationAddress,
      locationLatLng: _locationLatLng,
      eventMembers: _eventMembers.map((email) => {
        'email': email,
        'status': 'pending',
        'invitedAt': DateTime.now().toIso8601String(),
      }).toList(),
      eventManagers: [email],
      eventGoals: _eventGoals,
      audienceTags: _audienceTags,
      isPublic: _isPublic,
      isPaid: _isPaid,
      eventPrice: _isPaid ? _eventPrice : null,
      eventCurrency: _isPaid ? _eventCurrency : null,
      jamieEnabled: _jamieEnabled,
      status: 'UPCOMING',
      createdBy: email,
    );


    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    await CloudStorageService().saveEvent(eventData);

    if (mounted) Navigator.of(context).pop();
    if (mounted) Navigator.of(context).pop(eventData);


    for (final email in _eventMembers) {
      final query = await FirebaseFirestore.instance
          .collection('public_data')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        LocalNotificationService().addNotification(
          userId: query.docs.first.id,
          message: 'You were invited to join "${_eventName}".',
          eventId: eventData.id!,
          sender: eventData.createdBy,
        );
      }
    }
  }




  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: selectedThemeNotifier,
      builder: (_, __, ___) {
        final viewInsets = MediaQuery.of(context).viewInsets;

        return AnimatedPadding(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            padding: const EdgeInsets.all(16),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: SizedBox(
                      height: 380,
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: List.generate(_totalSteps, (index) => _step(index)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildNavigationControls(),
                _buildProgressBarWithMorphingIcon(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.initialData == null ? "Create New Event" : "Edit This Event",
                style: TextStyle(
                  color: textColor,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 500,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        CloseButtonAnimated(
            onPressed: () => Navigator.of(context).pop(),
          ),
      ],
    );
  }

  Widget _buildNavigationControls() {
    final bool isLastStep = _currentStep == _totalSteps - 1;
    final bool canProceed = _canProceedToNextStep();

    return Row(
      children: [
        if (_currentStep > 0)
          AnimatedScaleButton(
            onPressed: _prevStep,
            icon: Icons.chevron_left,
            label: "Back",
            backgroundColor: Colors.transparent,
            foregroundColor: textColor,
            fontSize: 20,
            borderColor: textDimColor,
            borderWidth: 1.2,
            isEnabled: true,
          ),
        if (_currentStep > 0) const SizedBox(width: 16),
        AnimatedScaleButton(
          onPressed: canProceed ? _nextStep : () {},
          icon: isLastStep ? Icons.check : Icons.chevron_right,
          label: isLastStep ? (widget.initialData == null ? "Create" : "Update") : "Next",
          backgroundGradient: canProceed
              ? LinearGradient(
            colors: [
              textHighlightedColor,
              textSecondaryHighlightedColor,
            ],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          )
              : null,
          backgroundColor: canProceed ? null : Colors.transparent,
          foregroundColor: inAppForegroundColor,
          fontSize: 20,
          borderColor: textDimColor,
          borderWidth: 1.2,
          isEnabled: canProceed,
        ),
      ],
    );
  }

  Widget _buildProgressBarWithMorphingIcon() {
    const double dotSize = 6;
    const double iconSize = 32;
    const double cellWidth = 40; // keep the even spacing
    const double barHeight = 16;
    const double maxBarWidth = 600;

    return SizedBox(
      height: 80,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double barWidth = maxBarWidth.clamp(0, constraints.maxWidth);
          final double fillWidth = barWidth * (_currentStep + 1) / _totalSteps;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Dot/Icon Row (even spacing, moved closer to bar)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_totalSteps, (index) {
                  final bool isActive = index == _currentStep;

                  return SizedBox(
                    width: cellWidth,
                    height: cellWidth,
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeOutBack,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: isActive
                            ? Icon(
                          key: ValueKey('icon-$index'),
                          stepIcons[index],
                          size: iconSize,
                          color: textHighlightedColor,
                        )
                            : Container(
                          key: ValueKey('dot-$index'),
                          width: dotSize,
                          height: dotSize,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8), // moved closer from 16 to 8
              // Progress bar
              SizedBox(
                width: barWidth,
                child: Stack(
                  children: [
                    Container(
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: barHeight,
                      width: fillWidth,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: [
                            isDarkModeNotifier.value ? textHighlightedColor: textSecondaryHighlightedColor,
                            isDarkModeNotifier.value ? textSecondaryHighlightedColor : textHighlightedColor],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField({String? hint}) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: textColor.withOpacity(0.07),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      style: TextStyle(color: textColor),
    );
  }



  Widget _step(int index) {
    switch (index) {
      case 0:
        return EventNameStep(
          eventName: _eventName,
          organizationType: _organizationType,
          customOrg: _customOrg,
          onEventNameChanged: (value) => setState(() => _eventName = value),
          onOrganizationTypeChanged: (value) => setState(() => _organizationType = value),
          onCustomOrgChanged: (value) => setState(() => _customOrg = value),
        );
      case 1:
        return DateTimeStep(
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          onDateChanged: (value) => setState(() => _selectedDate = value),
          onTimeChanged: (value) => setState(() => _selectedTime = value),
        );
      case 2:
        return EventLocationStep(
          initialCenter: _initialLatLng,
          onLocationPicked: (address, lat, lng) {
            setState(() {
              _locationAddress = address;
              _initialLatLng = LatLng(lat, lng);
              _locationLatLng = LatLng(lat, lng);
            });
          },
          initialAddress: _locationAddress,
          initialLatLng: _locationLatLng,
        );
      case 3:
        return EventMembersStep(
          key: _membersKey,
          initialMembers: _eventMembers,
          onChanged: (list) => setState(() => _eventMembers = list),
        );
      case 4:
        return EventGoalsStep(
          key: _goalsKey,
          goals: _eventGoals.join('\n'),
          onGoalsAdded: (goals) => setState(() {
            _eventGoals = goals
                .split('\n')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
          }),
        );
      case 5:
        return EventAudienceStep(
          key: _audienceKey,
          selectedTags: _audienceTags,
          isPublic: _isPublic,
          isPaid: _isPaid,
          price: _eventPrice,
          currency: _eventCurrency,
          onChanged: ({
            required audience,
            required isPublic,
            required isPaid,
            required price,
            required currency,
          }) {
            setState(() {
              _audienceTags = audience;
              _isPublic = isPublic;
              _isPaid = isPaid;
              _eventPrice = price;
              _eventCurrency = currency;
            });
          },
        );
      case 6:
        return EventAIStep(
          jamieEnabled: _jamieEnabled,
          onChanged: (val) => setState(() => _jamieEnabled = val),
        );

      default:
        return _buildTextField(hint: "Enter here...");
    }
  }



  bool _canProceedToNextStep() {
    if (_currentStep == 0) {
      return _eventName.length > 3 && (_organizationType != 'Custom' || _customOrg.length > 3);
    } else if (_currentStep == 1) {
      return _selectedDate != null && _selectedTime != null;
    } else if (_currentStep == 2) {
      return _locationAddress != null && _locationAddress!.trim().length > 5;
    } else if (_currentStep == 4) {
      return _eventGoals.isNotEmpty;
    } else if (_currentStep == 5) {
      final hasCustomSelected = _audienceTags.any((e) => e.startsWith("Custom"));
      final hasValidCustom = _audienceTags.any(
            (e) => e.startsWith("Custom:") && e.substring(7).trim().length >= 2,
      );
      final hasValidPredefined = _audienceTags.any((e) => !e.startsWith("Custom"));
      final hasAudience = hasCustomSelected ? hasValidCustom : hasValidPredefined;

      final hasValidPrice = _eventPrice != null && _eventPrice! > 0;
      final hasValidCurrency = _eventCurrency != null && _eventCurrency!.isNotEmpty;
      final paidValid = !_isPaid || (hasValidPrice && hasValidCurrency);

      return hasAudience && paidValid;
    }

    return true;
  }


  @override
  void dispose() {
    popupStackCount.value--;
    super.dispose();
  }



  void scrollToStep(int stepIndex) {
    if (stepIndex >= 0 && stepIndex < _totalSteps) {
      setState(() => _currentStep = stepIndex);
      _pageController.jumpToPage(stepIndex);
    }
  }
}
