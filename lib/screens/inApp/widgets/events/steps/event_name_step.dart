import 'package:flutter/material.dart';
import 'package:optima/globals.dart';

class EventNameStep extends StatefulWidget {
  final String eventName;
  final String organizationType;
  final String customOrg;
  final ValueChanged<String> onEventNameChanged;
  final ValueChanged<String> onOrganizationTypeChanged;
  final ValueChanged<String> onCustomOrgChanged;

  const EventNameStep({
    super.key,
    required this.eventName,
    required this.organizationType,
    required this.customOrg,
    required this.onEventNameChanged,
    required this.onOrganizationTypeChanged,
    required this.onCustomOrgChanged,
  });

  @override
  State<EventNameStep> createState() => _EventNameStepState();
}

class _EventNameStepState extends State<EventNameStep> {
  late TextEditingController _eventNameController;
  late TextEditingController _customOrgController;

  @override
  void initState() {
    super.initState();
    _eventNameController = TextEditingController(text: widget.eventName);
    _customOrgController = TextEditingController(text: widget.customOrg);

    // Attach listeners
    _eventNameController.addListener(() {
      widget.onEventNameChanged(_eventNameController.text);
    });
    _customOrgController.addListener(() {
      widget.onCustomOrgChanged(_customOrgController.text);
    });
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _customOrgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isCustom = widget.organizationType == 'Custom';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _title("What's your event called?"),
            const SizedBox(height: 16),
            _eventNameField(),
            const SizedBox(height: 32),
            _title("Who's organizing this?", width: 180),
            const SizedBox(height: 14),
            _orgOptions(context),
            if (isCustom) _customOrgField(),
          ],
        ),
      ),
    );
  }

  Widget _title(String text, {double width = 220}) {
    return Column(
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Container(height: 2, width: width, color: Colors.white24),
      ],
    );
  }

  Widget _eventNameField() {
    return TextField(
      controller: _eventNameController,
      textAlign: TextAlign.center,
      decoration: standardInputDecoration(hint: "e.g. Educational Workshop"),
      style: TextStyle(color: textColor, fontSize: 18),
    );
  }

  Widget _orgOptions(BuildContext context) {
    final List<String> options = ["Personal", "Team/Club", "Company", "Custom"];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: options.map((label) => _orgOption(label)).toList(),
    );
  }

  Widget _orgOption(String label) {
    final bool isSelected = widget.organizationType == label;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      tween: Tween(begin: 1.0, end: isSelected ? 1.1 : 1.0),
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        onTap: () => widget.onOrganizationTypeChanged(label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? textHighlightedColor : inAppForegroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? textHighlightedColor : textDimColor,
              width: isSelected ? 0 : 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                Icon(Icons.check, size: 20, color: inAppForegroundColor),
              if (isSelected)
                const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? inAppForegroundColor : textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _customOrgField() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: TextField(
        key: const ValueKey('customOrg'),
        controller: _customOrgController,
        textAlign: TextAlign.center,
        decoration: standardInputDecoration(hint: "Enter organization name"),
        style: TextStyle(color: textColor, fontSize: 18),
      ),
    );
  }
}
