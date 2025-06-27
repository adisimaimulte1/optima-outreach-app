import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/beforeApp/widgets/buttons/bouncy_button.dart';

class DateTimeStep extends StatelessWidget {
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final ValueChanged<DateTime?> onDateChanged;
  final ValueChanged<TimeOfDay?> onTimeChanged;

  const DateTimeStep({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.onDateChanged,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _title("When is it happening?"),
            const SizedBox(height: 24),
            _pickerButton(
              context,
              icon: Icons.calendar_today,
              label: selectedDate != null
                  ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"
                  : "Select a date",
              isFilled: selectedDate != null,
              onTap: () => _pickDate(context),
            ),
            const SizedBox(height: 16),
            _pickerButton(
              context,
              icon: Icons.access_time,
              label: selectedTime != null
                  ? _formatTime(selectedTime!)
                  : "Select a time",
              isFilled: selectedTime != null,
              disabled: selectedDate == null,
              onTap: () => _pickTime(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _title(String text) {
    return Column(
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Container(height: 2, width: 220, color: Colors.white24),
      ],
    );
  }

  Widget _pickerButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onTap,
        bool isFilled = false,
        bool disabled = false,
      }) {
    return BouncyButton(
      onPressed: disabled ? () {} : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: disabled
              ? Colors.white10
              : (isFilled ? textHighlightedColor : textColor.withOpacity(0.06)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: disabled
                ? Colors.white24
                : (isFilled ? textHighlightedColor : textDimColor),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: disabled
                  ? Colors.white38
                  : (isFilled ? inAppForegroundColor : Colors.white54),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: disabled
                      ? Colors.white38
                      : (isFilled ? inAppForegroundColor : textColor),
                  fontWeight: isFilled ? FontWeight.bold : FontWeight.normal,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    popupStackCount.value++;

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: selectedDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: _customPickerTheme,
    ).whenComplete(() => popupStackCount.value--);

    if (picked != null) {
      onDateChanged(picked);

      // validate if time needs to be cleared
      if (selectedTime != null) {
        final now = DateTime.now();
        if (picked.year == now.year && picked.month == now.month && picked.day == now.day) {
          final pickedMinutes = selectedTime!.hour * 60 + selectedTime!.minute;
          final nowPlusOneHourMinutes = (now.hour + 1) * 60 + now.minute;

          if (pickedMinutes < nowPlusOneHourMinutes) {
            onTimeChanged(null);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: textHighlightedColor,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                elevation: 6,
                duration: const Duration(seconds: 3),
                content: Center(
                  child: Text(
                    "Selected time was invalid and has been cleared.",
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
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    if (selectedDate == null) return;

    final now = DateTime.now();
    final initialTime = selectedTime ?? TimeOfDay.now();

    popupStackCount.value++;

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: _customPickerTheme,
    ).whenComplete(() => popupStackCount.value--);

    if (picked != null) {
      if (selectedDate!.year == now.year &&
          selectedDate!.month == now.month &&
          selectedDate!.day == now.day) {
        final pickedMinutes = picked.hour * 60 + picked.minute;
        final nowPlusOneHourMinutes = (now.hour + 1) * 60 + now.minute;

        if (pickedMinutes < nowPlusOneHourMinutes) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: textHighlightedColor,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              elevation: 6,
              duration: const Duration(seconds: 1),
              content: Center(
                child: Text(
                  (nowPlusOneHourMinutes - pickedMinutes < 60)
                      ? "Please select a time at least 1 hour from now."
                      : "You can't select a time in the past.",
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
          return;
        }
      }

      onTimeChanged(picked);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? "AM" : "PM";

    return "$hour:$minute $period";
  }

  Widget _customPickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: textHighlightedColor,
          onPrimary: inAppForegroundColor,
          surface: const Color(0xFF2F445E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2F445E),
          iconTheme: IconThemeData(
            color: Colors.white54,
            opacity: 1.0,
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            splashFactory: NoSplash.splashFactory,
            overlayColor: MaterialStateProperty.all(Colors.transparent),
            iconSize: MaterialStateProperty.all(26),
            foregroundColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.disabled)) {
                return Colors.white38;
              }
              if (states.contains(MaterialState.pressed)) {
                return textHighlightedColor.withOpacity(0.7);
              }
              return textHighlightedColor;
            }),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all(textHighlightedColor),
            textStyle: MaterialStateProperty.all(const TextStyle(fontWeight: FontWeight.bold)),
            overlayColor: MaterialStateProperty.all(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
          ),
        ),
        timePickerTheme: TimePickerThemeData(
          backgroundColor: inAppForegroundColor,
          hourMinuteTextColor: textColor,
          dayPeriodTextColor: textColor,
          dialHandColor: textHighlightedColor,
          helpTextStyle: TextStyle(color: textColor),
          dayPeriodShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          dayPeriodColor: MaterialStateColor.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return textHighlightedColor;
            }
            return Colors.white10;
          }),
        ),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
  }
}
