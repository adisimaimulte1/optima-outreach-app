import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/event_feedback.dart';
import 'package:optima/screens/inApp/widgets/settings/buttons/text_button.dart';

class EventFeedbackFormDialog extends StatefulWidget {
  final void Function(EventFeedback feedback) onSubmit;

  const EventFeedbackFormDialog({super.key, required this.onSubmit});

  @override
  State<EventFeedbackFormDialog> createState() => _EventFeedbackFormDialogState();
}

class _EventFeedbackFormDialogState extends State<EventFeedbackFormDialog> {
  int stars = 0;
  bool wasOrganizedWell = false;
  bool wouldRecommend = false;
  bool wantsToBeContacted = false;
  final commentController = TextEditingController();

  bool get isValid => stars > 0 && commentController.text.trim().length > 30;

  @override
  void initState() {
    super.initState();
    commentController.addListener(() {
      setState(() {});
    });
  }


  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  Widget _title(String text, {double width = 200}) {
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

  Widget _buildStarRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final isSelected = index < stars;
        return GestureDetector(
          onTap: () => setState(() => stars = index + 1),
          behavior: HitTestBehavior.translucent,
          child: AnimatedScale(
            scale: isSelected ? 1.3 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                color: isSelected ? Colors.orangeAccent : Colors.white24,
                size: 42, // Increased size
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildToggleOptions() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _toggleOption("Was organized well", wasOrganizedWell, () {
          setState(() => wasOrganizedWell = !wasOrganizedWell);
        }),
        _toggleOption("Would recommend", wouldRecommend, () {
          setState(() => wouldRecommend = !wouldRecommend);
        }),
        _toggleOption("Contact me for future events", wantsToBeContacted, () {
          setState(() => wantsToBeContacted = !wantsToBeContacted);
        }),
      ],
    );
  }

  Widget _toggleOption(String label, bool selected, VoidCallback onTap) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      tween: Tween(begin: 1.0, end: selected ? 1.1 : 1.0),
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? textHighlightedColor : inAppForegroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? textHighlightedColor : textDimColor,
              width: selected ? 0 : 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) Icon(Icons.check, size: 20, color: inAppForegroundColor),
              if (selected) const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? inAppForegroundColor : textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: inAppForegroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _title("How did it go?", width: 160),
            const SizedBox(height: 20),
            _buildStarRow(),
            const SizedBox(height: 24),
            _title("Share your thoughts", width: 200),
            const SizedBox(height: 14),
            TextField(
              controller: commentController,
              maxLines: 3,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: standardInputDecoration(hint: "Any other thoughts?\n Write at least 30 characters."),
            ),
            const SizedBox(height: 28),
            _title("A Personal Touch", width: 180),
            const SizedBox(height: 14),
            _buildToggleOptions(),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButtonWithoutIcon(
          label: "Dismiss",
          onPressed: () => Navigator.of(context).pop(),
          foregroundColor: Colors.white70,
          borderColor: Colors.white70,
          fontSize: 16,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        ),
        TextButtonWithoutIcon(
          label: "Submit",
          onPressed: () {
            if (!isValid) return;

            final email = FirebaseAuth.instance.currentUser?.email ?? 'unknown';
            final feedback = EventFeedback(
              email: email,
              completed: true,
              stars: stars,
              comment: commentController.text.trim(),
              wasOrganizedWell: wasOrganizedWell,
              wouldRecommend: wouldRecommend,
              wantsToBeContacted: wantsToBeContacted,
            );
            widget.onSubmit(feedback);
            Navigator.of(context).pop();
          },
          foregroundColor: isValid? inAppBackgroundColor : Colors.white70,
          backgroundColor: isValid ? textHighlightedColor : Colors.transparent,
          borderColor: isValid ? textHighlightedColor : Colors.white70,
          fontSize: 16,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        ),
      ],
    );
  }
}
