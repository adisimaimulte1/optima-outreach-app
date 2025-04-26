import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/buttons/close_button.dart';
import 'package:optima/screens/inApp/widgets/events/buttons/navigation_button.dart';

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
          ),
        if (_currentStep > 0) const SizedBox(width: 16),
          AnimatedScaleButton(
            onPressed: _nextStep,
            icon: isLastStep ? Icons.check : Icons.chevron_right,
            label: isLastStep ? "Create" : "Next",
            backgroundGradient: LinearGradient(
              colors: [textHighlightedColor, textSecondaryHighlightedColor],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
            foregroundColor: inAppForegroundColor,
            fontSize: 20,
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
                          colors: [textSecondaryHighlightedColor, textHighlightedColor],
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

  Widget _step(int index) {
    if (index == 0) return _buildEventNameStep();
    if (index == 1) return _buildDateTimeStep();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Step ${index + 1}",
          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        _buildTextField(hint: "Enter here..."),
      ],
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





  // step 1
  Widget _buildEventNameStep() {
    final bool isCustom = _organizationType == 'Custom';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Event Name Title + Underline
            Column(
              children: [
                Text(
                  "What's your event called?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 2,
                  width: 220,
                  color: Colors.white24,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Event Name Input
            TextField(
              onChanged: (value) => setState(() => _eventName = value),
              textAlign: TextAlign.center,
              decoration: standardInputDecoration(hint: "e.g. Educational Workshop"),
              style: TextStyle(color: textColor, fontSize: 18),
            ),

            const SizedBox(height: 32),

            // Organizer Label + Underline
            Column(
              children: [
                Text(
                  "Who's organizing this?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 2,
                  width: 180,
                  color: Colors.white24,
                ),
              ],
            ),
            const SizedBox(height: 14),

            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                _orgOption("Personal"),
                _orgOption("Team/Club"),
                _orgOption("Company"),
                _orgOption("Custom"),
              ],
            ),

            // Custom org input
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: isCustom
                  ? Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextField(
                  key: const ValueKey('customOrg'),
                  onChanged: (value) => setState(() => _customOrg = value),
                  textAlign: TextAlign.center,
                  decoration: standardInputDecoration(hint: "Enter organization name"),
                  style: TextStyle(color: textColor, fontSize: 18),
                ),
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orgOption(String label) {
    final isSelected = _organizationType == label;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        tween: Tween<double>(begin: 1.0, end: isSelected ? 1.1 : 1.0),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: ChoiceChip(
          selected: isSelected,
          showCheckmark: false,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                Icon(Icons.check, size: 20, color: inAppForegroundColor),
              if (isSelected) const SizedBox(width: 4),
              Text(label),
            ],
          ),
          labelStyle: TextStyle(
            color: isSelected ? inAppForegroundColor : textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
          selectedColor: textHighlightedColor,
          backgroundColor: inAppForegroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? textHighlightedColor : textDimColor,
              width: isSelected ? 0 : 1.2,
            ),
          ),
          onSelected: (_) => setState(() => _organizationType = label),
        ),
      ),
    );
  }


  // step 2
  Widget _buildDateTimeStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "When is it happening?",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Container(height: 2, width: 220, color: Colors.white24),
            const SizedBox(height: 24),

            _buildPickerPreview(
              icon: Icons.calendar_today,
              label: _selectedDate != null
                  ? "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}"
                  : "Select a date",
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: ColorScheme.dark(
                          primary: textHighlightedColor,
                          surface: inAppForegroundColor,
                          onPrimary: inAppForegroundColor,
                        ),
                        dialogBackgroundColor: const Color(0xFF2F445E),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
            ),

            const SizedBox(height: 16),

            _buildPickerPreview(
              icon: Icons.access_time,
              label: _selectedTime != null
                  ? _selectedTime!.format(context)
                  : "Select a time",
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime ?? TimeOfDay.now(),
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.dark().copyWith(
                        timePickerTheme: TimePickerThemeData(
                          backgroundColor: inAppForegroundColor,
                          hourMinuteTextColor: textColor,
                          dayPeriodTextColor: Colors.white70,
                          dialHandColor: textHighlightedColor,
                          entryModeIconColor: textColor,
                        ),
                        colorScheme: ColorScheme.dark(
                          primary: textHighlightedColor,
                          onPrimary: inAppForegroundColor,
                          surface: Color(0xFF2F445E),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() => _selectedTime = picked);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerPreview({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      tween: Tween<double>(begin: 1.0, end: isActive ? 1.03 : 1.0),
      builder: (context, scale, child) {
        return GestureDetector(
          onTap: () {
            onTap();
          },
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isActive ? textHighlightedColor.withOpacity(0.15) : textColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isActive ? textHighlightedColor : textDimColor, width: 1.2),
              ),
              child: Row(
                children: [
                  Icon(icon, color: isActive ? textHighlightedColor : Colors.white54),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      color: isActive ? textHighlightedColor : textColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


}
