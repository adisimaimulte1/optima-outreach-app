import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/buttons/close_button.dart';
import 'package:optima/screens/inApp/widgets/events/buttons/navigation_button.dart';
import 'package:optima/screens/inApp/widgets/events/steps/event_name_step.dart';
import 'package:optima/screens/inApp/widgets/events/steps/event_time_step.dart';

class AddEventForm extends StatefulWidget {
  const AddEventForm({super.key});

  @override
  State<AddEventForm> createState() => _AddEventFormState();
}

class _AddEventFormState extends State<AddEventForm> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 7;


  // step 1
  String _eventName = '';
  String _organizationType = 'Personal';
  String _customOrg = '';

  // step 2
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;




  final List<IconData> stepIcons = [
    Icons.edit,           // Event Name
    Icons.calendar_today, // Date & Time
    Icons.location_on,    // Location
    Icons.people,         // Audience
    Icons.flag,           // Goals
    Icons.inventory,      // Resources
    Icons.smart_toy,      // AI + Visibility
  ];




  void _nextStep() {
    FocusScope.of(context).unfocus();
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      // TODO: Submit
    }
  }

  void _prevStep() {
    FocusScope.of(context).unfocus();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }



  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0),
      resizeToAvoidBottomInset: false,  // Prevent the scaffold from resizing its body
      body: Center(
        child: AnimatedPadding(
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

                // Wrapping the PageView with Flexible to ensure it takes only available space
                Flexible(
                  child: SingleChildScrollView(
                    child: SizedBox(
                      height: 380,  // Set the fixed height for your PageView
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: List.generate(
                          _totalSteps,
                              (index) => _step(index),
                        ),
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
        ),
      ),
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
                "Create New Event",
                style: TextStyle(
                  color: textColor,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 500, // You can tweak this (try 120-160 depending on design)
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
            isEnabled: true, // Back is always enabled
          ),
        if (_currentStep > 0) const SizedBox(width: 16),
        AnimatedScaleButton(
          onPressed: canProceed ? _nextStep : () {}, // Must pass a non-null function
          icon: isLastStep ? Icons.check : Icons.chevron_right,
          label: isLastStep ? "Create" : "Next",
          backgroundGradient: canProceed
              ? LinearGradient(
            colors: [
              isDarkModeNotifier.value
                  ? textSecondaryHighlightedColor
                  : textHighlightedColor,
              isDarkModeNotifier.value
                  ? textHighlightedColor
                  : textSecondaryHighlightedColor,
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
    // TODO: Other steps
      default:
        return _buildTextField(hint: "Enter here...");
    }
  }



  bool _canProceedToNextStep() {
    if (_currentStep == 0) {
      return _eventName.length > 3;
    } else if (_currentStep == 1) {
      return _selectedDate != null && _selectedTime != null;
    }
    return true; // other steps: allow freely for now
  }

}
