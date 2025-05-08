import 'package:flutter/material.dart';
import 'package:optima/screens/inApp/widgets/settings/dialogs/update_plan_dialog.dart';
import 'package:optima/screens/inApp/widgets/settings/buttons/text_button.dart';
import 'package:optima/globals.dart';

class CreditDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => ValueListenableBuilder<int>(
        valueListenable: creditNotifier,
        builder: (context, currentCredits, _) {
          return ValueListenableBuilder<double>(
            valueListenable: subCreditNotifier,
            builder: (context, subCreditValue, _) {
              final double progress = (subCreditValue % 1).clamp(0.0, 1.0);

              return AlertDialog(
                backgroundColor: inAppForegroundColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                titlePadding: const EdgeInsets.only(top: 24),
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                title: Column(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                      child: Icon(
                        currentCredits == 1203
                            ? Icons.auto_awesome
                            : (currentCredits == 0 ? Icons.credit_card_off : Icons.credit_score),
                        key: ValueKey(
                          currentCredits == 1203
                              ? 'easterEgg'
                              : (currentCredits == 0 ? 'zero' : 'normal'),
                        ),
                        size: 48,
                        color: currentCredits == 0 ? Colors.red : textHighlightedColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Your Balance",
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                content: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 260, maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 600),
                        switchInCurve: Curves.easeOutExpo,
                        switchOutCurve: Curves.easeInExpo,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(scale: animation, child: child),
                        ),
                        child: Text(
                          "$currentCredits Credits",
                          key: ValueKey(currentCredits),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LinearProgressIndicator(
                                value: value,
                                backgroundColor: Colors.white12,
                                valueColor: AlwaysStoppedAnimation<Color>(textHighlightedColor),
                                minHeight: 10,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${(value * 100).round()}% of next credit",
                                style: TextStyle(
                                  color: textColor.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                actionsAlignment: MainAxisAlignment.spaceEvenly,
                actions: [
                  TextButtonWithoutIcon(
                    label: "Close",
                    onPressed: () => Navigator.pop(context),
                    foregroundColor: Colors.white70,
                    borderColor: Colors.white70,
                    fontSize: 16,
                    borderWidth: 1,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  ),
                  TextButtonWithoutIcon(
                    label: "Get More",
                    onPressed: () {
                      Navigator.pop(context);
                      UpgradePlanDialog.show(context, selectedPlan);
                    },
                    backgroundColor: textHighlightedColor,
                    foregroundColor: inAppForegroundColor,
                    fontSize: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
